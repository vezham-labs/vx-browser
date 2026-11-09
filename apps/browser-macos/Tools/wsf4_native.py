#!/usr/bin/env python3
"""Run the actual debug browser against a disposable loopback fixture."""
import argparse
from datetime import datetime, timezone
from hashlib import sha256
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
import json
from pathlib import Path
import queue
import socket
import subprocess
import sys
import threading
import time
sys.dont_write_bytecode = True
from native_host import APP

STYLE = b"""<style>
html{background:#f5f3e9;color:#1b3530;font:16px system-ui}
body{margin:0}header{padding:25px 42px;border-bottom:1px solid #ddd9cd;font-size:13px;letter-spacing:.08em}
main{max-width:740px;margin:auto;padding:55px 38px}small{color:#526b58;text-transform:uppercase;letter-spacing:.14em}
h1{font:64px Georgia,serif;letter-spacing:-.055em;margin:14px 0}p{line-height:1.6;max-width:500px}
a{color:#155943} hr{border:0;border-top:1px solid #dadbd0;margin:34px 0}
</style>"""
FAVICON = b'<link rel="icon" href="data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk+A8AAQUBAScY42YAAAAASUVORK5CYII=">'
PAGES = {
    "/guide": (b"<title>Coastal Field Guide</title>" + FAVICON + STYLE +
               b"<header>COASTAL FIELD GUIDE</header><main><small>Field notes / 01</small>"
               b"<h1>Along the<br>water's edge.</h1><p>A short walk through the salt meadows, tidal pools and dunes of the north coast.</p>"
               b"<hr><a id='next' href='/notes'>Read the trail notes &rarr;</a></main>"),
    "/notes": b"<title>Trail Notes</title>" + FAVICON + STYLE + b"<main><h1>Trail notes</h1><p>Stay on the marked paths.</p><a id=mini-link target=_blank href=/guide>Open field guide</a></main>",
    "/state": (b"<title>Waiting</title><script>document.title = document.cookie.includes('fixture=') "
               b"? 'Prior Session' : 'Fresh Session';</script>"),
}


class Fixture(BaseHTTPRequestHandler):
    def do_GET(self):
        if self.path == "/broken":
            self.connection.shutdown(socket.SHUT_RDWR)
            self.close_connection = True
            return
        data = PAGES.get(self.path)
        if data is None:
            self.send_error(404)
            return
        self.send_response(200)
        self.send_header("Content-Type", "text/html; charset=utf-8")
        self.send_header("Cache-Control", "no-store")
        if self.path == "/guide":
            self.send_header("Set-Cookie", "fixture=owned-synthetic; SameSite=Strict; Path=/")
        self.send_header("Content-Length", str(len(data)))
        self.end_headers()
        self.wfile.write(data)

    def log_message(self, *_):
        pass


def run(evidence, attempt, origin, refinement=False):
    target = evidence / f"native-{attempt}"
    target.mkdir()
    binary = APP / "Contents/MacOS/VezhamBrowser"
    events = []
    screenshots = {}
    started = datetime.now(timezone.utc).isoformat()
    with (target / "stderr.log").open("wb") as errors:
        process = subprocess.Popen([binary, "--wsf4-qualification", origin, *(["--wsf4r-qualification"] if refinement else [])], stdout=subprocess.PIPE, stderr=errors)
        lines = queue.Queue()

        def read():
            for line in process.stdout:
                lines.put(line)
            lines.put(None)

        threading.Thread(target=read, daemon=True).start()
        deadline = time.monotonic() + (180 if refinement else 95)
        try:
            with (target / "stdout.log").open("wb") as raw:
                while time.monotonic() < deadline:
                    try:
                        line = lines.get(timeout=0.5)
                    except queue.Empty:
                        continue
                    if line is None:
                        break
                    raw.write(line)
                    raw.flush()
                    try:
                        event = json.loads(line)
                    except (ValueError, UnicodeError):
                        continue
                    if "externalURL" in event and refinement:
                        from urllib.parse import urlparse, parse_qs
                        wrapper = urlparse(event["externalURL"])
                        destination = parse_qs(wrapper.query).get("url", [""])[0]
                        parsed = urlparse(destination)
                        if wrapper.scheme != "vezham" or wrapper.netloc != "open" or parsed.hostname != "127.0.0.1":
                            raise RuntimeError("Unowned external fixture URL")
                        launch = subprocess.run(["open", "-a", str(APP), event["externalURL"]], capture_output=True, timeout=8)
                        (evidence / f"external-{attempt}.json").write_text(
                            json.dumps({"exit": launch.returncode, "stderr": launch.stderr.decode(errors="replace")}, indent=2) + "\n")
                    if "testID" in event:
                        events.append(event)
                    if event.get("testID") == "qualification":
                        break
                    if "screenshot" in event and attempt == 1:
                        name = event["screenshot"]
                        capture = subprocess.run(["screencapture", "-x", "-o", "-l", str(event["window"]),
                                                  str(target / f"{name}.png")], capture_output=True, timeout=6)
                        screenshots[name] = {"status": "captured" if capture.returncode == 0 else "blocked",
                                             "stderr": capture.stderr.decode(errors="replace").strip()}
        finally:
            if process.poll() is None:
                try:
                    process.wait(timeout=10)
                except subprocess.TimeoutExpired:
                    process.kill()
                    process.wait()
    passed = process.returncode == 0 and bool(events) and events[-1] == {"testID": "qualification", "status": "PASS_NATIVE"}
    result = {"startedUTC": started, "binarySHA256": sha256(binary.read_bytes()).hexdigest(),
              "attempt": attempt, "exit": process.returncode, "screenshots": screenshots,
              "events": events, "passed": passed}
    (target / "result.json").write_text(json.dumps(result, indent=2) + "\n")
    print(json.dumps({"attempt": attempt, "events": len(events), "passed": passed, "screenshots": screenshots}))
    return passed


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--evidence", type=Path, required=True)
    parser.add_argument("--run-name", required=True)
    parser.add_argument("--refinement", action="store_true")
    args = parser.parse_args()
    if not args.run_name.isascii() or not args.run_name.replace("-", "").isalnum():
        parser.error("Run name must use ASCII letters, digits and hyphens.")
    evidence = args.evidence.resolve() / args.run_name
    evidence.mkdir()
    info = subprocess.check_output(["/usr/libexec/PlistBuddy", "-c", "Print CFBundleIdentifier", APP / "Contents/Info.plist"], text=True).strip()
    if info != "internal.vezham.browser.wsf4.qualification":
        raise SystemExit("Build the isolated qualification bundle first.")
    with ThreadingHTTPServer(("127.0.0.1", 0), Fixture) as server:
        thread = threading.Thread(target=server.serve_forever, daemon=True)
        thread.start()
        origin = f"http://127.0.0.1:{server.server_port}"
        try:
            results = [run(evidence, i, origin, args.refinement) for i in (1, 2)]
        finally:
            server.shutdown()
    return 0 if all(results) else 1


if __name__ == "__main__":
    raise SystemExit(main())
