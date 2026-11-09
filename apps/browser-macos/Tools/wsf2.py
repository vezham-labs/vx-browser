#!/usr/bin/env python3
"""WS-F2 entrypoint; no SQLCipher/provider initialization is permitted."""
import argparse
import json
import platform
import re
import sys
sys.dont_write_bytecode = True
from wsf1 import Run, ROOT, PACKAGE, digest

def main():
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument("action", choices=["build", "contracts", "security-native", "webkit-native"])
    p.add_argument("--evidence", required=True, type=__import__('pathlib').Path)
    p.add_argument("--build-record", type=__import__('pathlib').Path)
    a = p.parse_args(); r = Run(a.evidence, "f2-" + a.action)
    if a.action == "build": r.build(); return
    if a.action == "contracts":
        result = r.run("swift-test", ["swift", "test", "--package-path", str(PACKAGE), "--scratch-path", str(r.work / "build"), "--cache-path", str(r.work / "cache"), "--config-path", str(r.work / "config"), "--security-path", str(r.work / "security"), "--disable-keychain", "--disable-netrc", "--manifest-cache", "local", "--jobs", "2", "--disable-xctest", "--enable-swift-testing", "--no-parallel"])
        text = (result.stdout + result.stderr).decode('utf8', 'replace')
        passed = re.findall(r'Test "((?:F1|F2)-[^"]+)"(?: with \d+ test cases)? passed', text)
        expected = re.search(r'Test run with (\d+) tests.*?passed', text)
        ok = result.returncode == 0 and expected is not None and len(passed) == int(expected[1]) and all(digest(ROOT / k) == v for k,v in r.sources.items())
        r.save("result.json", {"status":"PASS_CONTRACT" if ok else "FAIL", "tests":passed,"count":len(passed),"nativeKeychainWebKitExecution":False,"host":platform.mac_ver()[0]})
        print(json.dumps({"attempt":str(r.out),"status":"PASS_CONTRACT" if ok else "FAIL","count":len(passed)}))
        if not ok: print("\n".join(x for x in text.splitlines() if "error:" in x or "issue" in x or "failed" in x)[-7000:]); raise SystemExit(1)
    else:
        if not a.build_record: p.error("Exact build record required")
        from wsf2_native import execute
        execute(r, a.build_record, a.action)
if __name__ == '__main__': main()
