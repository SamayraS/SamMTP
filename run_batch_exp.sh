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

PYTHON=.venv/bin/python3

HOP_INTERVALS=(1 3 5 10)
RUNS=5
BOTS=50
CLIENTS=5
DURATION=600

RESULT_DIR="batch_results"
mkdir -p $RESULT_DIR

echo "==== RESUMABLE BATCH EXPERIMENT ===="

for HOP in "${HOP_INTERVALS[@]}"
do
    for ((i=1;i<=RUNS;i++))
    do
        RUN_DIR="$RESULT_DIR/hop_${HOP}_run_${i}"

        # ✅ Skip if already completed
        if [ -f "$RUN_DIR/COMPLETED" ]; then
            echo "[SKIP] Hop=$HOP Run=$i already completed."
            continue
        fi

        echo "----------------------------------"
        echo "Running Hop=$HOP Run=$i"
        echo "----------------------------------"

        HOP_INTERVAL=$HOP \
        NUM_BOTS=$BOTS \
        NUM_CLIENTS=$CLIENTS \
        RUNTIME=$DURATION \
        ./run_experiment.sh

        # If experiment failed, stop entire batch
        if [ $? -ne 0 ]; then
            echo "[ERROR] Experiment failed. Stopping batch."
            exit 1
        fi

        mkdir -p $RUN_DIR
        cp *_baseline.txt *_mtd.txt $RUN_DIR/

        # Mark as completed
        touch "$RUN_DIR/COMPLETED"

        echo "[DONE] Hop=$HOP Run=$i completed."
    done
done

echo "==== ALL EXPERIMENTS FINISHED ===="