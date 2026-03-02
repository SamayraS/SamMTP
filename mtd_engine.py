"""
MTD engine: rotates C2 IP, port, and domain to break bot connectivity.
Causes retry bursts and timing anomalies (detection signals).
"""
import time
import os

CONFIG_DIR = os.path.dirname(os.path.abspath(__file__))

ips = ["127.0.0.1", "127.0.0.2", "127.0.0.3"]
ports = [9000, 9001, 9002]
domains = ["botc2.example", "botc2-alt.example"]


def write_c2_ip(ip):
    path = os.path.join(CONFIG_DIR, "c2_ip.txt")
    with open(path, "w") as f:
        f.write(ip)


def write_port(port):
    path = os.path.join(CONFIG_DIR, "c2_port.txt")
    with open(path, "w") as f:
        f.write(str(port))


def write_domain(domain):
    path = os.path.join(CONFIG_DIR, "domain.txt")
    with open(path, "w") as f:
        f.write(domain)


if __name__ == "__main__":
    cycle = 0
    while True:
        ip = ips[cycle % len(ips)]
        port = ports[cycle % len(ports)]
        domain = domains[cycle % len(domains)]
        print("Switching C2 →", ip, "port", port, "domain", domain)
        write_c2_ip(ip)
        write_port(port)
        write_domain(domain)
        cycle += 1
        time.sleep(20)
