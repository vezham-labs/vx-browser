#!/usr/bin/env python3
"""Two-origin synthetic fixture for the final local feasibility checks."""
import json
import socket
import threading
import time
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from urllib.parse import parse_qs, urlparse

A = "http://127.0.0.1:18765"
B = "http://127.0.0.1:18766"
STATE = {"events": [], "uploads": [], "downloadRequests": []}
LOCK = threading.Lock()


class Fixture(BaseHTTPRequestHandler):
    def reply(self, body, kind="text/html; charset=utf-8", headers=None):
        data = body.encode() if isinstance(body, str) else body
        self.send_response(200)
        self.send_header("Content-Type", kind)
        self.send_header("Content-Length", str(len(data)))
        self.send_header("Cache-Control", "no-store")
        for key, value in (headers or {}).items(): self.send_header(key, value)
        self.end_headers()
        try: self.wfile.write(data)
        except (BrokenPipeError, ConnectionResetError): pass

    def redirect(self, destination):
        self.send_response(302)
        self.send_header("Location", destination)
        self.send_header("Content-Length", "0")
        self.send_header("Cache-Control", "no-store")
        self.end_headers()

    def do_GET(self):
        p = urlparse(self.path)
        query = parse_qs(p.query)
        if p.path == "/state":
            with LOCK: value = json.dumps(STATE)
            return self.reply(value, "application/json")
        if p.path == "/benchmark-page":
            prefix = b"<!doctype html><meta charset=utf-8><title>Phase 3 1 MB fixture</title><main>"
            suffix = b"</main>"
            return self.reply(prefix + b"x" * (1_048_576-len(prefix)-len(suffix)) + suffix)
        if p.path == "/phase3":
            return self.reply("""<!doctype html><meta charset=utf-8><title>Phase 3 final local checks</title>
<h1>Phase 3 final local checks</h1><pre id=status>Loading hostile frame checks...</pre>
<p><button id=multi>Choose two synthetic files</button><input id=files type=file multiple hidden></p>
<p><button id=directory>Choose synthetic folder</button><input id=folder type=file webkitdirectory hidden></p>
<p><a href=/duplicate>Try duplicate download name</a> (cancel replacement and the save panel)</p>
<p><a href=/interrupted>Save interrupted synthetic download</a></p>
<p><a href=/complete>Save completed synthetic download</a></p>
<p><a href=/redirect-cross>Follow cross-origin redirect</a></p>
<p><a href='http://127.0.0.1:18766/cross-result?case=popup' target=_blank>Open cross-origin popup</a></p>
<iframe src='http://127.0.0.1:18766/hostile-frame' title='Synthetic hostile frame'></iframe>
<script>
localStorage.setItem('phase3-A-secret','A-only-synthetic-marker');
let messages=0;
window.addEventListener('message',async event=>{
 if(event.origin!=='http://127.0.0.1:18766')return;
 if(event.data.kind==='untrusted-command'){messages++;return;}
 if(event.data.kind==='frame-result'){
   const result={...event.data,receivedMessages:messages};
   await fetch('/event',{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify(result)});
   document.querySelector('#status').textContent=JSON.stringify(result);
 }
});
async function upload(input,kind){
 const files=[];
 for(const file of input.files) files.push({name:file.name,relativePath:file.webkitRelativePath,content:await file.text(),size:file.size});
 const response=await fetch('/upload',{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify({kind,files})});
 document.querySelector('#status').textContent=await response.text();
}
const files=document.querySelector('#files'), folder=document.querySelector('#folder');
document.querySelector('#multi').onclick=()=>files.click();
document.querySelector('#directory').onclick=()=>folder.click();
files.onchange=()=>upload(files,'multiple');folder.onchange=()=>upload(folder,'directory');
</script>""")
        if p.path == "/hostile-frame":
            return self.reply("""<!doctype html><meta charset=utf-8><title>Hostile frame fixture</title>
<p>Cross-origin frame attempts</p><script>
(async()=>{
let parentReadDenied=false,reachable=0,throws=0;
try{void parent.document.body.innerHTML;}catch(e){parentReadDenied=e.name==='SecurityError';}
for(let i=0;i<100;i++){
 const payload=i===99?{method:'native',data:'x'.repeat(262144)}:
   [null,42,'not-an-envelope',{version:999,command:'read-file'},
    {version:1,requestID:'replay',viewID:'stale',profileID:'wrong',command:'native'}][i%5];
 try{window.webkit.messageHandlers.vezham.postMessage(payload);reachable++;}catch(e){throws++;}
 parent.postMessage({kind:'untrusted-command',payload},'http://127.0.0.1:18765');
}
parent.postMessage({kind:'frame-result',attemptCount:100,reachable,throws,parentReadDenied,
 bridgeAbsent:!window.webkit||!window.webkit.messageHandlers||!window.webkit.messageHandlers.vezham},'http://127.0.0.1:18765');
location.href='vezham-ui://settings';
})();
</script>""")
        if p.path == "/redirect-cross": return self.redirect(B + "/cross-result?case=redirect")
        if p.path == "/blocked-redirect": return self.redirect("vezham-ui://settings")
        if p.path == "/cross-result":
            case = query.get("case", [""])[0]
            if case not in ("redirect", "popup"): return self.send_error(400)
            return self.reply("""<!doctype html><meta charset=utf-8><title>Cross-origin result</title>
<h1>Cross-origin result</h1><pre id=result>Checking...</pre>
<p><a href='http://127.0.0.1:18765/phase3'>Return to final checks</a></p>
<p><a href=/blocked-redirect>Try redirect to privileged scheme</a></p>
<script>
const result={kind:new URLSearchParams(location.search).get('case'),origin:location.origin,
 AStorageAbsent:localStorage.getItem('phase3-A-secret')===null,
 bridgeAbsent:!window.webkit||!window.webkit.messageHandlers||!window.webkit.messageHandlers.vezham};
fetch('/event',{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify(result)})
 .then(()=>document.querySelector('#result').textContent=JSON.stringify(result));
</script>""")
        if p.path in ("/duplicate", "/interrupted", "/complete"):
            with LOCK: STATE["downloadRequests"].append(p.path)
            if p.path == "/duplicate":
                return self.reply(b"replacement must not be saved\n", "application/octet-stream", {"Content-Disposition": 'attachment; filename="existing.txt"'})
            if p.path == "/complete":
                return self.reply(b"complete synthetic payload\n", "application/octet-stream", {"Content-Disposition": 'attachment; filename="complete.txt"'})
            self.send_response(200)
            self.send_header("Content-Type", "application/octet-stream")
            self.send_header("Content-Disposition", 'attachment; filename="interrupted.bin"')
            self.send_header("Content-Length", "1048576")
            self.end_headers()
            try:
                self.wfile.write(b"incomplete synthetic payload\n")
                self.wfile.flush()
                time.sleep(2)
                self.connection.shutdown(socket.SHUT_RDWR)
            except OSError: pass
            self.close_connection = True
            return
        self.send_error(404)

    def do_POST(self):
        size = int(self.headers.get("Content-Length", "0"))
        if size < 0 or size > 1_048_576: return self.send_error(413)
        try:
            value = json.loads(self.rfile.read(size))
            if not isinstance(value, dict): raise ValueError()
        except (ValueError, json.JSONDecodeError): return self.send_error(400)
        with LOCK:
            if self.path == "/event": STATE["events"].append(value)
            elif self.path == "/upload": STATE["uploads"].append(value)
            else: return self.send_error(404)
        self.reply(json.dumps({"received": value.get("kind"), "fileCount": len(value.get("files", []))}), "application/json")

    def log_message(self, fmt, *args): pass


if __name__ == "__main__":
    servers = [ThreadingHTTPServer(("127.0.0.1", port), Fixture) for port in (18765,18766)]
    for server in servers: threading.Thread(target=server.serve_forever, daemon=True).start()
    threading.Event().wait()
