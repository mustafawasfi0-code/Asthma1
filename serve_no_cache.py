from http.server import SimpleHTTPRequestHandler, ThreadingHTTPServer
from functools import partial

class NoCacheHandler(SimpleHTTPRequestHandler):
    def end_headers(self):
        self.send_header('Cache-Control', 'no-store, no-cache, must-revalidate, max-age=0')
        self.send_header('Pragma', 'no-cache')
        self.send_header('Expires', '0')
        super().end_headers()

handler = partial(NoCacheHandler, directory=r'C:\Projects\flutter_app\build\web')
ThreadingHTTPServer(('127.0.0.1', 4180), handler).serve_forever()
