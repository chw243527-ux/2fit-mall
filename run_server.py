import http.server
import socketserver
import os
import socket

os.chdir('/home/user/flutter_app/build/web')

class CORSHandler(http.server.SimpleHTTPRequestHandler):
    def end_headers(self):
        self.send_header('Access-Control-Allow-Origin', '*')
        self.send_header('X-Frame-Options', 'ALLOWALL')
        self.send_header('Content-Security-Policy', 'frame-ancestors *')
        super().end_headers()
    def log_message(self, format, *args):
        pass

class ReusableTCPServer(socketserver.TCPServer):
    allow_reuse_address = True
    def server_bind(self):
        self.socket.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
        self.socket.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEPORT, 1)
        super().server_bind()

with ReusableTCPServer(('0.0.0.0', 5060), CORSHandler) as httpd:
    print("Server running on port 5060", flush=True)
    httpd.serve_forever()
