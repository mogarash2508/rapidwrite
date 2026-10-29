import http.server
import socketserver
import os
import sys
import json
import urllib.request
import urllib.error
import socket

PORT = 8080
DIRECTORY = os.path.dirname(os.path.abspath(__file__))

GOOGLE_DIGITAL_INK_URL = "https://www.google.com/inputtools/request?ime=handwriting&app=autopen&text_type=json"

class Handler(http.server.SimpleHTTPRequestHandler):
    def __init__(self, *args, **kwargs):
        super().__init__(*args, directory=DIRECTORY, **kwargs)

    def end_headers(self):
        # Enable CORS and disable caching so live changes show immediately
        self.send_header('Access-Control-Allow-Origin', '*')
        self.send_header('Access-Control-Allow-Methods', 'GET, POST, OPTIONS')
        self.send_header('Access-Control-Allow-Headers', 'Content-Type')
        self.send_header('Cache-Control', 'no-store, no-cache, must-revalidate')
        super().end_headers()

    def do_OPTIONS(self):
        self.send_response(200)
        self.end_headers()

    def do_POST(self):
        if self.path == '/api/digital-ink':
            self.handle_google_digital_ink()
        else:
            self.send_response(404)
            self.end_headers()

    def handle_google_digital_ink(self):
        try:
            content_length = int(self.headers.get('Content-Length', 0))
            post_data = self.rfile.read(content_length)
            req_json = json.loads(post_data.decode('utf-8'))

            strokes = req_json.get('strokes', [])
            canvas_width = int(req_json.get('canvasWidth', 1024))
            canvas_height = int(req_json.get('canvasHeight', 600))
            language = req_json.get('language', 'en')

            # Convert strokes into Google Digital Ink format: [ [ [x...], [y...], [t...] ], ... ]
            ink_array = []
            for stroke in strokes:
                points = stroke.get('points', []) if isinstance(stroke, dict) else stroke
                if not points:
                    continue
                xs = [int(p.get('x', 0)) for p in points]
                ys = [int(p.get('y', 0)) for p in points]
                ts = [int(p.get('t', 0)) for p in points]
                ink_array.append([xs, ys, ts])

            if not ink_array:
                self.send_response(200)
                self.send_header('Content-Type', 'application/json')
                self.end_headers()
                self.wfile.write(json.dumps({
                    "status": "success",
                    "text": "",
                    "candidates": [],
                    "engine": "Google Digital Ink (Web Engine)"
                }).encode('utf-8'))
                return

            google_payload = {
                "options": "enable_pre_space",
                "requests": [{
                    "writing_guide": {
                        "writing_area_width": canvas_width,
                        "writing_area_height": canvas_height
                    },
                    "pre_context": "",
                    "max_num_results": 5,
                    "max_completions": 0,
                    "language": language,
                    "ink": ink_array
                }]
            }

            req = urllib.request.Request(
                GOOGLE_DIGITAL_INK_URL,
                data=json.dumps(google_payload).encode('utf-8'),
                headers={"Content-Type": "application/json"}
            )

            try:
                with urllib.request.urlopen(req, timeout=10) as response:
                    raw_res = response.read().decode('utf-8')
                    parsed = json.loads(raw_res)
                    # Expected format: ["SUCCESS", [["requests", ["candidate1", "candidate2", ...]]]]
                    candidates = []
                    if isinstance(parsed, list) and len(parsed) > 1:
                        nested = parsed[1]
                        if isinstance(nested, list) and len(nested) > 0 and len(nested[0]) > 1:
                            candidates = nested[0][1]

                    recognized_text = candidates[0] if candidates else ""

                    self.send_response(200)
                    self.send_header('Content-Type', 'application/json')
                    self.end_headers()
                    self.wfile.write(json.dumps({
                        "status": "success",
                        "text": recognized_text,
                        "candidates": candidates,
                        "engine": "Google Digital Ink (Web Engine)"
                    }).encode('utf-8'))
                    return
            except Exception as net_err:
                print(f"[Google Digital Ink] Cloud endpoint notice: {net_err}")
                self.send_response(200)
                self.send_header('Content-Type', 'application/json')
                self.end_headers()
                self.wfile.write(json.dumps({
                    "status": "fallback",
                    "message": str(net_err),
                    "engine": "Google Digital Ink Fallback"
                }).encode('utf-8'))
                return

        except Exception as e:
            self.send_response(500)
            self.send_header('Content-Type', 'application/json')
            self.end_headers()
            self.wfile.write(json.dumps({
                "status": "error",
                "error": str(e)
            }).encode('utf-8'))

def get_local_ip():
    try:
        s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
        s.connect(("8.8.8.8", 80))
        ip = s.getsockname()[0]
        s.close()
        return ip
    except Exception:
        return "127.0.0.1"

if __name__ == '__main__':
    os.chdir(DIRECTORY)
    socketserver.TCPServer.allow_reuse_address = True
    local_ip = get_local_ip()
    with socketserver.TCPServer(("", PORT), Handler) as httpd:
        print("=" * 68)
        print("  RapidWrite Handwriting Evaluator Server is LIVE!")
        print("  Google Digital Ink ML Kit recognition endpoint: /api/digital-ink")
        print("-" * 68)
        print(f"  Laptop Browser:       http://localhost:{PORT}/")
        print(f"  Mobile Phone Browser: http://{local_ip}:{PORT}/")
        print("-" * 68)
        print("  MOBILE / IPAD NOTE:")
        print("  1. Connect your iPad / tablet & laptop to the same Wi-Fi.")
        print(f"  2. In your iPad Safari browser, enter: http://{local_ip}:{PORT}/")
        print("=" * 68)
        try:
            httpd.serve_forever()
        except KeyboardInterrupt:
            print("\nServer stopped.")
            httpd.server_close()
