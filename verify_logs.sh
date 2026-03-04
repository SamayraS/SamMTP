# # #!/bin/bash
# # #
# # # Verify baseline vs MTD experiment logs:
# # # - Bot SUCCESS/FAIL, DNS activity, C2 beacons, normal traffic, MTD switches
# # # - Sanity inference check that MTD increased failures and DNS retries
# # #

# # SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# # cd "$SCRIPT_DIR"

# # echo "======================================"
# # echo "      VERIFYING BASELINE vs MTD"
# # echo "======================================"
# # echo ""

# # ########################################
# # # Helper: run command if file exists, else output 0
# # ########################################
# # count_if_exists() {
# #     if [ -f "$1" ]; then
# #         eval "$2" 2>/dev/null || echo "0"
# #     else
# #         echo "0"
# #     fi
# # }

# # ########################################
# # # BASELINE METRICS
# # ########################################

# # BASE_SUCCESS=$(count_if_exists bot_log_baseline.txt "grep -c 'SUCCESS' bot_log_baseline.txt")
# # BASE_FAIL=$(count_if_exists bot_log_baseline.txt "grep -c 'FAIL' bot_log_baseline.txt")

# # BASE_DNS_TOTAL=$(count_if_exists dns_log_baseline.txt "wc -l < dns_log_baseline.txt")
# # BASE_DNS_BOT=$(count_if_exists dns_log_baseline.txt "grep -c 'botc2' dns_log_baseline.txt")

# # BASE_C2_BEACONS=$(count_if_exists c2_log_baseline.txt "grep -c 'Beacon' c2_log_baseline.txt")

# # BASE_NORMAL_DNS=$(count_if_exists normal_log_baseline.txt "wc -l < normal_log_baseline.txt")

# # ########################################
# # # MTD METRICS
# # ########################################

# # MTD_SUCCESS=$(count_if_exists bot_log_mtd.txt "grep -c 'SUCCESS' bot_log_mtd.txt")
# # MTD_FAIL=$(count_if_exists bot_log_mtd.txt "grep -c 'FAIL' bot_log_mtd.txt")

# # MTD_DNS_TOTAL=$(count_if_exists dns_log_mtd.txt "wc -l < dns_log_mtd.txt")
# # MTD_DNS_BOT=$(count_if_exists dns_log_mtd.txt "grep -c 'botc2' dns_log_mtd.txt")

# # MTD_C2_BEACONS=$(count_if_exists c2_log_mtd.txt "grep -c 'Beacon' c2_log_mtd.txt")

# # MTD_NORMAL_DNS=$(count_if_exists normal_log_mtd.txt "wc -l < normal_log_mtd.txt")

# # MTD_SWITCHES=$(count_if_exists mtd_log.txt "grep -c 'Switching' mtd_log.txt")

# # ########################################
# # # PRINT RESULTS
# # ########################################

# # echo "----------- BOT STATUS -----------"
# # echo "Baseline  → SUCCESS: $BASE_SUCCESS | FAIL: $BASE_FAIL"
# # echo "MTD       → SUCCESS: $MTD_SUCCESS | FAIL: $MTD_FAIL"
# # echo ""

# # echo "----------- DNS ACTIVITY -----------"
# # echo "Baseline DNS queries (total): $BASE_DNS_TOTAL"
# # echo "Baseline Bot DNS queries:     $BASE_DNS_BOT"
# # echo ""
# # echo "MTD DNS queries (total):      $MTD_DNS_TOTAL"
# # echo "MTD Bot DNS queries:          $MTD_DNS_BOT"
# # echo ""

# # echo "----------- C2 BEACONS -----------"
# # echo "Baseline C2 beacons: $BASE_C2_BEACONS"
# # echo "MTD C2 beacons:      $MTD_C2_BEACONS"
# # echo ""

# # echo "----------- NORMAL TRAFFIC -----------"
# # echo "Baseline normal DNS queries: $BASE_NORMAL_DNS"
# # echo "MTD normal DNS queries:      $MTD_NORMAL_DNS"
# # echo ""

# # echo "----------- MTD ENGINE -----------"
# # echo "MTD switching events logged: $MTD_SWITCHES"
# # echo ""

# # ########################################
# # # SANITY INFERENCE CHECK
# # ########################################

# # echo "======================================"
# # echo "INFERENCE CHECK"
# # echo "======================================"

# # if [ "${BASE_FAIL:-0}" -eq 0 ] && [ "${BASE_SUCCESS:-0}" -gt 0 ]; then
# #     echo "[OK] Baseline stable (no significant failures)"
# # else
# #     echo "[WARN] Baseline instability detected"
# # fi

# # if [ "${MTD_FAIL:-0}" -gt "${BASE_FAIL:-0}" ]; then
# #     echo "[OK] MTD increased failures (expected)"
# # else
# #     echo "[WARN] MTD did not significantly impact failures"
# # fi

# # if [ "${MTD_DNS_TOTAL:-0}" -gt "${BASE_DNS_TOTAL:-0}" ]; then
# #     echo "[OK] DNS retries increased under MTD"
# # else
# #     echo "[WARN] DNS retry burst not clearly visible"
# # fi

# # if [ "${MTD_SWITCHES:-0}" -gt 0 ]; then
# #     echo "[OK] IP + DNS + Port hopping confirmed"
# # else
# #     echo "[WARN] No MTD switching events logged"
# # fi

# # echo ""
# # echo "Verification complete."

# #!/bin/bash
# #
# # VERIFY BASELINE vs MTD (COMPARATIVE TABLE VERSION)
# #

# BOT_COUNT=12
# RUNTIME_MIN=10

# ########################################
# # COLLECT METRICS
# ########################################

# baseline_success=$(grep -c "SUCCESS" bot_log_baseline.txt 2>/dev/null)
# baseline_fail=$(grep -c "FAIL" bot_log_baseline.txt 2>/dev/null)
# baseline_total=$((baseline_success + baseline_fail))

# mtd_success=$(grep -c "SUCCESS" bot_log_mtd.txt 2>/dev/null)
# mtd_fail=$(grep -c "FAIL" bot_log_mtd.txt 2>/dev/null)
# mtd_total=$((mtd_success + mtd_fail))

# baseline_dns=$(wc -l < dns_log_baseline.txt 2>/dev/null)
# mtd_dns=$(wc -l < dns_log_mtd.txt 2>/dev/null)

# baseline_c2=$(grep -c "BEACON" c2_log_baseline.txt 2>/dev/null)
# mtd_c2=$(grep -c "BEACON" c2_log_mtd.txt 2>/dev/null)

# baseline_normal=$(wc -l < normal_log_baseline.txt 2>/dev/null)
# mtd_normal=$(wc -l < normal_log_mtd.txt 2>/dev/null)

# mtd_switches=$(grep -c "SWITCH" mtd_log.txt 2>/dev/null)

# ########################################
# # CALCULATIONS
# ########################################

# calc_rate () {
#     total=$1
#     part=$2
#     if [ "$total" -gt 0 ]; then
#         awk "BEGIN {printf \"%.2f\", ($part/$total)*100}"
#     else
#         echo "0.00"
#     fi
# }

# baseline_fail_rate=$(calc_rate $baseline_total $baseline_fail)
# mtd_fail_rate=$(calc_rate $mtd_total $mtd_fail)

# baseline_success_rate=$(calc_rate $baseline_total $baseline_success)
# mtd_success_rate=$(calc_rate $mtd_total $mtd_success)

# ########################################
# # PRINT TABLE
# ########################################

# echo ""
# echo "=========================================================================="
# echo "                    BASELINE vs MTD COMPARISON"
# echo "=========================================================================="
# printf "%-30s | %-15s | %-15s\n" "Metric" "Baseline" "MTD"
# echo "--------------------------------------------------------------------------"

# printf "%-30s | %-15s | %-15s\n" "Total Attempts" "$baseline_total" "$mtd_total"
# printf "%-30s | %-15s | %-15s\n" "SUCCESS" "$baseline_success" "$mtd_success"
# printf "%-30s | %-15s | %-15s\n" "FAIL" "$baseline_fail" "$mtd_fail"
# printf "%-30s | %-14s%% | %-14s%%\n" "Success Rate" "$baseline_success_rate" "$mtd_success_rate"
# printf "%-30s | %-14s%% | %-14s%%\n" "Failure Rate" "$baseline_fail_rate" "$mtd_fail_rate"

# echo "--------------------------------------------------------------------------"

# printf "%-30s | %-15s | %-15s\n" "DNS Queries" "$baseline_dns" "$mtd_dns"
# printf "%-30s | %-15s | %-15s\n" "C2 Beacons" "$baseline_c2" "$mtd_c2"
# printf "%-30s | %-15s | %-15s\n" "Normal Traffic (DNS)" "$baseline_normal" "$mtd_normal"

# echo "--------------------------------------------------------------------------"

# printf "%-30s | %-15s | %-15s\n" "Avg Success per Bot" \
# "$(awk "BEGIN {printf \"%.2f\", $baseline_success/$BOT_COUNT}")" \
# "$(awk "BEGIN {printf \"%.2f\", $mtd_success/$BOT_COUNT}")"

# printf "%-30s | %-15s | %-15s\n" "Avg Fail per Bot" \
# "$(awk "BEGIN {printf \"%.2f\", $baseline_fail/$BOT_COUNT}")" \
# "$(awk "BEGIN {printf \"%.2f\", $mtd_fail/$BOT_COUNT}")"

# echo "--------------------------------------------------------------------------"

# printf "%-30s | %-15s | %-15s\n" "MTD Switching Events" "-" "$mtd_switches"

# echo "=========================================================================="
# echo ""

#!/bin/bash

BOT_COUNT=12
RUNTIME_MIN=10

echo ""
echo "=========================================================================="
echo "                    BASELINE vs MTD COMPARISON"
echo "=========================================================================="

########################################
# BOT (CLIENT-SIDE)
########################################

baseline_success=$(grep -c "SUCCESS" bot_log_baseline.txt)
baseline_fail=$(grep -c "FAIL" bot_log_baseline.txt)
baseline_total=$((baseline_success + baseline_fail))

mtd_success=$(grep -c "SUCCESS" bot_log_mtd.txt)
mtd_fail=$(grep -c "FAIL" bot_log_mtd.txt)
mtd_total=$((mtd_success + mtd_fail))

########################################
# SERVER-SIDE BEACONS (REAL ACCEPTED)
########################################

baseline_beacons=$(grep -c "BEACON" c2_log_baseline.txt)
mtd_beacons=$(grep -c "BEACON" c2_log_mtd.txt)

########################################
# DNS
########################################

baseline_dns=$(grep -c "" dns_log_baseline.txt)
mtd_dns=$(grep -c "" dns_log_mtd.txt)

########################################
# NORMAL
########################################

baseline_normal=$(grep -c "" normal_log_baseline.txt)
mtd_normal=$(grep -c "" normal_log_mtd.txt)

########################################
# RATES
########################################

calc_rate () {
    total=$1
    part=$2
    if [ "$total" -gt 0 ]; then
        awk "BEGIN {printf \"%.2f\", ($part/$total)*100}"
    else
        echo "0.00"
    fi
}

baseline_fail_rate=$(calc_rate $baseline_total $baseline_fail)
mtd_fail_rate=$(calc_rate $mtd_total $mtd_fail)

baseline_success_rate=$(calc_rate $baseline_total $baseline_success)
mtd_success_rate=$(calc_rate $mtd_total $mtd_success)

########################################
# EFFECTIVENESS
########################################

beacon_drop=$(awk "BEGIN {printf \"%.2f\", (1 - $mtd_beacons/$baseline_beacons)*100}")

########################################
# TABLE
########################################

printf "%-30s | %-15s | %-15s\n" "Metric" "Baseline" "MTD"
echo "--------------------------------------------------------------------------"

printf "%-30s | %-15s | %-15s\n" "Client Attempts" "$baseline_total" "$mtd_total"
printf "%-30s | %-15s | %-15s\n" "Client Success" "$baseline_success" "$mtd_success"
printf "%-30s | %-15s | %-15s\n" "Client Fail" "$baseline_fail" "$mtd_fail"

printf "%-30s | %-14s%% | %-14s%%\n" "Client Success Rate" "$baseline_success_rate" "$mtd_success_rate"
printf "%-30s | %-14s%% | %-14s%%\n" "Client Fail Rate" "$baseline_fail_rate" "$mtd_fail_rate"

echo "--------------------------------------------------------------------------"

printf "%-30s | %-15s | %-15s\n" "Server Accepted Beacons" "$baseline_beacons" "$mtd_beacons"
printf "%-30s | %-15s | %-15s\n" "DNS Queries" "$baseline_dns" "$mtd_dns"
printf "%-30s | %-15s | %-15s\n" "Normal Traffic" "$baseline_normal" "$mtd_normal"

echo "--------------------------------------------------------------------------"

printf "%-30s | %-14s%% | %-14s%%\n" "Beacon Drop %" "0.00" "$beacon_drop"

echo "=========================================================================="
echo ""