#!/usr/bin/env python3
"""
Populate an Excel workbook from batch_results: one sheet for the full batch.
All hop/run folders are combined into a single sheet with one row per run.
"""
import os
from openpyxl import Workbook

BASE_DIR = "batch_results"
OUTPUT_FILE = "batch_results.xlsx"
SHEET_NAME = "Batch_Results"

if not os.path.exists(BASE_DIR):
    raise FileNotFoundError(f"Directory not found: {BASE_DIR}")

HEADERS = [
    "Hop_Interval",
    "Run",
    "Baseline_Success_Rate",
    "MTD_Success_Rate",
    "Baseline_Accepted_Beacons",
    "MTD_Accepted_Beacons",
    "Baseline_DNS_Queries",
    "MTD_DNS_Queries",
]


def parse_bot_log(path):
    success = 0
    fail = 0
    if os.path.getsize(path) == 0:
        raise ValueError(f"Empty log: {path}")
    with open(path, "r", errors="ignore") as f:
        for line in f:
            if "SUCCESS" in line:
                success += 1
            if "FAIL" in line:
                fail += 1
    total = success + fail
    return (success / total) * 100 if total > 0 else 0


def count_lines(path):
    if os.path.getsize(path) == 0:
        raise ValueError(f"Empty log: {path}")
    with open(path, "r", errors="ignore") as f:
        return sum(1 for _ in f)


def collect_run_row(run_path, folder):
    parts = folder.split("_")
    hop = int(parts[1])
    run = int(parts[3])
    bot_base = os.path.join(run_path, "bot_log_baseline.txt")
    bot_mtd = os.path.join(run_path, "bot_log_mtd.txt")
    c2_base = os.path.join(run_path, "c2_log_baseline.txt")
    c2_mtd = os.path.join(run_path, "c2_log_mtd.txt")
    dns_base = os.path.join(run_path, "dns_log_baseline.txt")
    dns_mtd = os.path.join(run_path, "dns_log_mtd.txt")
    required = [bot_base, bot_mtd, c2_base, c2_mtd, dns_base, dns_mtd]
    if not all(os.path.exists(p) for p in required):
        return None
    base_sr = round(parse_bot_log(bot_base), 2)
    mtd_sr = round(parse_bot_log(bot_mtd), 2)
    base_beacons = count_lines(c2_base)
    mtd_beacons = count_lines(c2_mtd)
    base_dns = count_lines(dns_base)
    mtd_dns = count_lines(dns_mtd)
    return [hop, run, base_sr, mtd_sr, base_beacons, mtd_beacons, base_dns, mtd_dns]


def main():
    folders = sorted(f for f in os.listdir(BASE_DIR) if f.startswith("hop_") and os.path.isdir(os.path.join(BASE_DIR, f)))
    if not folders:
        print("No hop_* folders found in batch_results.")
        return

    wb = Workbook()
    ws = wb.active
    ws.title = SHEET_NAME
    ws.append(HEADERS)

    for folder in folders:
        run_path = os.path.join(BASE_DIR, folder)
        row_data = collect_run_row(run_path, folder)
        if row_data is None:
            print(f"Skipping incomplete folder: {folder}")
            continue
        ws.append(row_data)

    wb.save(OUTPUT_FILE)
    print(f"Excel file generated: {OUTPUT_FILE} (1 sheet: {SHEET_NAME}, {ws.max_row - 1} rows)")


if __name__ == "__main__":
    main()
