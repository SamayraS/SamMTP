import os
import glob
import numpy as np
import subprocess

def compute_metric(dns_log, bot_log):
    result = subprocess.check_output(
        [".venv/bin/python3", "compute_metrics.py", dns_log, bot_log]
    ).decode()

    # Extract success rate
    for line in result.splitlines():
        if "Client Success Rate" in line:
            return float(line.split()[-2])
    return None


base_dir = "batch_results_*"
folders = glob.glob(base_dir)

all_results = {}

for folder in folders:
    for sub in os.listdir(folder):
        path = os.path.join(folder, sub)
        if os.path.isdir(path):

            hop = sub.split("_")[1]

            dns = os.path.join(path, "dns_log_mtd.txt")
            bot = os.path.join(path, "bot_log_mtd.txt")

            success_rate = compute_metric(dns, bot)

            if success_rate is not None:
                all_results.setdefault(hop, []).append(success_rate)

print("\n=== Aggregated Results ===\n")

for hop, values in sorted(all_results.items()):
    mean = np.mean(values)
    std = np.std(values)

    print(f"Hop {hop}s → Mean Success: {mean:.2f}% | Std Dev: {std:.2f}")