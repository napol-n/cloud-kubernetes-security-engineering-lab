import json
import os
from http.server import BaseHTTPRequestHandler, HTTPServer


HOST = "0.0.0.0"
PORT = int(os.getenv("PORT", "8080"))


class RequestHandler(BaseHTTPRequestHandler):
    def send_json(self, status_code, payload):
        body = json.dumps(payload).encode("utf-8")

        self.send_response(status_code)
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()

        self.wfile.write(body)

    def do_GET(self):
        if self.path == "/":
            self.send_json(
                200,
                {
                    "service": "cloud-kubernetes-security-lab",
                    "status": "running",
                },
            )
        elif self.path == "/health":
            self.send_json(200, {"status": "healthy"})
        else:
            self.send_json(404, {"error": "not found"})


if __name__ == "__main__":
    server = HTTPServer((HOST, PORT), RequestHandler)
    print(f"Listening on {HOST}:{PORT}", flush=True)
    server.serve_forever()
