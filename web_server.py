#!/usr/bin/env python3
"""
HTTP/1.1 서버: Range Request(206) + CORS 완전 지원
동영상 스트리밍을 위한 Partial Content 응답 처리
"""
import os, sys, socket, mimetypes
from http.server import HTTPServer, BaseHTTPRequestHandler

ROOT = os.path.join(os.path.dirname(__file__), 'build', 'web')
PORT = int(sys.argv[1]) if len(sys.argv) > 1 else 5060


class RangeHandler(BaseHTTPRequestHandler):
    protocol_version = 'HTTP/1.1'      # ← 핵심: 1.1 필수

    # ── CORS + 동영상 스트리밍 헤더 ──────────────────
    def _cors(self):
        self.send_header('Access-Control-Allow-Origin', '*')
        self.send_header('Access-Control-Allow-Methods', 'GET, HEAD, OPTIONS')
        self.send_header('Access-Control-Allow-Headers', 'Range, Content-Type')
        self.send_header('Access-Control-Expose-Headers', 'Content-Range, Accept-Ranges, Content-Length')
        self.send_header('X-Frame-Options', 'ALLOWALL')
        self.send_header('Content-Security-Policy', 'frame-ancestors *')

    def do_OPTIONS(self):
        self.send_response(200)
        self._cors()
        self.send_header('Content-Length', '0')
        self.end_headers()

    def do_HEAD(self):
        self._serve(head_only=True)

    def do_GET(self):
        self._serve(head_only=False)

    def _serve(self, head_only=False):
        # URL → 파일 경로
        path = self.path.split('?')[0]
        fpath = os.path.join(ROOT, path.lstrip('/'))

        # 디렉토리 → index.html
        if os.path.isdir(fpath):
            fpath = os.path.join(fpath, 'index.html')

        # 파일 없음
        if not os.path.isfile(fpath):
            # SPA 폴백: index.html
            idx = os.path.join(ROOT, 'index.html')
            if os.path.isfile(idx):
                fpath = idx
            else:
                self.send_response(404)
                self.send_header('Content-Length', '0')
                self.end_headers()
                return

        size   = os.path.getsize(fpath)
        mime   = mimetypes.guess_type(fpath)[0] or 'application/octet-stream'
        rng    = self.headers.get('Range', '')

        # ── Range 요청 처리 (206 Partial Content) ──
        if rng.startswith('bytes='):
            try:
                parts = rng[6:].split('-')
                start = int(parts[0]) if parts[0] else 0
                end   = int(parts[1]) if parts[1] else size - 1
                end   = min(end, size - 1)
                length = end - start + 1

                self.send_response(206)
                self._cors()
                self.send_header('Content-Type', mime)
                self.send_header('Content-Length', str(length))
                self.send_header('Content-Range', f'bytes {start}-{end}/{size}')
                self.send_header('Accept-Ranges', 'bytes')
                self.end_headers()

                if not head_only:
                    with open(fpath, 'rb') as f:
                        f.seek(start)
                        remaining = length
                        while remaining > 0:
                            chunk = f.read(min(65536, remaining))
                            if not chunk:
                                break
                            self.wfile.write(chunk)
                            remaining -= len(chunk)
                return
            except Exception:
                pass  # 파싱 실패 시 전체 전송

        # ── 일반 요청 (200 OK) ──
        self.send_response(200)
        self._cors()
        self.send_header('Content-Type', mime)
        self.send_header('Content-Length', str(size))
        self.send_header('Accept-Ranges', 'bytes')
        self.end_headers()

        if not head_only:
            with open(fpath, 'rb') as f:
                while True:
                    chunk = f.read(65536)
                    if not chunk:
                        break
                    self.wfile.write(chunk)

    def log_message(self, fmt, *args):
        pass  # 조용한 로그


class ReusableServer(HTTPServer):
    allow_reuse_address = True


if __name__ == '__main__':
    server = ReusableServer(('0.0.0.0', PORT), RangeHandler)
    print(f'Serving {ROOT} on port {PORT} (HTTP/1.1 + Range + CORS)')
    server.serve_forever()
