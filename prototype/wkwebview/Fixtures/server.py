#!/usr/bin/env python3
"""Loopback-only synthetic website fixture; never serves real user content."""
import json
from http.server import BaseHTTPRequestHandler, HTTPServer
from urllib.parse import parse_qs, unquote, urlparse


class Fixture(BaseHTTPRequestHandler):
    def do_GET(self):
        parsed = urlparse(self.path)
        query = parse_qs(parsed.query)
        if parsed.path == "/upload-status":
            result = getattr(self.server, "upload_result", {"status": "pending"})
            body = json.dumps(result).encode()
            self.send_response(200)
            self.send_header("Content-Type", "application/json")
            self.send_header("Content-Length", str(len(body)))
            self.end_headers()
            self.wfile.write(body)
            return
        if parsed.path == "/permission-status":
            result = getattr(self.server, "permission_result", {"status": "pending"})
            body = json.dumps(result).encode()
            self.send_response(200)
            self.send_header("Content-Type", "application/json")
            self.send_header("Content-Length", str(len(body)))
            self.end_headers()
            self.wfile.write(body)
            return
        if parsed.path == "/permission-fixture":
            html = b"""<!doctype html><meta charset='utf-8'><title>Vezham Permission Fixture</title>
<h1>Media denial check</h1><p>This synthetic page will request camera and microphone only after you press the button. Denying the request does not grant device access.</p>
<button id='request' type='button'>Request camera and microphone</button><pre id='status'></pre>
<script>
const status=document.querySelector('#status');
const media= navigator.mediaDevices;
status.textContent='secureContext='+window.isSecureContext+'; mediaDevices='+typeof media+'; getUserMedia='+typeof media?.getUserMedia+'; waiting for explicit test click';
document.querySelector('#request').addEventListener('click',async()=>{
  status.textContent='Waiting for the native permission decision...';
  let result;
  try {
    const stream=await navigator.mediaDevices.getUserMedia({audio:true,video:true});
    for(const track of stream.getTracks()) track.stop();
    result={status:'granted',errorName:null};
    status.textContent='Unexpectedly granted';
  } catch(error) {
    result={status:error.name==='NotAllowedError'?'denied':'error',errorName:error.name};
    status.textContent=result.status==='denied'?'Request denied':'Request error: '+error.name;
  }
  await fetch('/permission-status',{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify(result)});
});
</script>"""
            self.send_response(200)
            self.send_header("Content-Type", "text/html; charset=utf-8")
            self.send_header("Cache-Control", "no-store")
            self.send_header("Content-Length", str(len(html)))
            self.end_headers()
            self.wfile.write(html)
            return
        if parsed.path == "/upload-fixture":
            html = b"""<!doctype html><meta charset='utf-8'><title>Vezham Upload Fixture</title>
<h1>Local upload check</h1><p>Choose the synthetic fixture file to send it to the loopback test server.</p>
<input id='file' type='file' hidden><button id='choose' type='button'>Choose test file</button><pre id='status'>Waiting for file selection</pre>
<script>
const input=document.querySelector('#file'), status=document.querySelector('#status');
document.querySelector('#choose').addEventListener('click',()=>input.click());
input.addEventListener('change',async()=>{
  const file=input.files[0]; if(!file) return;
  status.textContent='Uploading synthetic file...';
  try { const response=await fetch('/upload-fixture',{method:'POST',headers:{'X-Fixture-Filename':encodeURIComponent(file.name)},body:file});
    status.textContent=JSON.stringify(await response.json());
  } catch(error) { status.textContent='Upload request failed'; }
});
</script>"""
            self.send_response(200)
            self.send_header("Content-Type", "text/html; charset=utf-8")
            self.send_header("Cache-Control", "no-store")
            self.send_header("Content-Length", str(len(html)))
            self.end_headers()
            self.wfile.write(html)
            return
        if parsed.path == "/transfer-download":
            body = b"Vezham synthetic download fixture\n"
            self.send_response(200)
            self.send_header("Content-Type", "application/octet-stream")
            self.send_header("Content-Disposition", 'attachment; filename="../../synthetic-download.bin"')
            self.send_header("Content-Length", str(len(body)))
            self.end_headers()
            self.wfile.write(body)
            return
        if parsed.path == "/crash-fixture":
            body = b"<!doctype html><meta charset='utf-8'><title>WK Recovery Fixture</title><h1>Local recovery page</h1>"
            self.send_response(200)
            self.send_header("Content-Type", "text/html; charset=utf-8")
            self.send_header("Cache-Control", "no-store")
            self.send_header("Content-Length", str(len(body)))
            self.end_headers()
            self.wfile.write(body)
            return
        if parsed.path == "/cookie-check":
            value = "missing"
            for item in self.headers.get("Cookie", "").split(";"):
                name, _, candidate = item.strip().partition("=")
                if name == "fixture_auth":
                    value = candidate
            body = value.encode()
            self.send_response(200)
            self.send_header("Content-Type", "text/plain; charset=utf-8")
            self.send_header("Content-Length", str(len(body)))
            self.end_headers()
            self.wfile.write(body)
            return
        if parsed.path == "/http-cache-marker":
            self.server.cache_sequence = getattr(self.server, "cache_sequence", 0) + 1
            value = "missing"
            for item in self.headers.get("Cookie", "").split(";"):
                name, _, candidate = item.strip().partition("=")
                if name == "fixture_auth":
                    value = candidate
            body = value.encode()
            self.send_response(200)
            self.send_header("Content-Type", "text/plain; charset=utf-8")
            self.send_header("Cache-Control", "public, max-age=1800")
            self.send_header("X-Fixture-Cache-Generation", str(self.server.cache_sequence))
            self.send_header("Content-Length", str(len(body)))
            self.end_headers()
            self.wfile.write(body)
            return
        if parsed.path == "/service-worker.js":
            body = b"self.addEventListener('install', e => self.skipWaiting()); self.addEventListener('activate', e => e.waitUntil(self.clients.claim()));"
            self.send_response(200)
            self.send_header("Content-Type", "text/javascript")
            self.send_header("Service-Worker-Allowed", "/")
            self.send_header("Cache-Control", "no-store")
            self.send_header("Content-Length", str(len(body)))
            self.end_headers()
            self.wfile.write(body)
            return
        if parsed.path not in ("/", "/fixture"):
            self.send_error(404)
            return
        profile = query.get("profile", ["unknown"])[0]
        mode = query.get("mode", ["seed"])[0]
        if profile not in ("a", "b", "private") or mode not in ("seed", "verify"):
            self.send_error(400)
            return
        marker = "marker-" + profile
        html = f"""<!doctype html>
<meta charset="utf-8"><meta name="viewport" content="width=device-width">
<title>Vezham Local Isolation Fixture</title>
<h1>Local WKWebView fixture</h1><pre id="result">initializing</pre>
<script>
window.fixtureReady = (async () => {{
  const mode = {mode!r};
  const marker = {marker!r};
  const request = indexedDB.open('VezhamFixture', 1);
  request.onupgradeneeded = () => {{ if (!request.result.objectStoreNames.contains('state')) request.result.createObjectStore('state'); }};
  const db = await new Promise((resolve, reject) => {{ request.onsuccess = () => resolve(request.result); request.onerror = () => reject(request.error); }});
  if (mode === 'seed') {{
    if (!localStorage.getItem('fixture-marker')) localStorage.setItem('fixture-marker', marker);
    if (!await new Promise((resolve, reject) => {{ const tx = db.transaction('state'); const get = tx.objectStore('state').get('marker'); get.onsuccess = () => resolve(get.result); get.onerror = () => reject(get.error); }})) {{
      await new Promise((resolve, reject) => {{ const tx = db.transaction('state', 'readwrite'); tx.objectStore('state').put(marker, 'marker'); tx.oncomplete = resolve; tx.onerror = () => reject(tx.error); }});
    }}
    if ('serviceWorker' in navigator) {{ await navigator.serviceWorker.register('/service-worker.js'); await navigator.serviceWorker.ready; }}
    const cache = await caches.open('vezham-fixture-v1');
    if (!(await cache.match('/fixture-marker'))) await cache.put('/fixture-marker', new Response(marker));
  }}
  const idb = await new Promise((resolve, reject) => {{ const get = db.transaction('state').objectStore('state').get('marker'); get.onsuccess = () => resolve(get.result || null); get.onerror = () => reject(get.error); }});
  const cache = await caches.open('vezham-fixture-v1');
  const cached = await cache.match('/fixture-marker');
  return {{ profile: {profile!r}, local: localStorage.getItem('fixture-marker'), indexedDB: idb,
    cache: cached ? await cached.text() : null, serviceWorker: (await navigator.serviceWorker.getRegistrations()).length > 0,
    bridgeAbsent: !window.webkit || !window.webkit.messageHandlers || !window.webkit.messageHandlers.vezham }};
}})();
window.fixtureReady.then(x => document.getElementById('result').textContent = JSON.stringify(x));
window.fixtureState = async () => {{ await window.fixtureReady; const auth = await (await fetch('/cookie-check', {{cache:'no-store'}})).text(); const cacheResponse = await fetch('/http-cache-marker'); const httpCache = await cacheResponse.text(); const httpCacheGeneration = cacheResponse.headers.get('X-Fixture-Cache-Generation'); return {{...await window.fixtureReady, auth, httpCache, httpCacheGeneration}}; }};
</script>""".encode()
        self.send_response(200)
        self.send_header("Content-Type", "text/html; charset=utf-8")
        self.send_header("Cache-Control", "no-store")
        if mode == "seed":
            self.send_header("Set-Cookie", f"fixture_auth={marker}; Path=/; Max-Age=1800; SameSite=Lax")
        self.send_header("Content-Length", str(len(html)))
        self.end_headers()
        self.wfile.write(html)

    def do_POST(self):
        path = urlparse(self.path).path
        if path == "/permission-status":
            length = int(self.headers.get("Content-Length", "0"))
            try:
                result = json.loads(self.rfile.read(min(length, 4096)))
                if not isinstance(result, dict):
                    raise ValueError("expected object")
            except (json.JSONDecodeError, ValueError):
                self.send_error(400)
                return
            self.server.permission_result = result
            body = b"ok"
            self.send_response(200)
            self.send_header("Content-Length", str(len(body)))
            self.end_headers()
            self.wfile.write(body)
            return
        if path != "/upload-fixture":
            self.send_error(404)
            return
        length = int(self.headers.get("Content-Length", "0"))
        payload = self.rfile.read(min(length, 1_048_577))
        expected = b"Vezham synthetic upload fixture\n"
        filename = unquote(self.headers.get("X-Fixture-Filename", ""))
        checks = [
            {"label": "selected fixture filename received", "passed": filename == "upload-fixture.txt"},
            {"label": "uploaded bytes match synthetic fixture", "passed": payload == expected},
            {"label": "upload stayed within the loopback fixture", "passed": length <= 1_048_576 and len(payload) == length},
        ]
        failures = [check["label"] for check in checks if not check["passed"]]
        result = {"mode": "upload", "status": "passed" if not failures else "failed", "tests": checks,
                  "failureCount": len(failures), "failures": failures, "filename": filename, "byteCount": len(payload)}
        self.server.upload_result = result
        body = json.dumps(result).encode()
        self.send_response(200)
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)

    def log_message(self, fmt, *args):
        # Avoid query strings/markers; emit only the path.
        print(f"fixture request {urlparse(self.path).path}", flush=True)


HTTPServer(("127.0.0.1", 18765), Fixture).serve_forever()
