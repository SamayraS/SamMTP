import os
import glob
import numpy as np
import subprocess
from collections import defaultdict

PYTHON_BIN = ".venv/bin/python3" if os.path.exists(".venv/bin/python3") else "python3"

def compute_metric(dns_log, bot_log):
    result = subprocess.check_output(
        [PYTHON_BIN, "compute_metrics.py", dns_log, bot_log]
    ).decode()

    # Extract success rate from "Success Rate: 12.34%"
    for line in result.splitlines():
        if "Success Rate:" in line:
            value = line.split("Success Rate:")[-1].strip().rstrip("%")
            return float(value)
    return None

all_results = defaultdict(list)
run_dirs = glob.glob("all_config_logs/mode_*/ratio_*/run_*")

for path in run_dirs:
    if not os.path.isdir(path):
        continue
    if not os.path.exists(os.path.join(path, "COMPLETED")):
        continue

    dns = os.path.join(path, "dns_log_mtd.txt")
    bot = os.path.join(path, "bot_log_mtd.txt")
    if not (os.path.exists(dns) and os.path.exists(bot)):
        continue

    mode = os.path.basename(os.path.dirname(os.path.dirname(path))).replace("mode_", "")
    ratio = os.path.basename(os.path.dirname(path)).replace("ratio_", "").replace("_", ":")
    key = f"{mode} | ratio={ratio}"

    success_rate = compute_metric(dns, bot)
    if success_rate is not None:
        all_results[key].append(success_rate)

print("\n=== Aggregated Results ===\n")

for key, values in sorted(all_results.items()):
    mean = np.mean(values)
    std = np.std(values)

    print(f"{key} -> Runs: {len(values)} | Mean Success: {mean:.2f}% | Std Dev: {std:.2f}")