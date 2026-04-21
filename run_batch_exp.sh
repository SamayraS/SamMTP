# #!/bin/bash

# PYTHON=.venv/bin/python3

# # Experiment parameters
# HOP_INTERVALS=(1 3 5 10)
# RUNS=5
# BOTS=50
# CLIENTS=5
# DURATION=600   # 10 minutes

# RESULT_DIR="batch_results_$(date +%Y%m%d_%H%M%S)"
# mkdir -p $RESULT_DIR

# echo "Starting batch experiments..."
# echo "Bots=$BOTS Clients=$CLIENTS Runs=$RUNS"

# for HOP in "${HOP_INTERVALS[@]}"
# do
#     echo "======================================"
#     echo "Running hop interval: ${HOP}s"
#     echo "======================================"

#     for ((i=1;i<=RUNS;i++))
#     do
#         echo "Run $i / $RUNS (Hop=$HOP)"

#         HOP_INTERVAL=$HOP \
#         NUM_BOTS=$BOTS \
#         NUM_CLIENTS=$CLIENTS \
#         RUNTIME=$DURATION \
#         ./run_experiment.sh

#         mkdir -p $RESULT_DIR/hop_${HOP}_run_${i}

#         cp *_baseline.txt *_mtd.txt $RESULT_DIR/hop_${HOP}_run_${i}/

#         echo "Run $i complete"
#     done
# done

# echo "Batch experiments completed."

#!/bin/bash

set -u

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

source "$SCRIPT_DIR/batch_experiment_config.sh"

VERIFY_SCRIPT="$SCRIPT_DIR/verify_logs.sh"
RESULT_DIR="$SCRIPT_DIR/${ALL_CONFIG_LOGS_DIR}"
BASELINE_CACHE_DIR="$RESULT_DIR/baseline_cache"

mkdir -p "$RESULT_DIR"
mkdir -p "$BASELINE_CACHE_DIR"
chmod +x "$VERIFY_SCRIPT" "$SCRIPT_DIR/run_experiment.sh"

CAFFEINATE_PID=""
cleanup_keepawake() {
  if [ -n "${CAFFEINATE_PID:-}" ]; then
    kill "$CAFFEINATE_PID" 2>/dev/null || true
  fi
}
trap 'cleanup_keepawake' EXIT INT TERM

if command -v caffeinate >/dev/null 2>&1; then
  # Prevent display/system sleep for the duration of this batch script.
  caffeinate -dimsu &
  CAFFEINATE_PID=$!
  echo "[POWER] Sleep disabled for this batch run (caffeinate pid=$CAFFEINATE_PID)."
else
  echo "[POWER][WARN] caffeinate not found; macOS sleep may interrupt the batch."
fi

TOTAL_RUNS=$(( ${#CONFIG_MODES[@]} * RUNS_PER_CONFIG * ${#BOT_BENIGN_RATIOS[@]} ))
completed=0
next_index=0

pick_interval_for_run() {
    local run_id="$1"
    local idx=$(( (run_id - 1) % ${#MUTATION_INTERVALS[@]} ))
    echo "${MUTATION_INTERVALS[$idx]}"
}

baseline_logs=(
  "dns_log_baseline.txt"
  "c2_log_baseline.txt"
  "bot_log_baseline.txt"
  "normal_log_baseline.txt"
)

echo "==== CONFIG-DRIVEN RESUMABLE BATCH EXPERIMENT ===="
echo "Total planned runs: $TOTAL_RUNS"
echo "Logs root: $RESULT_DIR"
echo "Baseline cache: $BASELINE_CACHE_DIR"
echo ""

for ratio in "${BOT_BENIGN_RATIOS[@]}"; do
  bots="${ratio%%:*}"
  clients="${ratio##*:}"
  ratio_slug="${bots}_${clients}"

  for ((run_id=1; run_id<=RUNS_PER_CONFIG; run_id++)); do
    interval="$(pick_interval_for_run "$run_id")"
    baseline_dir="$BASELINE_CACHE_DIR/ratio_${ratio_slug}/run_${run_id}"
    mkdir -p "$baseline_dir"

    # Collect baseline once per (ratio, run_id), then reuse for all modes.
    if ! [ -f "$baseline_dir/BASELINE_COMPLETED" ] || ! [ -s "$baseline_dir/dns_log_baseline.txt" ] || ! [ -s "$baseline_dir/bot_log_baseline.txt" ]; then
      echo "------------------------------------------------------------"
      echo "[BASELINE] ratio=${bots}:${clients} run=$run_id interval=${interval}s"
      echo "------------------------------------------------------------"

      rm -f ./*_log_*.txt ./mtd_log.txt
      EXPERIMENT_MODE="baseline" \
      EXPERIMENT_PHASE="baseline" \
      RUN_LABEL="mode=baseline ratio=${bots}:${clients} run=$run_id interval=${interval}s" \
      RUN_INDEX="0" \
      TOTAL_RUNS="$TOTAL_RUNS" \
      NUM_BOTS="$bots" \
      NUM_CLIENTS="$clients" \
      HOP_INTERVAL="$interval" \
      RUNTIME="$RUN_DURATION_SECONDS" \
      ./run_experiment.sh

      if [ $? -ne 0 ]; then
        echo "[ERROR] Baseline run failed; stopping batch."
        exit 1
      fi

      for f in "${baseline_logs[@]}"; do
        cp "$f" "$baseline_dir/$f"
      done
      touch "$baseline_dir/BASELINE_COMPLETED"
    else
      echo "[SKIP][BASELINE] ratio=${bots}:${clients} run=$run_id already cached."
    fi

    for mode in "${CONFIG_MODES[@]}"; do
      next_index=$((next_index + 1))
      run_dir="$RESULT_DIR/mode_${mode}/ratio_${ratio_slug}/run_${run_id}"
      mkdir -p "$run_dir"

      if [ -f "$run_dir/COMPLETED" ] && "$VERIFY_SCRIPT" "$run_dir" >/dev/null 2>&1; then
        completed=$((completed + 1))
        echo "[SKIP][$completed/$TOTAL_RUNS] mode=$mode ratio=${bots}:${clients} run=$run_id interval=${interval}s"
        continue
      fi

      echo "------------------------------------------------------------"
      echo "[RUN][$next_index/$TOTAL_RUNS] mode=$mode ratio=${bots}:${clients} run=$run_id interval=${interval}s (MTD-only)"
      echo "------------------------------------------------------------"

      rm -f ./*_log_*.txt ./mtd_log.txt
      EXPERIMENT_MODE="$mode" \
      EXPERIMENT_PHASE="mtd" \
      RUN_LABEL="mode=$mode ratio=${bots}:${clients} run=$run_id interval=${interval}s" \
      RUN_INDEX="$next_index" \
      TOTAL_RUNS="$TOTAL_RUNS" \
      NUM_BOTS="$bots" \
      NUM_CLIENTS="$clients" \
      HOP_INTERVAL="$interval" \
      RUNTIME="$RUN_DURATION_SECONDS" \
      ./run_experiment.sh

      if [ $? -ne 0 ]; then
        echo "[ERROR] MTD run failed; stopping batch."
        exit 1
      fi

      for f in "${baseline_logs[@]}"; do
        cp "$baseline_dir/$f" "$run_dir/$f"
      done
      for f in dns_log_mtd.txt c2_log_mtd.txt bot_log_mtd.txt normal_log_mtd.txt mtd_log.txt; do
        cp "$f" "$run_dir/$f"
      done

      cat > "$run_dir/run_metadata.txt" <<EOF
mode=$mode
bots=$bots
clients=$clients
ratio=${bots}:${clients}
run_id=$run_id
mutation_interval_seconds=$interval
runtime_seconds=$RUN_DURATION_SECONDS
EOF

      if "$VERIFY_SCRIPT" "$run_dir" >/dev/null 2>&1; then
        touch "$run_dir/COMPLETED"
        completed=$((completed + 1))
        echo "[DONE][$completed/$TOTAL_RUNS] Stored logs in $run_dir"
      else
        echo "[WARN] Invalid/corrupt logs removed. Run will be retried on next batch invocation."
      fi
    done
  done
done

if [ "$completed" -eq "$TOTAL_RUNS" ]; then
  echo "FINITO"
else
  echo "[INFO] Progress: $completed / $TOTAL_RUNS valid runs collected."
fi