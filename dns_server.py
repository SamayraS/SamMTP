"""
DNS server: logs all queries and returns C2 IP for active domain.
Reads C2 IP and active domain from files (MTD can change them).
"""
from socketserver import UDPServer, BaseRequestHandler
import time
import os

CONFIG_DIR = os.path.dirname(os.path.abspath(__file__))


def get_c2_ip():
    path = os.path.join(CONFIG_DIR, "c2_ip.txt")
    with open(path) as f:
        return f.read().strip()


def get_domain():
    path = os.path.join(CONFIG_DIR, "domain.txt")
    if os.path.exists(path):
        with open(path) as f:
            return f.read().strip()
    return "botc2.example"


class DNSHandler(BaseRequestHandler):
    def handle(self):
        data, sock = self.request
        query = data.decode().strip()
        # print(f"{time.time()} QUERY {query}")
        now = time.time()
        active_domain = get_domain()

        if query == active_domain:
            response = get_c2_ip()
            print(f"{now} QUERY {query} -> C2_IP {response}")
        else:
            response = "8.8.8.8"
            print(f"{now} QUERY {query} -> DEFAULT {response}")
        active_domain = get_domain()
        if query == active_domain:
            response = get_c2_ip()
        else:
            response = "8.8.8.8"
        sock.sendto(response.encode(), self.client_address)


if __name__ == "__main__":
    UDPServer(("127.0.0.1", 5354), DNSHandler).serve_forever()
