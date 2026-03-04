"""
Simulated infected IoT device: resolves C2 via DNS (active domain), beacons to C2 IP:port.
Uses jitter (random 2–6s) for realistic beaconing. Reads port and domain from files.
"""
import socket
import time
import random
import os

DNS = ("127.0.0.1", 5354)
CONFIG_DIR = os.path.dirname(os.path.abspath(__file__))


def get_port():
    path = os.path.join(CONFIG_DIR, "c2_port.txt")
    with open(path) as f:
        return int(f.read().strip())


def get_domain():
    path = os.path.join(CONFIG_DIR, "domain.txt")
    if os.path.exists(path):
        with open(path) as f:
            return f.read().strip()
    return "botc2.example"


def resolve():
    s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    domain = get_domain()
    s.sendto(domain.encode(), DNS)
    return s.recv(1024).decode()


# def main():
#     while True:
#         try:
#             ip = resolve()
#             port = get_port()
#             s = socket.socket()
#             s.settimeout(2)
#             s.connect((ip, port))
#             s.send(b"beacon")
#             print("C2 SUCCESS")
#         except Exception:
#             print("C2 FAIL")
#         time.sleep(random.uniform(2, 6))
def main():
    while True:
        domain = get_domain()
        port = None
        ip = None

        try:
            t_dns_start = time.time()
            ip = resolve()
            t_dns_end = time.time()

            port = get_port()

            print(f"[DNS] domain={domain} ip={ip} time={(t_dns_end - t_dns_start):.4f}s")

            t_tcp_start = time.time()
            s = socket.socket()
            s.settimeout(2)
            s.connect((ip, port))
            t_tcp_end = time.time()

            s.send(b"beacon")
            print(f"[TCP] CONNECT SUCCESS ip={ip} port={port} connect_time={(t_tcp_end - t_tcp_start):.4f}s")
            print("C2 SUCCESS")

        except Exception as e:
            print(f"[TCP] CONNECT FAIL ip={ip} port={port} error={type(e).__name__}")
            print("C2 FAIL")

        time.sleep(random.uniform(2, 6))

if __name__ == "__main__":
    main()
