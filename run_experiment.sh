# #!/bin/bash
# #
# # FULL MTD BOTNET EXPERIMENT
# # - Baseline: 1 min (stable C2 IP/DNS/port)
# # - MTD: 1 min (IP + DNS + port hopping via mtd_engine.py)
# # - Debug prints after each step
# #

# SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# cd "$SCRIPT_DIR"

# # Use venv Python if present
# if [ -x ".venv/bin/python3" ]; then
#     PYTHON=".venv/bin/python3"
#     echo "[CONFIG] Using venv Python: $PYTHON"
# else
#     PYTHON="python3"
#     echo "[CONFIG] Using system Python: $PYTHON"
# fi

# BASELINE_TIME=600   # 10 minute
# MTD_TIME=600        # 10 minute

# # DNS server runs on 5354 (avoid system mDNS on 5353)
# DNS_PORT=5354
# C2_PORT_DEFAULT=9000

# LOGS=(
#     dns_log_baseline.txt
#     c2_log_baseline.txt
#     bot_log_baseline.txt
#     normal_log_baseline.txt
#     dns_log_mtd.txt
#     c2_log_mtd.txt
#     bot_log_mtd.txt
#     normal_log_mtd.txt
#     mtd_log.txt
# )

# echo ""
# echo "=== FULL MTD BOTNET EXPERIMENT (1 min baseline + 1 min MTD) ==="
# echo ""

# # ---------------------------------------------------------------------------
# echo "[1] Cleaning old logs..."
# # ---------------------------------------------------------------------------
# BACKUP_DIR="_old_logs_$(date +%Y%m%d_%H%M%S)"
# mkdir -p "$BACKUP_DIR"
# for f in "${LOGS[@]}"; do
#     if [ -f "$f" ]; then
#         mv "$f" "$BACKUP_DIR/"
#         echo "  [OK] Moved $f -> $BACKUP_DIR/"
#     fi
# done
# echo "  [DONE] Old logs backed up to $BACKUP_DIR"
# echo ""

# # ---------------------------------------------------------------------------
# echo "[2] Killing leftover processes..."
# # ---------------------------------------------------------------------------
# for name in dns_server.py c2_server.py bot_client.py normal_client.py mtd_engine.py; do
#     if pkill -f "$name" 2>/dev/null; then
#         echo "  [OK] Killed $name"
#     else
#         echo "  [--] No process found for $name"
#     fi
# done
# sleep 2
# echo "  [DONE] Process cleanup complete"
# echo ""

# # ---------------------------------------------------------------------------
# echo "[3] Resetting C2 config for baseline (stable IP/DNS/port)..."
# # ---------------------------------------------------------------------------
# echo "127.0.0.1" > c2_ip.txt
# echo "9000"      > c2_port.txt
# echo "botc2.example" > domain.txt
# echo "  [OK] c2_ip.txt = $(cat c2_ip.txt)"
# echo "  [OK] c2_port.txt = $(cat c2_port.txt)"
# echo "  [OK] domain.txt = $(cat domain.txt)"
# echo "  [DONE] Baseline config ready"
# echo ""

# ########################################
# # BASELINE RUN (no MTD)
# ########################################
# echo "=============================================="
# echo "=== BASELINE RUN (${BASELINE_TIME}s, no hopping) ==="
# echo "=============================================="

# echo "[BASELINE-1] Starting DNS server (port $DNS_PORT)..."
# $PYTHON -u dns_server.py > dns_log_baseline.txt 2>&1 &
# DNS_PID=$!
# sleep 1
# if kill -0 "$DNS_PID" 2>/dev/null; then
#     echo "  [OK] DNS server started (PID $DNS_PID)"
# else
#     echo "  [FAIL] DNS server did not start"
#     exit 1
# fi

# echo "[BASELINE-2] Starting C2 server (port $C2_PORT_DEFAULT)..."
# $PYTHON -u c2_server.py > c2_log_baseline.txt 2>&1 &
# C2_PID=$!
# sleep 1
# if kill -0 "$C2_PID" 2>/dev/null; then
#     echo "  [OK] C2 server started (PID $C2_PID)"
# else
#     echo "  [FAIL] C2 server did not start"
#     kill $DNS_PID 2>/dev/null
#     exit 1
# fi

# echo "[BASELINE-3] Starting normal client..."
# $PYTHON -u normal_client.py > normal_log_baseline.txt 2>&1 &
# NORMAL_PID=$!
# sleep 1
# if kill -0 "$NORMAL_PID" 2>/dev/null; then
#     echo "  [OK] Normal client started (PID $NORMAL_PID)"
# else
#     echo "  [FAIL] Normal client did not start"
# fi

# echo "[BASELINE-4] Starting bot client..."
# $PYTHON -u bot_client.py > bot_log_baseline.txt 2>&1 &
# BOT_PID=$!
# sleep 1
# if kill -0 "$BOT_PID" 2>/dev/null; then
#     echo "  [OK] Bot client started (PID $BOT_PID)"
# else
#     echo "  [FAIL] Bot client did not start"
# fi

# echo "[BASELINE-5] Running baseline for $BASELINE_TIME seconds..."
# sleep $BASELINE_TIME
# echo "  [DONE] Baseline duration complete"

# echo "[BASELINE-6] Stopping baseline processes..."
# kill $DNS_PID $C2_PID $NORMAL_PID $BOT_PID 2>/dev/null || true
# sleep 2
# echo "  [OK] Processes stopped"

# echo "[BASELINE-7] Checking baseline logs..."
# for f in dns_log_baseline.txt c2_log_baseline.txt bot_log_baseline.txt normal_log_baseline.txt; do
#     if [ -f "$f" ]; then
#         lines=$(wc -l < "$f")
#         echo "  [OK] $f: $lines lines"
#     else
#         echo "  [FAIL] $f: missing"
#     fi
# done
# echo "  [DONE] Baseline run complete."
# echo ""

# ########################################
# # MTD RUN (IP + DNS + port hopping)
# ########################################
# echo "=============================================="
# echo "=== MTD RUN (${MTD_TIME}s, IP + DNS + port hopping) ==="
# echo "=============================================="

# echo "[MTD-1] Resetting C2 config (MTD engine will overwrite)..."
# echo "127.0.0.1" > c2_ip.txt
# echo "9000"      > c2_port.txt
# echo "botc2.example" > domain.txt
# echo "  [OK] Config reset"

# echo "[MTD-2] Starting DNS server..."
# $PYTHON -u dns_server.py > dns_log_mtd.txt 2>&1 &
# DNS_PID=$!
# sleep 1
# if kill -0 "$DNS_PID" 2>/dev/null; then
#     echo "  [OK] DNS server started (PID $DNS_PID)"
# else
#     echo "  [FAIL] DNS server did not start"
#     exit 1
# fi

# echo "[MTD-3] Starting C2 server (port from c2_port.txt, will change with MTD)..."
# $PYTHON -u c2_server.py > c2_log_mtd.txt 2>&1 &
# C2_PID=$!
# sleep 1
# if kill -0 "$C2_PID" 2>/dev/null; then
#     echo "  [OK] C2 server started (PID $C2_PID)"
# else
#     echo "  [FAIL] C2 server did not start"
#     kill $DNS_PID 2>/dev/null
#     exit 1
# fi

# echo "[MTD-4] Starting MTD engine (IP + DNS domain + port hopping)..."
# $PYTHON -u mtd_engine.py > mtd_log.txt 2>&1 &
# MTD_PID=$!
# sleep 2
# if kill -0 "$MTD_PID" 2>/dev/null; then
#     echo "  [OK] MTD engine started (PID $MTD_PID)"
# else
#     echo "  [FAIL] MTD engine did not start"
# fi

# echo "[MTD-5] Starting normal client..."
# $PYTHON -u normal_client.py > normal_log_mtd.txt 2>&1 &
# NORMAL_PID=$!
# sleep 1
# if kill -0 "$NORMAL_PID" 2>/dev/null; then
#     echo "  [OK] Normal client started (PID $NORMAL_PID)"
# else
#     echo "  [FAIL] Normal client did not start"
# fi

# echo "[MTD-6] Starting bot client..."
# $PYTHON -u bot_client.py > bot_log_mtd.txt 2>&1 &
# BOT_PID=$!
# sleep 1
# if kill -0 "$BOT_PID" 2>/dev/null; then
#     echo "  [OK] Bot client started (PID $BOT_PID)"
# else
#     echo "  [FAIL] Bot client did not start"
# fi

# echo "[MTD-7] Running MTD for $MTD_TIME seconds (hopping every 20s)..."
# sleep $MTD_TIME
# echo "  [DONE] MTD duration complete"

# echo "[MTD-8] Stopping all MTD processes..."
# kill $DNS_PID $C2_PID $NORMAL_PID $BOT_PID $MTD_PID 2>/dev/null || true
# sleep 2
# echo "  [OK] Processes stopped"

# echo "[MTD-9] Checking MTD logs..."
# for f in dns_log_mtd.txt c2_log_mtd.txt bot_log_mtd.txt normal_log_mtd.txt mtd_log.txt; do
#     if [ -f "$f" ]; then
#         lines=$(wc -l < "$f")
#         echo "  [OK] $f: $lines lines"
#     else
#         echo "  [FAIL] $f: missing"
#     fi
# done
# echo "  [DONE] MTD run complete."
# echo ""

# # ---------------------------------------------------------------------------
# echo "=============================================="
# echo "=== EXPERIMENT COMPLETE ==="
# echo "=============================================="
# echo "Logs generated:"
# ls -lh dns_log_baseline.txt c2_log_baseline.txt bot_log_baseline.txt normal_log_baseline.txt \
#        dns_log_mtd.txt c2_log_mtd.txt bot_log_mtd.txt normal_log_mtd.txt mtd_log.txt 2>/dev/null || true
# echo ""
# echo "Run metrics: $PYTHON compute_metrics.py dns_log_baseline.txt bot_log_baseline.txt"
# echo "             $PYTHON compute_metrics.py dns_log_mtd.txt bot_log_mtd.txt"
# echo ""
#!/bin/bash
#
# FULL MTD BOTNET EXPERIMENT (HIGH REALISM)
# - 12 Bots
# - 2 Normal Clients
# - 10 min Baseline
# - 10 min MTD
# - Hop interval: 3 seconds
#

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

########################################
# CONFIG
########################################

BOT_COUNT=12
CLIENT_COUNT=2
BASELINE_TIME=600
MTD_TIME=600
HOP_INTERVAL=3   # seconds

if [ -x ".venv/bin/python3" ]; then
    PYTHON=".venv/bin/python3"
else
    PYTHON="python3"
fi

echo ""
echo "=============================================="
echo " HIGH-REALISM MTD BOTNET EXPERIMENT"
echo " Bots: $BOT_COUNT | Clients: $CLIENT_COUNT"
echo " Baseline: 10 min | MTD: 10 min"
echo " Hop interval: ${HOP_INTERVAL}s"
echo "=============================================="
echo ""

########################################
# CLEANUP
########################################

echo "[1] Cleaning old logs..."
BACKUP_DIR="_old_logs_$(date +%Y%m%d_%H%M%S)"
mkdir -p "$BACKUP_DIR"
mv *_log_*.txt "$BACKUP_DIR" 2>/dev/null || true
echo "  [OK] Logs moved to $BACKUP_DIR"

echo "[2] Killing old processes..."
pkill -f dns_server.py 2>/dev/null
pkill -f c2_server.py 2>/dev/null
pkill -f bot_client.py 2>/dev/null
pkill -f normal_client.py 2>/dev/null
pkill -f mtd_engine.py 2>/dev/null
sleep 2
echo "  [OK] Cleanup complete"
echo ""

########################################
# BASELINE CONFIG
########################################

echo "127.0.0.1" > c2_ip.txt
echo "9000" > c2_port.txt
echo "botc2.example" > domain.txt

########################################
# BASELINE RUN
########################################

echo "========== BASELINE START =========="

$PYTHON -u dns_server.py > dns_log_baseline.txt 2>&1 &
DNS_PID=$!

$PYTHON -u c2_server.py > c2_log_baseline.txt 2>&1 &
C2_PID=$!

sleep 2

echo "[BASELINE] Starting $CLIENT_COUNT normal clients..."
CLIENT_PIDS=()
for ((i=1;i<=CLIENT_COUNT;i++)); do
    $PYTHON -u normal_client.py >> normal_log_baseline.txt 2>&1 &
    CLIENT_PIDS+=($!)
done

echo "[BASELINE] Starting $BOT_COUNT bots..."
BOT_PIDS=()
for ((i=1;i<=BOT_COUNT;i++)); do
    $PYTHON -u bot_client.py >> bot_log_baseline.txt 2>&1 &
    BOT_PIDS+=($!)
done

echo "[BASELINE] Running for 10 minutes..."
sleep $BASELINE_TIME

echo "[BASELINE] Stopping processes..."
kill $DNS_PID $C2_PID "${CLIENT_PIDS[@]}" "${BOT_PIDS[@]}" 2>/dev/null
sleep 3

echo "========== BASELINE COMPLETE =========="
echo ""

########################################
# MTD RUN
########################################

echo "========== MTD START =========="

echo "127.0.0.1" > c2_ip.txt
echo "9000" > c2_port.txt
echo "botc2.example" > domain.txt

$PYTHON -u dns_server.py > dns_log_mtd.txt 2>&1 &
DNS_PID=$!

$PYTHON -u c2_server.py > c2_log_mtd.txt 2>&1 &
C2_PID=$!

# --- Override MTD hop interval dynamically ---
echo "[MTD] Starting MTD engine with ${HOP_INTERVAL}s hopping..."

MTD_PIDS=()
(
while true; do
    for ip in 127.0.0.1 127.0.0.2 127.0.0.3; do
        echo $ip > c2_ip.txt
        for port in 9000 9001 9002; do
            echo $port > c2_port.txt
            for domain in botc2.example botc2-alt.example; do
                echo $domain > domain.txt
                echo "$(date +%s) SWITCH ip=$ip port=$port domain=$domain" >> mtd_log.txt
                sleep $HOP_INTERVAL
            done
        done
    done
done
) &
MTD_PID=$!

sleep 2

echo "[MTD] Starting $CLIENT_COUNT normal clients..."
CLIENT_PIDS=()
for ((i=1;i<=CLIENT_COUNT;i++)); do
    $PYTHON -u normal_client.py >> normal_log_mtd.txt 2>&1 &
    CLIENT_PIDS+=($!)
done

echo "[MTD] Starting $BOT_COUNT bots..."
BOT_PIDS=()
for ((i=1;i<=BOT_COUNT;i++)); do
    $PYTHON -u bot_client.py >> bot_log_mtd.txt 2>&1 &
    BOT_PIDS+=($!)
done

echo "[MTD] Running for 10 minutes..."
sleep $MTD_TIME

echo "[MTD] Stopping processes..."
kill $DNS_PID $C2_PID $MTD_PID "${CLIENT_PIDS[@]}" "${BOT_PIDS[@]}" 2>/dev/null
sleep 3

echo "========== MTD COMPLETE =========="
echo ""

########################################
# SUMMARY
########################################

echo "========== FINAL SUMMARY =========="
ls -lh *_log_*.txt 2>/dev/null
echo ""

echo "Run metrics:"
echo "$PYTHON compute_metrics.py dns_log_baseline.txt bot_log_baseline.txt"
echo "$PYTHON compute_metrics.py dns_log_mtd.txt bot_log_mtd.txt"
echo ""