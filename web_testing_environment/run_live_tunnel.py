import subprocess
import time
import re
import sys
import os
import threading

DIRECTORY = os.path.dirname(os.path.abspath(__file__))
os.chdir(DIRECTORY)

CLOUDFLARED = r"C:\Program Files (x86)\cloudflared\cloudflared.exe"
if not os.path.exists(CLOUDFLARED):
    CLOUDFLARED = "cloudflared"

print("=" * 68)
print("  RapidWrite Studio Server & Worldwide Cloudflare Tunnel")
print("=" * 68)

# 1. Start Python HTTP Server
server_proc = subprocess.Popen(
    [sys.executable, "server.py"],
    cwd=DIRECTORY
)
print("1. Local Server running on: http://localhost:8080/")

time.sleep(1.0)

# 2. Start Cloudflare Tunnel with HTTP/2 protocol for maximum stability
print("2. Connecting worldwide Cloudflare Tunnel (HTTP/2 stable protocol)...")

tunnel_proc = subprocess.Popen(
    [CLOUDFLARED, "tunnel", "--protocol", "http2", "--url", "http://127.0.0.1:8080"],
    stdout=subprocess.PIPE,
    stderr=subprocess.STDOUT,
    text=True,
    bufsize=1
)

public_url = None
url_event = threading.Event()

def drain_output():
    global public_url
    try:
        for line in tunnel_proc.stdout:
            sys.stdout.write(line)
            sys.stdout.flush()
            if not public_url:
                match = re.search(r"https://[a-zA-Z0-9-]+\.trycloudflare\.com", line)
                if match:
                    public_url = match.group(0)
                    url_event.set()
    except Exception:
        pass

# Drain thread ensures stdout pipe NEVER fills up or blocks cloudflared
drain_thread = threading.Thread(target=drain_output, daemon=True)
drain_thread.start()

# Wait up to 35 seconds for tunnel URL
url_event.wait(timeout=35)

if public_url:
    print("\n" + "=" * 68)
    print("  RAPIDWRITE STUDIO IS LIVE WORLDWIDE!")
    print(f"  Laptop URL:     http://localhost:8080/")
    print(f"  Worldwide Link: {public_url}")
    print("=" * 68)
    print("  Send the Worldwide Link to your friend on iPad and Android Tablet.")
    print("  It works across all networks (different Wi-Fi, 4G/5G, Hotspots).")
    print("=" * 68 + "\n")
    with open("ACTIVE_TUNNEL_LINK.txt", "w", encoding="utf-8") as f:
        f.write(public_url)
    with open("ACTIVE_TUNNEL_LINK.json", "w", encoding="utf-8") as f:
        import json
        json.dump({"url": public_url, "created_at": time.time()}, f)
else:
    print("\nCould not automatically parse tunnel URL. See logs above.")

try:
    while tunnel_proc.poll() is None and server_proc.poll() is None:
        time.sleep(1)
except KeyboardInterrupt:
    print("Shutting down...")
finally:
    if server_proc.poll() is None:
        server_proc.terminate()
    if tunnel_proc.poll() is None:
        tunnel_proc.terminate()
