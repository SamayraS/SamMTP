#!/bin/bash
#
# FULL MTD BOTNET EXPERIMENT (HIGH REALISM + SCALABLE)
#

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"
set -u

########################################
# CONFIG (Environment Override Supported)
########################################

BOT_COUNT=${NUM_BOTS:-12}
CLIENT_COUNT=${NUM_CLIENTS:-2}
BASELINE_TIME=${RUNTIME:-600}
MTD_TIME=${RUNTIME:-600}
HOP_INTERVAL=${HOP_INTERVAL:-3}
EXPERIMENT_MODE=${EXPERIMENT_MODE:-ip_port_dns}
EXPERIMENT_PHASE=${EXPERIMENT_PHASE:-both}
RUN_LABEL=${RUN_LABEL:-manual}
RUN_INDEX=${RUN_INDEX:-0}
TOTAL_RUNS=${TOTAL_RUNS:-0}

if [ -x ".venv/bin/python3" ]; then
    PYTHON=".venv/bin/python3"
else
    PYTHON="python3"
fi

mode_uses_ip=0
mode_uses_port=0
mode_uses_dns=0

case "$EXPERIMENT_MODE" in
    baseline)
        ;;
    ip)
        mode_uses_ip=1
        ;;
    dns)
        mode_uses_dns=1
        ;;
    ip_port)
        mode_uses_ip=1
        mode_uses_port=1
        ;;
    ip_dns)
        mode_uses_ip=1
        mode_uses_dns=1
        ;;
    ip_port_dns)
        mode_uses_ip=1
        mode_uses_port=1
        mode_uses_dns=1
        ;;
    *)
        echo "[ERROR] Unknown EXPERIMENT_MODE: $EXPERIMENT_MODE"
        exit 1
        ;;
esac

case "$EXPERIMENT_PHASE" in
    both|baseline|mtd)
        ;;
    *)
        echo "[ERROR] Unknown EXPERIMENT_PHASE: $EXPERIMENT_PHASE"
        exit 1
        ;;
esac

echo ""
echo "=============================================="
echo " HIGH-REALISM MTD BOTNET EXPERIMENT"
echo " Run label: $RUN_LABEL"
echo " Progress: $RUN_INDEX / $TOTAL_RUNS"
echo " Phase: $EXPERIMENT_PHASE"
echo " Mode: $EXPERIMENT_MODE (IP=$mode_uses_ip PORT=$mode_uses_port DNS=$mode_uses_dns)"
echo " Bots: $BOT_COUNT | Clients: $CLIENT_COUNT"
echo " Baseline: ${BASELINE_TIME}s | MTD: ${MTD_TIME}s"
echo " Mutation interval: ${HOP_INTERVAL}s"
echo "=============================================="
echo ""

DNS_PID=""
C2_PID=""
MTD_PID=""
CLIENT_PIDS=()
BOT_PIDS=()

cleanup_children() {
    local pids=()
    [ -n "${DNS_PID:-}" ] && pids+=("$DNS_PID")
    [ -n "${C2_PID:-}" ] && pids+=("$C2_PID")
    [ -n "${MTD_PID:-}" ] && pids+=("$MTD_PID")
    pids+=("${CLIENT_PIDS[@]}")
    pids+=("${BOT_PIDS[@]}")
    if [ "${#pids[@]}" -gt 0 ]; then
        kill "${pids[@]}" 2>/dev/null || true
    fi
}

trap 'echo "[INTERRUPT] Cleaning up child processes..."; cleanup_children; exit 1' INT TERM

########################################
# CLEANUP
########################################

rm -f ./*_log_*.txt ./mtd_log.txt

pkill -f dns_server.py 2>/dev/null
pkill -f c2_server.py 2>/dev/null
pkill -f bot_client.py 2>/dev/null
pkill -f normal_client.py 2>/dev/null
pkill -f mtd_engine.py 2>/dev/null
sleep 2


########################################
# BASELINE CONFIG
########################################

if [ "$EXPERIMENT_PHASE" = "both" ] || [ "$EXPERIMENT_PHASE" = "baseline" ]; then

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

for ((i=1;i<=CLIENT_COUNT;i++)); do
    $PYTHON -u normal_client.py >> normal_log_baseline.txt 2>&1 &
    CLIENT_PIDS+=($!)
done

for ((i=1;i<=BOT_COUNT;i++)); do
    $PYTHON -u bot_client.py >> bot_log_baseline.txt 2>&1 &
    BOT_PIDS+=($!)
done

sleep $BASELINE_TIME

cleanup_children
DNS_PID=""
C2_PID=""
CLIENT_PIDS=()
BOT_PIDS=()
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

fi

if [ "$EXPERIMENT_PHASE" = "both" ] || [ "$EXPERIMENT_PHASE" = "mtd" ]; then

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
        if [ "$mode_uses_ip" -eq 1 ]; then
            echo "$ip" > c2_ip.txt
        else
            echo "127.0.0.1" > c2_ip.txt
        fi
        for port in 9000 9001 9002; do
            if [ "$mode_uses_port" -eq 1 ]; then
                echo "$port" > c2_port.txt
            else
                echo "9000" > c2_port.txt
            fi
            for domain in botc2.example botc2-alt.example botc2-mutate.example; do
                if [ "$mode_uses_dns" -eq 1 ]; then
                    # Keep DNS uncached by forcing resolver-side changes every mutation step.
                    echo "$domain" > domain.txt
                else
                    echo "botc2.example" > domain.txt
                fi
                echo "$(date +%s) SWITCH mode=$EXPERIMENT_MODE ip=$(cat c2_ip.txt) port=$(cat c2_port.txt) domain=$(cat domain.txt)" >> mtd_log.txt
                sleep $HOP_INTERVAL
            done
        done
    done
done
) &
MTD_PID=$!

sleep 2

for ((i=1;i<=CLIENT_COUNT;i++)); do
    $PYTHON -u normal_client.py >> normal_log_mtd.txt 2>&1 &
    CLIENT_PIDS+=($!)
done

for ((i=1;i<=BOT_COUNT;i++)); do
    $PYTHON -u bot_client.py >> bot_log_mtd.txt 2>&1 &
    BOT_PIDS+=($!)
done

sleep $MTD_TIME

cleanup_children
DNS_PID=""
C2_PID=""
MTD_PID=""
CLIENT_PIDS=()
BOT_PIDS=()
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

fi

trap - INT TERM