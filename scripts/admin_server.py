import http.server
import socketserver
import json
import os
import sys

# 強制控制台輸出為 UTF-8 並開啟 line_buffering 確保即時顯示
if sys.platform == "win32":
    import io
    sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8', line_buffering=True)
    sys.stderr = io.TextIOWrapper(sys.stderr.buffer, encoding='utf-8', line_buffering=True)
else:
    # 確保非 Windows 環境也能即時輸出
    import sys
    sys.stdout.reconfigure(line_buffering=True)


PORT = 8080
BASE_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
DATA_DIR = os.path.join(BASE_DIR, "assets", "data")
WEB_DIR = os.path.join(BASE_DIR, "web")

class AdminHandler(http.server.SimpleHTTPRequestHandler):
    def end_headers(self):
        self.send_header('Access-Control-Allow-Origin', '*')
        # 防止瀏覽器快取
        self.send_header('Cache-Control', 'no-store, no-cache, must-revalidate, max-age=0')
        super().end_headers()

    def do_GET(self):
        if self.path == '/':
            self.send_response(200)
            self.send_header("Content-type", "text/html; charset=utf-8")
            self.end_headers()
            with open(os.path.join(WEB_DIR, "admin.html"), "r", encoding="utf-8") as f:
                self.wfile.write(f.read().encode('utf-8'))
        elif self.path == '/api/toaddlist':
            self.send_response(200)
            self.send_header("Content-type", "application/json; charset=utf-8")
            self.end_headers()
            txt_path = os.path.join(DATA_DIR, "toaddlist.txt")
            content = ""
            if os.path.exists(txt_path):
                with open(txt_path, "r", encoding="utf-8") as f:
                    content = f.read()
            self.wfile.write(json.dumps({"text": content}).encode('utf-8'))
        elif self.path == '/api/shops':
            self.serve_json("shops.json")
        elif self.path == '/api/payments':
            self.serve_json("payment_methods.json")
        else:
            self.send_error(404, "Not Found")

    def serve_json(self, filename):
        self.send_response(200)
        self.send_header("Content-type", "application/json; charset=utf-8")
        self.end_headers()
        path = os.path.join(DATA_DIR, filename)
        if os.path.exists(path):
            with open(path, "r", encoding="utf-8") as f:
                self.wfile.write(f.read().encode('utf-8'))
        else:
            self.wfile.write(b"[]")

    def do_POST(self):
        if self.path == '/api/save':
            content_length = int(self.headers['Content-Length'])
            post_data = self.rfile.read(content_length)
            try:
                data = json.loads(post_data.decode('utf-8'))
                store_discounts = data.get("discounts", [])
                product_discounts = data.get("discounts_product", [])
                
                # Append to discounts.json
                self.append_to_file("discounts.json", store_discounts)
                # Append to discounts_product.json
                self.append_to_file("discounts_product.json", product_discounts)
                
                # Clear toaddlist.txt
                with open(os.path.join(DATA_DIR, "toaddlist.txt"), "w", encoding="utf-8") as f:
                    f.write("")
                
                self.send_response(200)
                self.send_header("Content-type", "application/json; charset=utf-8")
                self.end_headers()
                self.wfile.write(json.dumps({"status": "ok"}).encode('utf-8'))
            except Exception as e:
                self.send_response(500)
                self.end_headers()
                self.wfile.write(str(e).encode('utf-8'))
                print(e)
                
    def append_to_file(self, filename, new_items):
        if not new_items:
            return
        path = os.path.join(DATA_DIR, filename)
        existing = []
        if os.path.exists(path):
            with open(path, "r", encoding="utf-8") as f:
                try:
                    existing = json.load(f)
                except ValueError:
                    pass
        existing.extend(new_items)
        with open(path, "w", encoding="utf-8") as f:
            json.dump(existing, f, ensure_ascii=False, indent=4)

if __name__ == "__main__":
    import threading
    import webbrowser
    os.makedirs(TOOLS_DIR, exist_ok=True)
    with socketserver.TCPServer(("", PORT), AdminHandler) as httpd:
        print(f"Server activated! Local Admin URL: http://localhost:{PORT}/")
        try:
            threading.Timer(1.25, lambda: webbrowser.open(f'http://localhost:{PORT}/')).start()
            httpd.serve_forever()
        except KeyboardInterrupt:
            print("\nShutting down admin server...")
            httpd.shutdown()
