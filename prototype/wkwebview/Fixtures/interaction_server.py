#!/usr/bin/env python3
"""Synthetic interaction fixture; loopback only, with no real files or accounts."""
import json
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from urllib.parse import parse_qs, urlparse

MARKER = "synthetic-private-marker"


class InteractionFixture(BaseHTTPRequestHandler):
    def reply(self, body, content_type="text/html; charset=utf-8", headers=None):
        body = body.encode() if isinstance(body, str) else body
        self.send_response(200)
        self.send_header("Content-Type", content_type)
        self.send_header("Content-Length", str(len(body)))
        self.send_header("Cache-Control", "no-store")
        for name, value in (headers or {}).items():
            self.send_header(name, value)
        self.end_headers()
        self.wfile.write(body)

    def do_GET(self):
        parsed = urlparse(self.path)
        if parsed.path == "/interaction-state":
            self.reply(json.dumps(self.server.observations), "application/json")
        elif parsed.path == "/interaction-fixture":
            self.reply("""<!doctype html><meta charset="utf-8"><title>Vezham Local Interaction Checks</title>
<h1>Local interaction checks</h1><p>Only synthetic data on loopback is used.</p>
<p><button id="choose">Open upload picker</button> <button id="check">Check upload selection</button></p>
<input id="file" type="file" hidden><p id="status">No file selected</p>
<p><a href="/interaction-download">Open download save panel</a></p>
<p><a href="/interaction-redirect">Follow local redirect</a></p>
<p><a href="/interaction-result?case=popup" target="_blank">Open same-session popup</a></p>
<p><a href="vezham-unsupported://fixture">Try unsupported navigation</a></p>
<script>
localStorage.setItem('interaction-marker','synthetic-private-marker');
const input=document.querySelector('#file'), status=document.querySelector('#status');
document.querySelector('#choose').onclick=()=>input.click();
document.querySelector('#check').onclick=async()=>{
  await fetch('/interaction-event',{method:'POST',headers:{'Content-Type':'application/json'},
    body:JSON.stringify({kind:'upload-check',fileCount:input.files.length})});
  status.textContent='Selected files: '+input.files.length;
};
input.onchange=async()=>{
  for(const file of input.files) await fetch('/interaction-upload',{method:'POST',body:file});
  status.textContent='Unexpected file selection';
};
</script>""", headers={"Set-Cookie": f"interaction_profile={MARKER}; Path=/; SameSite=Lax"})
        elif parsed.path == "/interaction-redirect":
            self.send_response(302)
            self.send_header("Location", "/interaction-result?case=redirect")
            self.send_header("Content-Length", "0")
            self.send_header("Cache-Control", "no-store")
            self.end_headers()
        elif parsed.path == "/interaction-result":
            kind = parse_qs(parsed.query).get("case", [""])[0]
            if kind not in ("redirect", "popup"):
                self.send_error(400)
                return
            self.reply("""<!doctype html><meta charset="utf-8"><title>Vezham Interaction Result</title>
<h1>Interaction result</h1><pre id="result">Checking session data...</pre>
<a href="/interaction-fixture">Return to checks</a>
<script>
const kind=new URLSearchParams(location.search).get('case');
const result={kind,marker:localStorage.getItem('interaction-marker'),
  cookiePresent:document.cookie.split(';').some(x=>x.trim()==='interaction_profile=synthetic-private-marker'),
  bridgeAbsent:!window.webkit||!window.webkit.messageHandlers||!window.webkit.messageHandlers.vezham};
fetch('/interaction-event',{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify(result)})
  .then(()=>document.querySelector('#result').textContent=JSON.stringify(result));
</script>""")
        elif parsed.path == "/interaction-download":
            self.server.observations["downloadResponses"] += 1
            self.reply(b"Vezham synthetic cancellation fixture\n", "application/octet-stream",
                       {"Content-Disposition": 'attachment; filename="cancel-fixture.txt"'})
        else:
            self.send_error(404)

    def do_POST(self):
        length = int(self.headers.get("Content-Length", "0"))
        if length < 0 or length > 1_048_576:
            self.send_error(413)
            return
        payload = self.rfile.read(length)
        if self.path == "/interaction-upload":
            self.server.observations["uploadRequests"] += 1
            self.server.observations["uploadBytes"] += len(payload)
        elif self.path == "/interaction-event":
            try:
                value = json.loads(payload)
                if not isinstance(value, dict) or value.get("kind") not in ("upload-check", "redirect", "popup"):
                    raise ValueError("unexpected event")
            except (ValueError, json.JSONDecodeError):
                self.send_error(400)
                return
            self.server.observations["events"].append(value)
        else:
            self.send_error(404)
            return
        self.reply(b"ok", "text/plain")

    def log_message(self, fmt, *args):
        print("interaction fixture request", urlparse(self.path).path, flush=True)


if __name__ == "__main__":
    server = ThreadingHTTPServer(("127.0.0.1", 18765), InteractionFixture)
    server.observations = {"uploadRequests": 0, "uploadBytes": 0, "downloadResponses": 0, "events": []}
    server.serve_forever()
