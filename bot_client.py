"""
Simulated infected IoT device (Adaptive Version)

Features:
- DNS re-resolution on every attempt
- Randomized backoff on failure
- Beacon jitter (2–6s)
- Detailed logging for metrics
"""

import socket
import time
import random
import os

DNS_SERVER = ("127.0.0.1", 5354)
CONFIG_DIR = os.path.dirname(os.path.abspath(__file__))

BACKOFF_MIN = 1
BACKOFF_MAX = 5
JITTER_MIN = 2
JITTER_MAX = 6


def get_port():
    with open(os.path.join(CONFIG_DIR, "c2_port.txt")) as f:
        return int(f.read().strip())


def get_domain():
    path = os.path.join(CONFIG_DIR, "domain.txt")
    if os.path.exists(path):
        with open(path) as f:
            return f.read().strip()
    return "botc2.example"


def resolve(domain):
    s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    s.settimeout(2)
    s.sendto(domain.encode(), DNS_SERVER)
    return s.recv(1024).decode()


def main():
    while True:
        ip = None
        port = None
        domain = get_domain()

        try:
            # --- DNS Resolution ---
            t_dns_start = time.time()
            ip = resolve(domain)
            t_dns_end = time.time()

            port = get_port()

            print(f"[DNS] domain={domain} ip={ip} time={(t_dns_end - t_dns_start):.4f}s")

            # --- TCP Connect ---
            t_tcp_start = time.time()
            s = socket.socket()
            s.settimeout(2)
            s.connect((ip, port))
            t_tcp_end = time.time()

            s.send(b"beacon")

            print(f"[TCP] SUCCESS ip={ip} port={port} connect_time={(t_tcp_end - t_tcp_start):.4f}s")
            print("C2 SUCCESS")

            s.close()

            # Success jitter
            time.sleep(random.uniform(JITTER_MIN, JITTER_MAX))

        except Exception as e:
            print(f"[TCP] FAIL ip={ip} port={port} error={type(e).__name__}")
            print("C2 FAIL")

            # Adaptive Backoff
            backoff = random.uniform(BACKOFF_MIN, BACKOFF_MAX)
            print(f"[BACKOFF] sleeping={backoff:.2f}s")
            time.sleep(backoff)


if __name__ == "__main__":
    main()