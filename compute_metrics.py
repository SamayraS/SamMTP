# """
# Extracts detection metrics from DNS and bot logs.
# Usage: python3 compute_metrics.py <dns_log.txt> <bot_log.txt>
# Computes: DNS retry rate, inter-arrival variance, C2 success rate.
# Visualizes: bot query timeline and inter-arrival distribution (abnormal patterns).
# """
# import sys
# import numpy as np
# import pandas as pd
# import matplotlib.pyplot as plt
# import os

# # C2-related domains (for bot query detection with domain hopping)
# C2_DOMAINS = {"botc2.example", "botc2-alt.example"}


# def parse_dns_log(path):
#     """Parse DNS log: timestamp QUERY domain."""
#     rows = []
#     with open(path) as f:
#         for line in f:
#             line = line.strip()
#             if not line or "QUERY" not in line:
#                 continue
#             parts = line.split(None, 2)
#             if len(parts) < 3:
#                 continue
#             try:
#                 t = float(parts[0])
#                 q = parts[2].strip()
#                 rows.append({"time": t, "type": "QUERY", "query": q})
#             except (ValueError, IndexError):
#                 continue
#     if not rows:
#         return pd.DataFrame(columns=["time", "type", "query"])
#     return pd.DataFrame(rows)


# def parse_bot_log(path):
#     """Parse bot log: lines are either 'C2 SUCCESS' or 'C2 FAIL'."""
#     success, fail = 0, 0
#     with open(path) as f:
#         for line in f:
#             if "C2 SUCCESS" in line:
#                 success += 1
#             elif "C2 FAIL" in line:
#                 fail += 1
#     return success, fail

# def tcp_fail_ratio(path):
#     fails = 0
#     total = 0
#     with open(path) as f:
#         for line in f:
#             if "[TCP]" in line:
#                 total += 1
#                 if "FAIL" in line:
#                     fails += 1
#     return fails, total


# def main():
#     if len(sys.argv) < 3:
#         print("Usage: python3 compute_metrics.py <dns_log.txt> <bot_log.txt>")
#         sys.exit(1)
#     dns_path = sys.argv[1]
#     bot_path = sys.argv[2]
#     if not os.path.exists(dns_path):
#         print("DNS log not found:", dns_path)
#         sys.exit(1)
#     if not os.path.exists(bot_path):
#         print("Bot log not found:", bot_path)
#         sys.exit(1)

#     # --- DNS metrics ---
#     log = parse_dns_log(dns_path)
#     if log.empty:
#         print("No DNS entries in", dns_path)
#         bot_queries = pd.DataFrame(columns=["time", "type", "query"])
#     else:
#         bot_queries = log[log["query"].isin(C2_DOMAINS)]

#     total_bot_queries = len(bot_queries)
#     duration_sec = log["time"].max() - log["time"].min() if len(log) > 1 else 0
#     retry_rate_per_min = (total_bot_queries / (duration_sec / 60.0)) if duration_sec > 0 else total_bot_queries

#     if len(bot_queries) >= 2:
#         times = bot_queries["time"].values
#         deltas = np.diff(times)
#         inter_arrival_var = float(np.var(deltas))
#         inter_arrival_mean = float(np.mean(deltas))
#     else:
#         inter_arrival_var = 0.0
#         inter_arrival_mean = 0.0
#         deltas = np.array([])

#     tcp_fails, tcp_total = tcp_fail_ratio(bot_path)
#     print("TCP attempts logged:         ", tcp_total)
#     print("TCP failures logged:         ", tcp_fails)

#     # --- Bot log metrics ---
#     success, fail = parse_bot_log(bot_path)
#     total_beacons = success + fail
#     success_rate = (success / total_beacons * 100) if total_beacons > 0 else 0.0
#     failure_rate = (fail / total_beacons * 100) if total_beacons > 0 else 0.0
#     failure_burst_ratio = fail / total_beacons if total_beacons > 0 else 0


#     # --- Print report ---
#     base = os.path.basename(dns_path)
#     print("=== Metrics for", base, "===")
#     print("DNS bot queries (C2 lookups):", total_bot_queries)
#     print("Bot query rate (per min):    ", round(retry_rate_per_min, 2))
#     print("Inter-arrival mean (s):      ", round(inter_arrival_mean, 3))
#     print("Inter-arrival variance:      ", round(inter_arrival_var, 4))
#     print("C2 SUCCESS:                  ", success)
#     print("C2 FAIL:                     ", fail)
#     print("C2 success rate (%):         ", round(success_rate, 1))
#     print("C2 failure rate (%):         ", round(failure_rate, 1))
#     print("Failure burst ratio:         ", round(failure_burst_ratio, 3))

#     # --- Visualization (abnormal patterns) ---
#     fig, axes = plt.subplots(2, 1, figsize=(10, 8))

#     if len(bot_queries) > 0:
#         ax1 = axes[0]
#         ax1.scatter(bot_queries["time"], np.ones(len(bot_queries)), alpha=0.7, s=15)
#         ax1.set_xlabel("Time (s)")
#         ax1.set_ylabel("Bot DNS query")
#         ax1.set_title("Bot C2 DNS query timeline (bursts = retries)")
#         ax1.set_yticks([])
#     else:
#         axes[0].set_title("No bot DNS queries")
#         axes[0].set_ylabel("Bot DNS query")

#     if len(deltas) > 0:
#         ax2 = axes[1]
#         ax2.hist(deltas, bins=min(50, max(10, len(deltas))), edgecolor="black", alpha=0.7)
#         ax2.axvline(inter_arrival_mean, color="red", linestyle="--", label=f"mean={inter_arrival_mean:.2f}s")
#         ax2.set_xlabel("Inter-arrival time (s)")
#         ax2.set_ylabel("Count")
#         ax2.set_title("Inter-arrival distribution (variance = %.4f)" % inter_arrival_var)
#         ax2.legend()
#     else:
#         axes[1].set_title("Inter-arrival distribution (no data)")

#     plt.tight_layout()
#     out_name = "metrics_" + os.path.splitext(base)[0] + ".png"
#     plt.savefig(out_name, dpi=120)
#     print("Saved plot:", out_name)
#     plt.close()


# if __name__ == "__main__":
#     main()
#!/usr/bin/env python3
"""
MULTI-BOT METRICS COMPUTATION
Works for aggregated logs (12 bots, 10 min runtime)
"""

import sys
from pathlib import Path

BOT_COUNT = 12
RUNTIME_MINUTES = 10

if len(sys.argv) != 3:
    print("Usage: python compute_metrics.py <dns_log> <bot_log>")
    sys.exit(1)

dns_file = Path(sys.argv[1])
bot_file = Path(sys.argv[2])

if not dns_file.exists() or not bot_file.exists():
    print("Error: One or more log files not found.")
    sys.exit(1)

# ---------------------------
# BOT METRICS
# ---------------------------
success = 0
fail = 0

with bot_file.open() as f:
    for line in f:
        if "SUCCESS" in line:
            success += 1
        elif "FAIL" in line:
            fail += 1

total_attempts = success + fail
success_rate = (success / total_attempts * 100) if total_attempts else 0
fail_rate = (fail / total_attempts * 100) if total_attempts else 0

avg_success_per_bot = success / BOT_COUNT
avg_fail_per_bot = fail / BOT_COUNT

success_per_min = success / RUNTIME_MINUTES
fail_per_min = fail / RUNTIME_MINUTES

# ---------------------------
# DNS METRICS
# ---------------------------
dns_queries = 0

with dns_file.open() as f:
    for _ in f:
        dns_queries += 1

dns_per_min = dns_queries / RUNTIME_MINUTES
dns_per_bot = dns_queries / BOT_COUNT

# ---------------------------
# OUTPUT
# ---------------------------
print("====================================")
print("          METRICS SUMMARY")
print("====================================\n")

print("----------- BOT ACTIVITY -----------")
print(f"Total Attempts: {total_attempts}")
print(f"SUCCESS: {success}")
print(f"FAIL: {fail}")
print(f"Success Rate: {success_rate:.2f}%")
print(f"Failure Rate: {fail_rate:.2f}%")
print(f"Avg Success per Bot: {avg_success_per_bot:.2f}")
print(f"Avg Fail per Bot: {avg_fail_per_bot:.2f}")
print(f"Success per Minute: {success_per_min:.2f}")
print(f"Fail per Minute: {fail_per_min:.2f}\n")

print("----------- DNS ACTIVITY -----------")
print(f"Total DNS Queries: {dns_queries}")
print(f"DNS per Minute: {dns_per_min:.2f}")
print(f"DNS per Bot: {dns_per_bot:.2f}")

print("\n====================================")