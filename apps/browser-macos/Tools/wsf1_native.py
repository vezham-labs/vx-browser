"""Finite native app qualification. Only owned children and registered synthetic UUIDs."""
import copy
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
import json
from pathlib import Path
import platform
import queue
import subprocess
import threading
import time
import uuid

FIXTURES = Path(__file__).resolve().parent / "fixtures"

def execute(run, build_record, diagnostic_record, resume_record=None, phase="all"):
    build = json.loads(build_record.read_text())
    diagnostic = json.loads(diagnostic_record.read_text())
    accepted = {"internal.vezham.browser.wsf1.qualification"}
    if run.evidence == run.evidence.parents[2] / "reports/WS-F4/evidence":
        accepted.add("internal.vezham.browser.wsf4.qualification")
    for record, bundle_ids in [(build, accepted), (diagnostic, {"internal.vx.M1Validation.run20261108T094414Z"})]:
        if record["status"] != "PASS_CONTRACT" or record["bundleID"] not in bundle_ids:
            raise SystemExit("Verified exact qualification bundles required")
        from wsf1 import digest
        if digest(Path(record["bundle"]) / "Contents/MacOS/VezhamBrowser") != record["binarySHA256"]:
            raise SystemExit("Build identity mismatch")
    requests = []
    class Handler(BaseHTTPRequestHandler):
        def do_GET(self):
            path = self.path.split("?", 1)[0]
            if path not in {"/fixture", "/sw.js", "/cacheable", "/sw-probe", "/favicon.ico"}:
                self.send_error(404); return
            requests.append({"path": path, "ordinal": len(requests) + 1})
            content = (FIXTURES / ("storage.html" if path == "/fixture" else "sw.js")).read_bytes() if path in {"/fixture", "/sw.js"} else ("response-" + str(len(requests)) if path == "/cacheable" else "network").encode()
            self.send_response(200)
            self.send_header("Content-Type", "application/javascript" if path == "/sw.js" else "text/html" if path == "/fixture" else "text/plain")
            self.send_header("Content-Length", str(len(content)))
            self.send_header("Cache-Control", "public,max-age=86400" if path == "/cacheable" else "no-store")
            self.end_headers(); self.wfile.write(content)
        def log_message(self, *_): pass
    resume = json.loads(resume_record.read_text()) if resume_record else None
    resume_input = json.loads((resume_record.parent / "03-private-input.json").read_text()) if resume_record else None
    if resume_record and (run.evidence not in resume_record.resolve().parents or not resume.get("checkpoint")):
        raise SystemExit("Registered prior synthetic checkpoint required")
    if phase == "persistent-lifecycle" and not resume:
        raise SystemExit("Independent lifecycle phase requires a registered prior checkpoint; private failure is not waived")
    from urllib.parse import urlparse
    server = ThreadingHTTPServer(("127.0.0.1", urlparse(resume_input["origin"]).port if resume_input else 0), Handler)
    thread = threading.Thread(target=server.serve_forever, daemon=True); thread.start()
    origin = "http://127.0.0.1:" + str(server.server_port)
    profiles = [{"name": name, "profile": str(uuid.uuid4()), "store": str(uuid.uuid4())} for name in ["A", "B"]]
    initial = {"namespace": str(uuid.uuid4()), "profiles": profiles, "origin": origin, "checkpoint": None, "cutpoint": None}
    if resume_input:
        initial = {**resume_input, "checkpoint": resume["checkpoint"], "cutpoint": None}
    run.save("fixtures.json", {**initial, "fixtureSHA256": {p.name: __import__('hashlib').sha256(p.read_bytes()).hexdigest() for p in FIXTURES.iterdir()}, "originalsModified": False})
    attempts = []
    def host(label, action, configuration, record=build, cutpoint=None, expected_kill=False):
        payload = {**configuration, "action": action, "cutpoint": cutpoint}
        run.save(label + "-input.json", payload)
        executable = Path(record["bundle"]) / "Contents/MacOS/VezhamBrowser"
        stderr = (run.out / (label + ".stderr")).open("wb")
        p = subprocess.Popen([str(executable), "--wsf1-qualification"], stdin=subprocess.PIPE, stdout=subprocess.PIPE, stderr=stderr)
        p.stdin.write(json.dumps(payload).encode()); p.stdin.close()
        q = queue.Queue()
        def read():
            for line in p.stdout: q.put(line)
            q.put(None)
        reader = threading.Thread(target=read, daemon=True); reader.start()
        lines, events, timed_out, killed = [], [], False, False
        deadline = time.monotonic() + 120
        while True:
            remaining = deadline - time.monotonic()
            if remaining <= 0:
                p.kill(); timed_out = True; break
            try: line = q.get(timeout=min(remaining, 1))
            except queue.Empty:
                if p.poll() is not None and not reader.is_alive(): break
                continue
            if line is None: break
            lines.append(line)
            try: event = json.loads(line)
            except (ValueError, UnicodeError): continue
            events.append(event)
            if expected_kill and event.get("event") == cutpoint:
                p.kill(); killed = True
        try: p.wait(timeout=5)
        except subprocess.TimeoutExpired: p.kill(); p.wait()
        reader.join(timeout=2); stderr.close()
        (run.out / (label + ".stdout")).write_bytes(b"".join(lines))
        checkpoints = [x["checkpoint"] for x in events if "checkpoint" in x]
        finals = [x for x in events if x.get("event") == "result"]
        result = finals[-1] if finals else {}
        ok = killed and p.returncode == -9 if expected_kill else p.returncode == 0 and bool(finals) and all(x["status"] != "FAIL" for x in result.get("cases", []))
        info = {"label": label, "pid": p.pid, "action": action, "cutpoint": cutpoint, "expectedKill": expected_kill, "cutpointObserved": killed,
                "returncode": p.returncode, "timeout": timed_out, "status": "PASS_NATIVE" if ok and not timed_out else "FAIL", "result": result,
                "checkpoint": checkpoints[-1] if checkpoints else configuration.get("checkpoint"), "binarySHA256": record["binarySHA256"],
                "observations": [x for x in events if "-values-" in x.get("event", "")]}
        run.save(label + "-result.json", info); attempts.append(info)
        print(json.dumps({"label": label, "status": info["status"], "returncode": p.returncode, "cases": len(result.get("cases", []))}), flush=True)
        if not ok or timed_out:
            raise RuntimeError("Native run stopped at " + label + "; no unchanged retry or unsafe cleanup")
        return info
    try:
        # Gate: exact original namespace; noncreating observation, no factories/removal.
        host("00-original-observation", "enumerate-original", initial, record=diagnostic)
        if phase == "private-only":
            host("private-only", "private-only", initial)
            stopped = host("private-only-interrupted", "private-only", initial, cutpoint="private-active", expected_kill=True)
            restarted = {**initial, "checkpoint": stopped["checkpoint"]}
            host("private-only-restart", "private-only", restarted)
            return
        if resume_record:
            seeds = [p for p in run.evidence.glob("native-*/01-seed-input.json") if json.loads(p.read_text())["profiles"] == initial["profiles"] and json.loads(p.read_text())["namespace"] == initial["namespace"]]
            if len(seeds) != 1: raise RuntimeError("Exact original synthetic seed evidence required")
            seeded = json.loads((seeds[0].parent / "01-seed-result.json").read_text())
        else: seeded = host("01-seed", "seed", initial)
        state = {**initial, "checkpoint": resume["checkpoint"] if resume else seeded["checkpoint"]}
        verified = host("02-restart", "verify", state)
        state["checkpoint"] = verified["checkpoint"]
        seed_values = {x["event"].split("-")[-1]: x["environment"] for x in seeded["observations"]}
        http_results = [{"id": "F1-NAT-RESTART-" + x["event"].split("-")[-1] + "-http", "status": "PASS_NATIVE" if x["environment"].get("http") == seed_values[x["event"].split("-")[-1]].get("http") else "INCONCLUSIVE", "detail": "HTTP cache response identity across actual process restart; eviction/persistence may differ"} for x in verified["observations"]]
        run.save("http-cache-results.json", http_results)
        if phase == "all":
            switched = host("02b-switch", "switch", state)
            state["checkpoint"] = switched["checkpoint"]
            private = host("03-private", "private", state)
            state["checkpoint"] = private["checkpoint"]
            interrupted_private = host("03b-private-interrupted", "private", state, cutpoint="private-active", expected_kill=True)
            state["checkpoint"] = interrupted_private["checkpoint"]
            private_restart = host("03c-private-restart", "private", state)
            state["checkpoint"] = private_restart["checkpoint"]
        else:
            run.save("private-gate-not-waived.json", {"status": "FAIL", "evidence": str(resume_record), "scope": "Independent persistent lifecycle only; no private retry or qualification claim"})
        cleared = host("04-clear", "clear", state)
        state["checkpoint"] = cleared["checkpoint"]
        host("05-remove", "remove", state)
        publication_fixture = {**initial, "namespace": str(uuid.uuid4()), "checkpoint": None,
            "profiles": [{"name": name, "profile": str(uuid.uuid4()), "store": str(uuid.uuid4())} for name in ["A", "B"]]}
        prepared = host("publication-failure-prepare", "seed", publication_fixture)
        publication_fixture["checkpoint"] = prepared["checkpoint"]
        host("publication-failure", "publication-failure", publication_fixture)
        # Each is an independent, registered finite cutpoint, not a retry of a failure.
        cutpoints = [("creation-intent", "seed"), ("persistent-factory", "seed"), ("assignment", "seed"), ("construction", "seed"),
                     ("publication", "seed"), ("clear-request", "clear"), ("clear-callback", "clear"),
                     ("retire", "remove"), ("remove-request", "remove"), ("remove-callback", "remove"), ("enumeration", "verify")]
        for index, (point, action) in enumerate(cutpoints):
            fixture = {**initial, "namespace": str(uuid.uuid4()), "checkpoint": None, "profiles": [{"name": name, "profile": str(uuid.uuid4()), "store": str(uuid.uuid4())} for name in ["A", "B"]]}
            label = "cut-%02d-%s" % (index, point)
            run.save(label + "-fixture.json", fixture)
            if action != "seed":
                base = host(label + "-prepare", "seed", fixture)
                fixture["checkpoint"] = base["checkpoint"]
            interrupted = host(label, action, fixture, cutpoint=point, expected_kill=True)
            fixture["checkpoint"] = interrupted["checkpoint"]
            host(label + "-reconcile", "reconcile-uncertain", fixture)
    except RuntimeError as error:
        run.save("blocker.json", {"reason": str(error), "automaticCleanup": False})
    finally:
        server.shutdown(); server.server_close()
        run.save("http-requests.json", requests)
        native_cases = [dict(case, attempt=x["label"]) for x in attempts for case in x.get("result", {}).get("cases", [])]
        native_cases.extend(locals().get("http_results", []))
        run.save("case-results.json", native_cases)
        run.save("attempts.json", attempts)
        qualification = platform.mac_ver()[0].split(".")[0] == "26"
        summary = {"hostMacOS": platform.mac_ver()[0], "nativeQualification": "BLOCKED",
                   "reason": "Actual macOS26 required; host discovery cannot substitute" if not qualification else "See exact case results",
                   "discoveryAttempts": len(attempts), "discoveryPassedObservations": sum(c["status"] == "PASS_NATIVE" for c in native_cases), "discoveryFailedObservations": sum(c["status"] == "FAIL" for c in native_cases),
                   "essentialDiscoveryFailure": any(a["status"] == "FAIL" for a in attempts), "buildRecord": str(build_record), "diagnosticBuildRecord": str(diagnostic_record), "cleanup": "See explicit remove result; incomplete/uncertain resources preserved",
                   "phase": phase, "priorPrivateGate": "Historical 2-second FAIL preserved; current 15-second cases above" if phase == "private-only" else "FAIL / not waived" if phase == "persistent-lifecycle" else "See current full-suite private results; historical failures preserved",
                   "limitation": "Per-case results require WKS/release review; one host or completed subset cannot auto-pass the full native matrix"}
        run.save("result.json", summary); print(json.dumps({"attempt": str(run.out), **summary}))
        if summary["essentialDiscoveryFailure"]: raise SystemExit(1)
