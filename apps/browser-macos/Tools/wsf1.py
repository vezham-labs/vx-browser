#!/usr/bin/env python3
"""Bounded WS-F1 build/qualification entrypoint. Never runs SQLCipher or Keychain."""
import argparse
import datetime
import hashlib
import json
import os
from pathlib import Path
import platform
import re
import subprocess
import sys
import tempfile
sys.dont_write_bytecode = True

ROOT = Path(__file__).resolve().parents[3]
PACKAGE = ROOT / "apps/browser-macos/StorageRuntime"

def digest(p):
    return hashlib.sha256(p.read_bytes()).hexdigest()

class Run:
    def __init__(self, evidence, action):
        self.evidence = evidence.resolve()
        if ROOT / "docs/architecture/phase-5/evidence" not in self.evidence.parents or not (self.evidence / "baseline.json").is_file():
            raise SystemExit("Registered evidence directory required")
        self.out = self.evidence / (action + "-" + datetime.datetime.now(datetime.timezone.utc).strftime("%H%M%S%f"))
        self.out.mkdir()
        self.work = Path(tempfile.mkdtemp(prefix="vx-wsf1-", dir="/private/tmp"))
        os.chmod(self.work, 0o700)
        self.env = {**os.environ, "CLANG_MODULE_CACHE_PATH": str(self.work / "clang-cache"), "SWIFTPM_MODULECACHE_OVERRIDE": str(self.work / "swift-cache")}
        self.commands = []
        self.sources = {str(p.relative_to(ROOT)): digest(p) for folder in [PACKAGE, ROOT / "qualification/webkit-storage-f0", ROOT / "apps/browser-macos/Sources"] for p in folder.rglob("*.swift") if ".build" not in p.parts}
        self.save("sources.json", self.sources)
    def save(self, name, obj):
        (self.out / name).write_text(json.dumps(obj, indent=2) + "\n")
    def run(self, label, argv, timeout=300):
        started = datetime.datetime.now(datetime.timezone.utc).isoformat()
        try:
            p = subprocess.run(argv, cwd=ROOT, env=self.env, capture_output=True, timeout=timeout)
        except subprocess.TimeoutExpired as ex:
            p = subprocess.CompletedProcess(argv, 124, ex.stdout or b"", ex.stderr or b"")
        (self.out / (label + ".stdout")).write_bytes(p.stdout)
        (self.out / (label + ".stderr")).write_bytes(p.stderr)
        self.commands.append({"label": label, "argv": argv, "startedUTC": started, "returncode": p.returncode})
        self.save("commands.json", self.commands)
        return p
    def models(self):
        p = self.run("swift-test", ["swift", "test", "--package-path", str(PACKAGE), "--scratch-path", str(self.work / "build"), "--cache-path", str(self.work / "cache"), "--config-path", str(self.work / "config"), "--security-path", str(self.work / "security"), "--disable-keychain", "--disable-netrc", "--manifest-cache", "local", "--jobs", "2", "--disable-xctest", "--enable-swift-testing", "--no-parallel"])
        output = (p.stdout + p.stderr).decode("utf8", "replace")
        passed = re.findall(r'Test "((?:F1|F2)-[^"]+)"(?: with \d+ test cases)? passed', output)
        summary = re.search(r'Test run with (\d+) tests.*?passed', output)
        unchanged = all(digest(ROOT / k) == v for k, v in self.sources.items())
        ok = p.returncode == 0 and summary is not None and int(summary[1]) == len(passed) and unchanged
        result = {"status": "PASS_CONTRACT" if ok else "FAIL", "passed": passed, "count": len(passed),
                  "contractCount": sum("-FAKE-" not in x for x in passed), "additionalFakeCount": sum("-FAKE-" in x for x in passed),
                  "sourceUnchanged": unchanged, "macOS": platform.mac_ver()[0], "nativeExecution": False, "returncode": p.returncode}
        self.save("result.json", result)
        print(json.dumps({"attempt": str(self.out), **result}))
        if not ok:
            print(output[-14000:]); raise SystemExit(1)
    def build(self, original=False):
        bundle = "internal.vx.M1Validation.run20261108T094414Z" if original else "internal.vezham.browser.wsf1.qualification"
        argv = ["xcodebuild", "-project", str(ROOT / "apps/browser-macos/VezhamBrowser.xcodeproj"), "-scheme", "VezhamBrowser", "-configuration", "Debug", "-destination", "platform=macOS,arch=" + platform.machine(), "-derivedDataPath", str(self.work / "DerivedData"), "-clonedSourcePackagesDirPath", str(self.work / "packages"), "-skipPackageUpdates", "build", "PRODUCT_BUNDLE_IDENTIFIER=" + bundle, "ARCHS=" + platform.machine(), "ONLY_ACTIVE_ARCH=YES", "MACOSX_DEPLOYMENT_TARGET=26.0"]
        p = self.run("xcodebuild", argv)
        app = self.work / "DerivedData/Build/Products/Debug/VezhamBrowser.app"
        result = {"status": "PASS_CONTRACT" if p.returncode == 0 else "FAIL", "bundle": str(app), "bundleID": bundle, "returncode": p.returncode, "runtimeExecuted": False}
        if p.returncode == 0:
            for label, command in [("signature", ["codesign", "--verify", "--strict", "--verbose=2", str(app)]), ("entitlements", ["codesign", "-d", "--entitlements", ":-", str(app)]), ("linkage", ["otool", "-L", str(app / "Contents/MacOS/VezhamBrowser")]), ("minimum-os", ["otool", "-l", str(app / "Contents/MacOS/VezhamBrowser")])]:
                checked = self.run(label, command)
                if checked.returncode: result["status"] = "FAIL"
            result["binarySHA256"] = digest(app / "Contents/MacOS/VezhamBrowser")
        self.save("result.json", result); print(json.dumps({"attempt": str(self.out), **result}))
        if result["status"] == "FAIL":
            print("\n".join(line for line in (p.stdout + p.stderr).decode("utf8", "replace").splitlines() if "error:" in line or "warning:" in line)[-6000:]); raise SystemExit(1)

def main():
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument("action", choices=["models", "build", "diagnostic-build", "native"])
    p.add_argument("--build-record", type=Path)
    p.add_argument("--diagnostic-record", type=Path)
    p.add_argument("--resume-record", type=Path)
    p.add_argument("--phase", choices=["all", "persistent-lifecycle", "private-only"], default="all")
    p.add_argument("--evidence", type=Path, required=True)
    a = p.parse_args(); r = Run(a.evidence, a.action)
    if a.action == "models": r.models()
    elif a.action == "native":
        if not a.build_record or not a.diagnostic_record: p.error("Exact build records required")
        from wsf1_native import execute
        execute(r, a.build_record, a.diagnostic_record, a.resume_record, a.phase)
    else: r.build(a.action == "diagnostic-build")

if __name__ == "__main__":
    main()
