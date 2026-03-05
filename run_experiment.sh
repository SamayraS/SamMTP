#!/bin/bash
#
# FULL MTD BOTNET EXPERIMENT (HIGH REALISM + SCALABLE)
#

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

########################################
# CONFIG (Environment Override Supported)
########################################

BOT_COUNT=${NUM_BOTS:-12}
CLIENT_COUNT=${NUM_CLIENTS:-2}
BASELINE_TIME=${RUNTIME:-600}
MTD_TIME=${RUNTIME:-600}
HOP_INTERVAL=${HOP_INTERVAL:-3}

if [ -x ".venv/bin/python3" ]; then
    PYTHON=".venv/bin/python3"
else
    PYTHON="python3"
fi

echo ""
echo "=============================================="
echo " HIGH-REALISM MTD BOTNET EXPERIMENT"
echo " Bots: $BOT_COUNT | Clients: $CLIENT_COUNT"
echo " Baseline: ${BASELINE_TIME}s | MTD: ${MTD_TIME}s"
echo " Hop interval: ${HOP_INTERVAL}s"
echo "=============================================="
echo ""

########################################
# CLEANUP
########################################

BACKUP_DIR="_old_logs_$(date +%Y%m%d_%H%M%S)"
mkdir -p "$BACKUP_DIR"
mv *_log_*.txt "$BACKUP_DIR" 2>/dev/null || true

pkill -f dns_server.py 2>/dev/null
pkill -f c2_server.py 2>/dev/null
pkill -f bot_client.py 2>/dev/null
pkill -f normal_client.py 2>/dev/null
pkill -f mtd_engine.py 2>/dev/null
sleep 2


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

CLIENT_PIDS=()
for ((i=1;i<=CLIENT_COUNT;i++)); do
    $PYTHON -u normal_client.py >> normal_log_baseline.txt 2>&1 &
    CLIENT_PIDS+=($!)
done

BOT_PIDS=()
for ((i=1;i<=BOT_COUNT;i++)); do
    $PYTHON -u bot_client.py >> bot_log_baseline.txt 2>&1 &
    BOT_PIDS+=($!)
done

sleep $BASELINE_TIME

kill $DNS_PID $C2_PID "${CLIENT_PIDS[@]}" "${BOT_PIDS[@]}" 2>/dev/null
sleep 3

echo "========== BASELINE COMPLETE =========="
echo ""

########################################
# FAILSAFE CHECK - BASELINE
########################################

echo "[CHECK] Verifying baseline logs..."

for f in dns_log_baseline.txt c2_log_baseline.txt bot_log_baseline.txt normal_log_baseline.txt; do
    if [ ! -s "$f" ]; then
        echo "[ERROR] $f is empty or missing. Aborting experiment."
        exit 1
    fi
done

echo "[OK] Baseline logs verified."
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

CLIENT_PIDS=()
for ((i=1;i<=CLIENT_COUNT;i++)); do
    $PYTHON -u normal_client.py >> normal_log_mtd.txt 2>&1 &
    CLIENT_PIDS+=($!)
done

BOT_PIDS=()
for ((i=1;i<=BOT_COUNT;i++)); do
    $PYTHON -u bot_client.py >> bot_log_mtd.txt 2>&1 &
    BOT_PIDS+=($!)
done

sleep $MTD_TIME

kill $DNS_PID $C2_PID $MTD_PID "${CLIENT_PIDS[@]}" "${BOT_PIDS[@]}" 2>/dev/null
sleep 3

echo "========== MTD COMPLETE =========="
echo ""

########################################
# FAILSAFE CHECK - MTD
########################################

echo "[CHECK] Verifying MTD logs..."

for f in dns_log_mtd.txt c2_log_mtd.txt bot_log_mtd.txt normal_log_mtd.txt mtd_log.txt; do
    if [ ! -s "$f" ]; then
        echo "[ERROR] $f is empty or missing. Aborting experiment."
        exit 1
    fi
done

echo "[OK] MTD logs verified."
echo ""
echo "Logs generated:"
ls -lh *_log_*.txt 2>/dev/null