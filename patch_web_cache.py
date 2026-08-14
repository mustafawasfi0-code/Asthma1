from pathlib import Path
root = Path(r'C:\Projects\flutter_app')
web = root / 'build' / 'web'
bootstrap = web / 'flutter_bootstrap.js'
s = bootstrap.read_text(encoding='utf-8')
s = s.replace('"mainJsPath":"main.dart.js"', '"mainJsPath":"main.dart.js?v=logout-button-20260726-3"')
start = s.find('_flutter.loader.load({')
if start != -1:
    s = s[:start] + """if ('serviceWorker' in navigator) {
  navigator.serviceWorker.getRegistrations().then(function(registrations) {
    for (var registration of registrations) { registration.unregister(); }
  });
}
_flutter.loader.load({
  serviceWorkerSettings: null
});
"""
bootstrap.write_text(s, encoding='utf-8')
server = root / 'serve_no_cache.py'
server.write_text(r'''from http.server import SimpleHTTPRequestHandler, ThreadingHTTPServer
from functools import partial

class NoCacheHandler(SimpleHTTPRequestHandler):
    def end_headers(self):
        self.send_header('Cache-Control', 'no-store, no-cache, must-revalidate, max-age=0')
        self.send_header('Pragma', 'no-cache')
        self.send_header('Expires', '0')
        super().end_headers()

handler = partial(NoCacheHandler, directory=r'C:\Projects\flutter_app\build\web')
ThreadingHTTPServer(('127.0.0.1', 4180), handler).serve_forever()
''', encoding='utf-8')
print('patched')
