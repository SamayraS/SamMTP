"""
Benign IoT device: periodic DNS lookups (e.g. google.com). Unchanged by MTD.
Optional: if infected.flag exists, run as bot (propagation simulation).
"""
import socket
import time
import os

DNS = ("127.0.0.1", 5354)
CONFIG_DIR = os.path.dirname(os.path.abspath(__file__))


def main_normal():
    while True:
        s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
        s.sendto(b"google.com", DNS)
        s.recv(1024)
        time.sleep(5)


if __name__ == "__main__":
    flag_path = os.path.join(CONFIG_DIR, "infected.flag")
    if os.path.exists(flag_path):
        from bot_client import main as bot_main
        bot_main()
    else:
        main_normal()
