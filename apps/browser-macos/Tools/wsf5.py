#!/usr/bin/env python3
"""Bounded WS-F5 qualification; stdlib only, no builds or handler registration.

Run with --app /exact/candidate.app --evidence docs/architecture/phase-5/reports/
WS-F5/evidence --run-name unique-name [--attempts 1|2]. --serve-only omits the
app launch, prints the owned origin, and serves for at most thirty minutes.
"""

import argparse
from datetime import datetime, timezone
import hashlib
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
import json
import os
from pathlib import Path
import platform
import plistlib
import re
import selectors
import signal
import socket
import subprocess
import sys
import threading
import time


REPO = Path(__file__).resolve().parents[3]
APP_ROOT = REPO / "apps/browser-macos"
EVIDENCE = REPO / "docs/architecture/phase-5/reports/WS-F5/evidence"
BUNDLE_ID = "internal.vezham.browser.wsf5.qualification"
TIMEOUT = 240
SERVE_SECONDS = 30 * 60
SAFE_NAME = re.compile(r"[A-Za-z0-9][A-Za-z0-9_-]{0,79}", re.ASCII)
PAGES = {
    "/alpha": b"<title>Alpha</title><h1>Alpha</h1><a href='/beta'>Beta</a>",
    "/beta": b"<title>Beta</title><h1>Beta</h1><a href='/gamma'>Gamma</a>",
    "/gamma": b"<title>Gamma</title><h1>Gamma</h1>",
    "/target": (b"<title>Target</title><h1>Target</h1>"
                b"<a id='popup' target='_blank' href='/beta'>Open Beta</a>"),
    # Intentionally no cookie headers, storage writes, or seeded state.
    "/storage": b"<title>Storage</title><h1>Storage</h1><p>Unseeded synthetic storage fixture.</p>",
}


def utc_now():
    return datetime.now(timezone.utc).isoformat()


def save(path, value):
    # Every evidence file is new; never truncate an existing artifact.
    with path.open("x", encoding="utf-8") as stream:
        json.dump(value, stream, indent=2, ensure_ascii=True)
        stream.write("\n")


class Fixture(BaseHTTPRequestHandler):
    timeout = 3
    server_version = "WSF5"
    sys_version = ""

    def log_message(self, *_):
        # Never record URLs, query strings, headers, credentials, or bodies.
        pass

    def do_GET(self):
        route = self.path.partition("?")[0]
        if route == "/failure":
            self.close_connection = True
            try:
                self.connection.shutdown(socket.SHUT_RDWR)
            except OSError:
                pass
            return
        if route == "/delay":
            if self.server.stopping.wait(2):
                return
            route = "/alpha"
        status, headers = 200, {}
        if route in ("/redirect", "/redirect302"):
            status, data = 302, b""
            headers["Location"] = "/beta"
        elif route == "/download":
            data = b"WS-F5 owned synthetic download.\n"
            headers["Content-Type"] = "text/plain; charset=utf-8"
            headers["Content-Disposition"] = 'attachment; filename="wsf5-synthetic.txt"'
        elif route in ("/auth", "/auth401"):
            # Always challenge; do not inspect or accept Authorization values.
            status, data = 401, b"Synthetic Basic authentication challenge."
            headers["WWW-Authenticate"] = 'Basic realm="WS-F5 synthetic"'
        else:
            data = PAGES.get(route)
            if data is None:
                status, data = 404, b"Not found"
        headers.setdefault("Content-Type", "text/html; charset=utf-8")
        try:
            self.send_response(status)
            for name, value in headers.items():
                self.send_header(name, value)
            self.send_header("Cache-Control", "no-store")
            self.send_header("Content-Length", str(len(data)))
            self.send_header("Connection", "close")
            self.end_headers()
            self.close_connection = True
            self.wfile.write(data)
        except (OSError, TimeoutError):
            pass


class FixtureServer(ThreadingHTTPServer):
    daemon_threads = True
    block_on_close = False
    allow_reuse_address = False

    def __init__(self, handler=Fixture):
        self.stopping = threading.Event()
        super().__init__(("127.0.0.1", 0), handler)

    def handle_error(self, request, client_address):
        # Base implementation prints request-related traceback information.
        pass


def digest(path):
    result = hashlib.sha256()
    with path.open("rb") as stream:
        for chunk in iter(lambda: stream.read(1024 * 1024), b""):
            result.update(chunk)
    return result.hexdigest()


def candidate(app):
    with (app / "Contents/Info.plist").open("rb") as stream:
        info = plistlib.load(stream)
    if info.get("CFBundleIdentifier") != BUNDLE_ID:
        raise ValueError("Exact WS-F5 qualification bundle ID required")
    executable = info.get("CFBundleExecutable")
    if not isinstance(executable, str) or not SAFE_NAME.fullmatch(executable):
        raise ValueError("Invalid bundle executable name")
    binary = app / "Contents/MacOS" / executable
    if not binary.is_file() or not os.access(binary, os.X_OK):
        raise ValueError("Bundle executable is missing or not executable")
    if not binary.resolve().is_relative_to(app.resolve()):
        raise ValueError("Bundle executable escapes the supplied app")
    return binary


def snapshot(app=None):
    roots = [APP_ROOT / name for name in ("Sources", "Config", "Chrome/src", "Tools",
                                         "StorageRuntime/Sources")]
    roots.append(REPO / "qualification/webkit-storage-f0/Sources")
    files = {path for root in roots for path in root.rglob("*")
             if path.is_file() and "__pycache__" not in path.parts}
    for name in ("Chrome/index.html", "Chrome/package.json", "StorageRuntime/Package.swift",
                 "VezhamBrowser.xcodeproj/project.pbxproj", "project.json"):
        path = APP_ROOT / name
        if path.is_file():
            files.add(path)
    for name in ("package.json", "pnpm-lock.yaml", "qualification/webkit-storage-f0/Package.swift"):
        path = REPO / name
        if path.is_file():
            files.add(path)
    sources = {str(path.relative_to(REPO)): digest(path) for path in sorted(files)}
    identity = {"sources": sources, "sourceSHA256": hashlib.sha256(
        json.dumps(sources, sort_keys=True).encode("utf-8")).hexdigest()}
    if app is not None:
        binary = candidate(app)
        identity.update(binary=str(binary), binarySHA256=digest(binary),
                        infoPlistSHA256=digest(app / "Contents/Info.plist"))
        resources = app / "Contents/Resources"
        identity["resources"] = {str(path.relative_to(resources)): digest(path)
                                 for path in sorted(resources.rglob("*")) if path.is_file()}
    return identity


def kill_owned(process):
    # The launch below creates a fresh process group; never use name-based kills.
    try:
        os.killpg(process.pid, signal.SIGKILL)
    except ProcessLookupError:
        pass


def capture(event, target, sequence, deadline):
    name, window = event.get("screenshot"), event.get("window")
    result = {"event": event}
    if (not isinstance(name, str) or not SAFE_NAME.fullmatch(name)
            or type(window) is not int or window <= 0):
        return dict(result, status="FAIL", reason="Invalid screenshot marker")
    remaining = deadline - time.monotonic()
    if remaining <= 0:
        return dict(result, status="FAIL", reason="Screenshot deadline exceeded")
    output = target / f"screenshot-{sequence:03d}-{name}.png"
    if output.exists():
        return dict(result, status="FAIL", reason="Screenshot already exists")
    command = ["/usr/sbin/screencapture", "-x", "-o", "-l", str(window), str(output)]
    try:
        completed = subprocess.run(command, capture_output=True, timeout=min(5, remaining))
        result.update(argv=command, exit=completed.returncode,
                      stderr=completed.stderr.decode("utf-8", errors="replace"), file=output.name)
        result["status"] = "CAPTURED" if completed.returncode == 0 and output.is_file() else "FAIL"
    except (OSError, subprocess.TimeoutExpired) as error:
        result.update(status="FAIL", reason=type(error).__name__)
    return result


def attempt(app, target, origin, baseline, flag="--wsf5-qualification"):
    target.mkdir()
    result = {"startedUTC": utc_now(), "status": "FAIL", "reasons": [],
              "timeout": False, "events": [], "screenshots": []}
    reasons = result["reasons"]
    process = None
    interrupted = False
    try:
        before = snapshot(app)
        save(target / "hashes-before.json", before)
        if before != baseline:
            raise ValueError("Candidate/source identity changed before attempt")
        argv = [str(candidate(app)), flag, origin]
        result["argv"] = argv
        deadline = time.monotonic() + TIMEOUT
        with (target / "stdout.log").open("xb", buffering=0) as stdout, \
                (target / "stderr.log").open("xb", buffering=0) as stderr, \
                (target / "events.jsonl").open("x", encoding="utf-8") as events, \
                selectors.DefaultSelector() as selector:
            process = subprocess.Popen(argv, stdout=subprocess.PIPE, stderr=subprocess.PIPE,
                                       stdin=subprocess.DEVNULL, start_new_session=True)
            result["pid"] = process.pid
            for pipe, raw in ((process.stdout, stdout), (process.stderr, stderr)):
                os.set_blocking(pipe.fileno(), False)
                selector.register(pipe, selectors.EVENT_READ, raw)
            pending = bytearray()
            oversized = False
            draining_until = None

            def event_line(line):
                try:
                    event = json.loads(line)
                except (ValueError, UnicodeError):
                    return
                if not isinstance(event, dict):
                    return
                events.write(json.dumps(event, ensure_ascii=True) + "\n")
                events.flush()
                if "testID" in event:
                    result["events"].append(event)
                if "screenshot" in event:
                    result["screenshots"].append(capture(
                        event, target, len(result["screenshots"]) + 1, deadline))

            # A qualification marker precedes NSApp.terminate teardown. Keep
            # draining both streams and require normal exit within the deadline.
            while selector.get_map() or process.poll() is None:
                now = time.monotonic()
                if draining_until is None and now >= deadline:
                    result["timeout"] = True
                    reasons.append("240-second timeout")
                    kill_owned(process)
                    draining_until = now + 2
                if draining_until is not None and now >= draining_until:
                    break
                for key, _ in selector.select(timeout=0.1):
                    chunk = os.read(key.fileobj.fileno(), 65536)
                    if not chunk:
                        selector.unregister(key.fileobj)
                        key.fileobj.close()
                        continue
                    key.data.write(chunk)
                    if key.data is not stdout:
                        continue
                    # Preserve raw output without allowing unbounded line buffering.
                    for part in chunk.splitlines(keepends=True):
                        if not oversized:
                            pending.extend(part)
                        if len(pending) > 1024 * 1024:
                            reasons.append("Oversized stdout event line")
                            pending.clear()
                            oversized = True
                        if part.endswith(b"\n"):
                            if not oversized:
                                event_line(bytes(pending))
                            pending.clear()
                            oversized = False
            if pending and not oversized:
                event_line(bytes(pending))
            process.wait(timeout=2)
    except KeyboardInterrupt:
        interrupted = True
        reasons.append("Interrupted")
    except Exception as error:
        reasons.append(f"{type(error).__name__}: {error}")
    finally:
        if process is not None:
            if process.poll() is None:
                kill_owned(process)
            try:
                process.wait(timeout=2)
            except subprocess.TimeoutExpired:
                reasons.append("Owned process did not reap after kill")
            for pipe in (process.stdout, process.stderr):
                if pipe is not None and not pipe.closed:
                    pipe.close()
            result["exit"] = process.returncode
            if process.returncode != 0:
                reasons.append("Nonzero/crashed process exit")
        try:
            after = snapshot(app)
            save(target / "hashes-after.json", after)
            if after != baseline:
                reasons.append("Candidate/source identity changed")
        except Exception as error:
            reasons.append(f"Post-run hashes unavailable: {type(error).__name__}: {error}")
        finals = [event for event in result["events"] if event.get("testID") == "qualification"]
        result["nativeFinal"] = finals[-1] if finals else None
        cases = [event for event in result["events"] if event.get("testID") != "qualification"]
        counts = {}
        for event in cases:
            status = str(event.get("status", "MISSING"))
            counts[status] = counts.get(status, 0) + 1
        result["caseStatusCounts"] = counts
        result["nativePassed"] = counts.get("PASS_NATIVE", 0)
        result["contractPassed"] = counts.get("PASS_CONTRACT", 0)
        if (len(finals) != 1 or finals[0].get("status") != "PASS_NATIVE"
                or result["events"][-1:] != finals):
            reasons.append("Missing, duplicate, nonpassing, or nonfinal qualification event")
        if any(event.get("status") not in ("PASS_NATIVE", "PASS_CONTRACT") for event in cases):
            reasons.append("Nonpassing test event; original status retained")
        if any(item["status"] != "CAPTURED" for item in result["screenshots"]):
            reasons.append("Screenshot evidence incomplete")
        if not reasons and process is not None and process.returncode == 0:
            result["status"] = "PASS_NATIVE"
        result["finishedUTC"] = utc_now()
        save(target / "result.json", result)
    return result, interrupted


def main(*, evidence_root=EVIDENCE, flag="--wsf5-qualification", server_factory=FixtureServer):
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--app", type=Path, help="Exact existing qualification .app bundle")
    parser.add_argument("--evidence", type=Path, required=True)
    parser.add_argument("--run-name", required=True)
    parser.add_argument("--attempts", type=int, choices=(1, 2), default=1)
    parser.add_argument("--serve-only", action="store_true")
    args = parser.parse_args()
    if not SAFE_NAME.fullmatch(args.run_name):
        parser.error("Run name must be 1-80 ASCII letters/digits/underscores/hyphens, starting alphanumeric")
    if args.evidence.resolve() != evidence_root or not evidence_root.is_dir():
        parser.error(f"Existing qualification evidence directory required: {evidence_root}")
    if not args.serve_only and args.app is None:
        parser.error("--app is required unless --serve-only is selected")
    app = args.app.absolute() if args.app is not None else None
    try:
        if app is not None:
            candidate(app)
        baseline = snapshot(app)
    except (OSError, ValueError, plistlib.InvalidFileException) as error:
        parser.error(str(error))
    target = evidence_root / args.run_name
    try:
        target.mkdir()  # Atomic refusal of any existing directory, file, or symlink.
    except FileExistsError:
        parser.error("Run directory already exists; use a unique --run-name")
    save(target / "hashes-before.json", baseline)
    record = {"startedUTC": utc_now(), "app": str(app) if app else None,
              "bundleID": BUNDLE_ID if app else None, "platform": platform.platform(),
              "mode": "serve-only" if args.serve_only else "qualification",
              "attemptsRequested": args.attempts, "timeoutSeconds": TIMEOUT,
              "serveLimitSeconds": SERVE_SECONDS, "attempts": [], "status": "FAIL",
              "nativePassed": 0, "contractPassed": 0, "caseStatusCounts": {},
              "countScope": "Non-qualification test-event observations across attempts"}
    interrupted = False
    server = None
    thread = None
    try:
        server = server_factory()
        thread = threading.Thread(target=server.serve_forever, kwargs={"poll_interval": 0.1}, daemon=True)
        thread.start()
        origin = f"http://127.0.0.1:{server.server_port}"
        save(target / "fixture.json", {"origin": origin, "requestLogging": False})
        if args.serve_only:
            print(origin, flush=True)
            server.stopping.wait(SERVE_SECONDS)
            record["status"] = "SERVED_ONLY"
        else:
            for number in range(1, args.attempts + 1):
                result, interrupted = attempt(app, target / f"attempt-{number}", origin, baseline, flag)
                record["attempts"].append({"attempt": number, "status": result["status"],
                                           "reasons": result["reasons"], "nativeFinal": result["nativeFinal"],
                                           "nativePassed": result["nativePassed"],
                                           "contractPassed": result["contractPassed"],
                                           "caseStatusCounts": result["caseStatusCounts"]})
                record["nativePassed"] += result["nativePassed"]
                record["contractPassed"] += result["contractPassed"]
                for status, count in result["caseStatusCounts"].items():
                    record["caseStatusCounts"][status] = record["caseStatusCounts"].get(status, 0) + count
                if interrupted:
                    break
            if len(record["attempts"]) == args.attempts and all(
                    item["status"] == "PASS_NATIVE" for item in record["attempts"]):
                record["status"] = "PASS_NATIVE"
    except KeyboardInterrupt:
        interrupted = True
        record["reason"] = "Interrupted"
    except Exception as error:
        record["reason"] = f"{type(error).__name__}: {error}"
    finally:
        if server is not None:
            server.stopping.set()
            if thread is not None and thread.is_alive():
                server.shutdown()
            server.server_close()
            if thread is not None:
                thread.join(timeout=2)
        try:
            after = snapshot(app)
            save(target / "hashes-after.json", after)
            if after != baseline:
                record.update(status="FAIL", reason="Candidate/source identity changed")
        except Exception as error:
            record.update(status="FAIL", reason=f"Post-run hashes unavailable: {error}")
        if interrupted:
            record["status"] = "FAIL"
        record["finishedUTC"] = utc_now()
        save(target / "summary.json", record)
    if not args.serve_only:
        print(json.dumps(record, ensure_ascii=True), flush=True)
    return 130 if interrupted else (0 if record["status"] in ("PASS_NATIVE", "SERVED_ONLY") else 1)


if __name__ == "__main__":
    def interrupt(_signum, _frame):
        raise KeyboardInterrupt

    signal.signal(signal.SIGTERM, interrupt)
    sys.exit(main())
