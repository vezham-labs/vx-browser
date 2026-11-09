#!/usr/bin/env python3
"""Build the pinned provider probe and record bounded native fixture observations."""
import argparse
from datetime import datetime, timezone
import hashlib
import json
from pathlib import Path
import subprocess
import tempfile

ROOT = Path(__file__).resolve().parents[2]
SOURCES = Path(__file__).resolve().parent
EVIDENCE = ROOT / "docs/architecture/phase-5/reports/WS-F3/evidence"
PIN = "355d4db92d3404e71faa8088d071a71d767807f4"
ARTIFACTS = {
    "libsqlite3.a": "ac0fed4b3c47b6259a87504b318fd4546018c880b0d60331a47e92c3f7a9856c",
    "sqlite3.h": "e36eb6ed4de77e56a633866a8f84ed339785662d0cf79cf099f420b638bf28ec",
}
CASES = {
    "valid": "Authenticate expected identity and become read-only ready",
    "wrong-key": "Reject incorrect 32-byte key with source unchanged",
    "foreign": "Reject foreign profile with source unchanged",
    "wrong-store": "Reject mismatched store identity",
    "wrong-schema": "Reject mismatched schema identity",
    "wrong-suite": "Reject mismatched suite identity",
    "wrong-version": "Reject mismatched key version",
    "corrupt": "Reject corrupted encrypted page",
    "invalid-header": "Reject truncated encrypted file",
    "missing": "Refuse missing file without recreation",
    "missing-key": "Refuse missing scoped key before open",
    "sidecar": "Refuse WAL sidecar before open",
}


def now():
    return datetime.now(timezone.utc).isoformat()


def digest(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--provider", type=Path, required=True)
    args = parser.parse_args()
    run_id = "provider-" + datetime.now(timezone.utc).strftime("%Y%m%dT%H%M%S%fZ")
    output = EVIDENCE / run_id
    output.mkdir(parents=True)
    commands = []

    def save(name, value):
        (output / name).write_text(json.dumps(value, indent=2) + "\n")

    def run(label, command, timeout=60):
        started = now()
        try:
            result = subprocess.run(command, capture_output=True, timeout=timeout)
        except subprocess.TimeoutExpired as exc:
            result = subprocess.CompletedProcess(command, 124, exc.stdout or b"", exc.stderr or b"")
        (output / f"{label}.stdout").write_bytes(result.stdout)
        (output / f"{label}.stderr").write_bytes(result.stderr)
        commands.append({"label": label, "argv": list(map(str, command)), "startedUTC": started,
                         "exit": result.returncode})
        save("commands.json", commands)
        return result

    with tempfile.TemporaryDirectory(prefix="vx-wsf3-provider-", dir="/private/tmp") as temporary:
        work = Path(temporary)
        provider = work / "provider"
        provider.mkdir()
        for name, expected in ARTIFACTS.items():
            contents = (args.provider / name).read_bytes()
            if hashlib.sha256(contents).hexdigest() != expected:
                raise SystemExit(f"Provider input hash mismatch: {name}")
            (provider / name).write_bytes(contents)
        sources = [SOURCES / "descriptor_vfs.c", SOURCES / "native_probe.c"]
        save("inputs.json", {"providerPin": PIN, "providerArtifacts": ARTIFACTS,
                            "sources": {p.name: digest(p) for p in [*sources, SOURCES / "descriptor_vfs.h", Path(__file__)]}})
        binary = work / "wsf3-native-probe"
        build = run("build", ["xcrun", "clang", "-std=c17", "-Wall", "-Wextra", "-Werror",
                              "-DSQLITE_HAS_CODEC", "-I", provider, *sources, provider / "libsqlite3.a",
                              "-framework", "Security", "-framework", "CoreFoundation", "-o", binary])
        if build.returncode:
            save("result.json", {"runID": run_id, "status": "FAIL", "stage": "build", "observations": []})
            print(build.stderr.decode(errors="replace"))
            return 1
        signature = run("signature", ["codesign", "-dvv", "--entitlements", ":-", binary])
        environment = {
            "os": run("os", ["sw_vers"]).stdout.decode().strip(),
            "arch": run("arch", ["uname", "-m"]).stdout.decode().strip(),
            "swift": run("swift", ["xcrun", "swift", "--version"]).stdout.decode().strip(),
            "sdk": run("sdk", ["xcrun", "--show-sdk-version"]).stdout.decode().strip(),
            "binarySHA256": digest(binary),
            "signature": signature.stderr.decode().strip(),
            "entitlements": "Standalone CLI; no application/Keychain entitlement claim",
            "provider": "SQLCipher 4.20.0 Community / CommonCrypto / SQLite 3.54.1",
        }
        save("environment.json", environment)
        observations = []
        for attempt in (1, 2):
            for case, expected in CASES.items():
                label = f"{attempt}-{case}"
                fixture = work / label
                fixture.mkdir(mode=0o700)
                started = now()
                result = run(label, [binary, fixture, case], timeout=12)
                events = [json.loads(line) for line in result.stdout.splitlines()]
                passed = (result.returncode == 0 and bool(events) and
                          events[-1] == {"event": "result", "case": case, "pass": True})
                observations.append({"runID": run_id, "testID": case, "attempt": attempt,
                                     "startedUTC": started, "testProfile": label, "expected": expected,
                                     "operation": "Pinned provider synthetic fixture / native reopen",
                                     "actual": events, "exit": result.returncode, "environment": "environment.json",
                                     "artifacts": [f"{label}.stdout", f"{label}.stderr"],
                                     "status": "PASS_NATIVE" if passed else "FAIL"})
                save("observations.json", observations)
                if not passed:
                    print(f"{label}: FAIL")
        failed = sum(row["status"] == "FAIL" for row in observations)
        save("result.json", {"runID": run_id, "status": "FAIL" if failed else "PASS_NATIVE",
                             "PASS_NATIVE": len(observations) - failed, "FAIL": failed})
        print(f"{run_id}: {len(observations) - failed} PASS_NATIVE, {failed} FAIL")
        return bool(failed)


if __name__ == "__main__":
    raise SystemExit(main())
