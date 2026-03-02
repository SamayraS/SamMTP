# MTD IoT Simulation — IP + DNS + Port Hopping

Simulated IoT network in user space: devices use DNS to find C2, bots beacon periodically, MTD changes C2 mapping (IP/DNS/port), and detection is based on retry bursts and timing anomalies.

## Components

| File | Role |
|------|------|
| `dns_server.py` | Logs DNS queries, returns C2 IP for active domain (reads from files) |
| `c2_server.py` | Receives bot beacons; binds to port from `c2_port.txt` |
| `bot_client.py` | Infected IoT device: resolves C2 via DNS, beacons with jitter (2–6 s) |
| `normal_client.py` | Benign device (google.com); optional propagation via `infected.flag` |
| `mtd_engine.py` | Rotates C2 IP, port, and domain every 20 s |
| `compute_metrics.py` | Retry rate, inter-arrival variance, C2 success rate + plots |

## Setup

DNS server uses **port 5354** (5353 is often used by system mDNS).

```bash
cd mtd_iot
python3 -m venv .venv && .venv/bin/pip install -r requirements.txt
# or: pip3 install -r requirements.txt
```

Config files (already present): `c2_ip.txt`, `c2_port.txt`, `domain.txt`.

## Baseline run (no MTD)

```bash
python3 -u dns_server.py > dns_log_baseline.txt 2>&1 &
sleep 2
python3 -u c2_server.py > c2_log_baseline.txt 2>&1 &
sleep 2
python3 -u normal_client.py > normal_log_baseline.txt 2>&1 &
sleep 2
python3 -u bot_client.py > bot_log_baseline.txt 2>&1 &
```

Let run 1–2 minutes (or 20–30 for full baseline). Then stop:

```bash
pkill -f dns_server.py
pkill -f c2_server.py
pkill -f normal_client.py
pkill -f bot_client.py
```

## MTD run (with hopping)

```bash
python3 -u dns_server.py > dns_log_mtd.txt 2>&1 &
sleep 2
python3 -u c2_server.py > c2_log_mtd.txt 2>&1 &
sleep 2
python3 -u normal_client.py > normal_log_mtd.txt 2>&1 &
sleep 2
python3 -u bot_client.py > bot_log_mtd.txt 2>&1 &
sleep 2
python3 -u mtd_engine.py > mtd_log.txt 2>&1 &
```

Run 1–2 minutes. Stop all:

```bash
pkill -f dns_server.py
pkill -f c2_server.py
pkill -f normal_client.py
pkill -f bot_client.py
pkill -f mtd_engine.py
```

## Metrics

```bash
python3 compute_metrics.py dns_log_baseline.txt bot_log_baseline.txt
python3 compute_metrics.py dns_log_mtd.txt bot_log_mtd.txt
```

Output: DNS retry rate, inter-arrival variance, C2 success/failure rate, and PNG plots (`metrics_*.png`) for timeline and inter-arrival distribution.

## Multiple bots

```bash
for i in {1..10}; do python3 bot_client.py & done
```

## Expected results under MTD

- DNS retries (bot C2 lookups) increase  
- Inter-arrival variance increases  
- C2 success rate decreases  
- Normal traffic (google.com) unchanged  

## Push to GitHub

Remote is set to `https://github.com/saumyaseetha1006/SamMTP`. From project root:

```bash
git push -u origin main
```

If you use SSH: `git remote set-url origin git@github.com:saumyaseetha1006/SamMTP.git` then push.
