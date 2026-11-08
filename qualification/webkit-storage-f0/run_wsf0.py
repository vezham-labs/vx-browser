"""Run only the isolated Swift fake suite; never launch native engines/providers."""
import argparse
import datetime
import hashlib
import json
import os
from pathlib import Path
import re
import subprocess
import tempfile

ROOT = Path(__file__).resolve().parents[2]
SOURCE = Path(__file__).resolve().parent

def digest(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--evidence", type=Path, required=True)
    args = parser.parse_args()
    evidence = args.evidence.resolve()
    if ROOT / "docs/architecture/phase-5/evidence" not in evidence.parents or not (evidence / "baseline.json").is_file():
        raise SystemExit("A registered evidence directory is required")
    attempt = evidence / ("attempt-" + datetime.datetime.now(datetime.timezone.utc).strftime("%H%M%S%f"))
    attempt.mkdir()
    work = Path(tempfile.mkdtemp(prefix="vx-wsf0-", dir="/private/tmp"))
    os.chmod(work, 0o700)
    commands = []
    sources = sorted(SOURCE.rglob("*.swift"))
    inventory = [{"path": str(p.relative_to(ROOT)), "sha256": digest(p)} for p in sources]
    (attempt / "source-hashes.json").write_text(json.dumps(inventory, indent=2) + "\n")
    # Only PackageDescription/Testing/local targets and Foundation UUID fixture helpers allowed.
    allowed_imports = {"Foundation", "PackageDescription", "Testing", "BrowserDomain", "BrowserPorts", "BrowserCore", "BrowserPersistence", "WSF0Fakes"}
    imports = sorted({name for p in sources for name in re.findall(r"^import (\w+)", p.read_text(), re.M)})
    if set(imports) - allowed_imports:
        raise SystemExit("Forbidden import before build")
    if re.search(r"\b(import WebKit|import Security|import AppKit|import SQLite3|sqlite3_|SecItem|WKWebsiteDataStore|WKWebView|FileManager|URLSession|Process\()", "\n".join(p.read_text() for p in sources)):
        raise SystemExit("Forbidden native/database/filesystem execution surface")
    env = {**os.environ, "CLANG_MODULE_CACHE_PATH": str(work / "clang-cache"), "SWIFTPM_MODULECACHE_OVERRIDE": str(work / "swift-cache")}
    def run(label, argv, timeout=240):
        started = datetime.datetime.now(datetime.timezone.utc).isoformat()
        result = subprocess.run(argv, cwd=ROOT, env=env, capture_output=True, timeout=timeout)
        (attempt / (label + ".stdout")).write_bytes(result.stdout)
        (attempt / (label + ".stderr")).write_bytes(result.stderr)
        commands.append({"label": label, "argv": argv, "cwd": str(ROOT), "started_utc": started, "returncode": result.returncode})
        (attempt / "commands.json").write_text(json.dumps(commands, indent=2) + "\n")
        return result
    version = run("swift-version", ["swift", "--version"])
    argv = ["swift", "test", "--package-path", str(SOURCE), "--scratch-path", str(work / "build"),
            "--cache-path", str(work / "cache"), "--config-path", str(work / "config"), "--security-path", str(work / "security"),
            "--disable-keychain", "--disable-netrc", "--manifest-cache", "local", "--jobs", "2",
            "--disable-xctest", "--enable-swift-testing", "--no-parallel"]
    result = run("swift-test", argv)
    output = (result.stdout + result.stderr).decode("utf-8", "replace")
    passed = re.findall(r'Test "(F0-[^"]+)" passed', output)
    failed = re.findall(r'Test "(F0-[^"]+)" failed', output)
    summary = re.search(r"Test run with (\d+) tests.*?passed", output)
    expected = re.findall(r'@Test\("(F0-[^"]+)"', "\n".join(p.read_text() for p in sources))
    suite_ok = result.returncode == 0 and summary is not None and int(summary[1]) == len(expected) and len(passed) == len(expected) and not failed
    binaries = sorted(p for p in (work / "build").rglob("*") if p.is_file() and (p.name.endswith(".dylib") or (p.parent.name == "MacOS" and p.parent.parent.parent.suffix == ".xctest")))
    linkage = []
    if not binaries: suite_ok = False
    for index, binary in enumerate(binaries):
        inspected = run("linkage-" + str(index), ["otool", "-L", str(binary)], timeout=30)
        text = inspected.stdout.decode("utf-8", "replace")
        forbidden = any(token in text for token in ["WebKit.framework", "libsqlite3", "sqlcipher"])
        linkage.append({"binary": str(binary), "sha256": digest(binary), "returncode": inspected.returncode, "forbidden_provider_or_engine": forbidden})
        if inspected.returncode or forbidden: suite_ok = False
    unchanged = all(digest(ROOT / item["path"]) == item["sha256"] for item in inventory)
    if not unchanged: suite_ok = False
    report = {"sources_unchanged_during_attempt": unchanged, "status": "PASS_FAKE_ONLY" if suite_ok else "FAIL", "attempt": str(attempt), "work_directory": str(work),
              "test_command": argv, "expected_test_count": len(expected), "passed_test_count": len(passed), "failed_test_count": len(failed),
              "skipped_test_count": 0, "uncompleted_test_count": len(expected) - len(passed) - len(failed), "passed_tests": passed, "failed_tests": failed, "all_source_tests_executed": len(passed) == len(expected),
              "imports": imports, "linkage": linkage, "WebKit_calls": 0, "SQLCipher_calls": 0, "browser_database_opens": 0,
              "Keychain_API_calls": 0, "website_storage_filesystem_backends": 0,
              "limitation": "Fake Swift tests on recorded host only; no native engine/provider/filesystem privacy or macOS26 runtime qualification"}
    (attempt / "result.json").write_text(json.dumps(report, indent=2) + "\n")
    print(json.dumps({"attempt": str(attempt), "status": report["status"], "passed": len(passed), "failed": len(failed), "expected": len(expected), "returncode": result.returncode}))
    if not suite_ok:
        print(output[-15000:])
        raise SystemExit(1)

if __name__ == "__main__":
    main()
