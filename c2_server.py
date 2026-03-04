"""
C2 server: receives bot beacons. Binds to dynamic port from file (MTD port hopping).
Optional: writes infected.flag to simulate propagation (normal hosts become bots).
"""
import socket
import time
import os

CONFIG_DIR = os.path.dirname(os.path.abspath(__file__))


def get_port():
    path = os.path.join(CONFIG_DIR, "c2_port.txt")
    with open(path) as f:
        return int(f.read().strip())


if __name__ == "__main__":
    while True:
        port = get_port()
        s = socket.socket()
        s.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
        s.bind(("127.0.0.1", port))
        s.listen()
        print("C2 on port", port)
        conn, addr = s.accept()
        conn.recv(1024)
        # print("Beacon from", addr)
        print(f"{time.time()} BEACON from {addr} on port {port}")
        conn.close()
        s.close()
        # Optional propagation: mark that C2 was reached (for normal_client infection sim)
        flag_path = os.path.join(CONFIG_DIR, "infected.flag")
        with open(flag_path, "w") as f:
            f.write("1")
