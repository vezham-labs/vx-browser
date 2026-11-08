"""Build Phase 1 tools, run only fake-provider tests, inspect an unexecuted linked image."""
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
PIN = "355d4db92d3404e71faa8088d071a71d767807f4"
ARCHIVE = Path("/private/tmp/vx-m1-provider-fixtures-20261108T113403Z/provider-build-1/libsqlite3.a")
ARCHIVE_HASH = "ac0fed4b3c47b6259a87504b318fd4546018c880b0d60331a47e92c3f7a9856c"
HEADER_HASH = "e36eb6ed4de77e56a633866a8f84ed339785662d0cf79cf099f420b638bf28ec"

def digest(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--evidence", type=Path, required=True)
    args = parser.parse_args()
    evidence = args.evidence.resolve()
    expected = ROOT / "docs/architecture/phase-5/evidence"
    if expected not in evidence.parents or not (evidence / "baseline.json").is_file():
        raise SystemExit("A registered current evidence directory is required")
    attempt = evidence / ("attempt-" + datetime.datetime.now(datetime.timezone.utc).strftime("%H%M%S%f"))
    attempt.mkdir()
    work = Path(tempfile.mkdtemp(prefix="vx-m1-phase1-", dir="/private/tmp"))
    os.chmod(work, 0o700)
    records = []
    def run(label, argv, timeout=40):
        result = subprocess.run(argv, cwd=work, capture_output=True, timeout=timeout)
        (attempt / (label + ".stdout")).write_bytes(result.stdout)
        (attempt / (label + ".stderr")).write_bytes(result.stderr)
        record = {"label": label, "argv": list(map(str, argv)), "cwd": str(work),
                  "returncode": result.returncode}
        records.append(record)
        (attempt / "commands.json").write_text(json.dumps(records, indent=2) + "\n")
        if result.returncode:
            raise RuntimeError(f"{label} failed with exit {result.returncode}; outputs retained")
        return result.stdout.decode("utf-8", "replace")
    try:
        if digest(ARCHIVE) != ARCHIVE_HASH or digest(ARCHIVE.parent / "sqlite3.h") != HEADER_HASH:
            raise RuntimeError("Pinned archive/header hash mismatch")
        clang = subprocess.check_output(["xcrun", "--find", "clang"], text=True).strip()
        sdk = subprocess.check_output(["xcrun", "--sdk", "macosx", "--show-sdk-path"], text=True).strip()
        version = run("compiler-version", [clang, "--version"])
        if "clang-2100.4.1.1" not in version or not sdk.endswith("/MacOSX27.2.sdk"):
            raise RuntimeError("Frozen compiler/SDK mismatch")
        flags = [clang, "-std=c11", "-O2", "-g0", "-Wall", "-Wextra", "-Werror",
                 "-target", "arm64-apple-macosx26.0", "-isysroot", sdk,
                 "-D__STDC_WANT_LIB_EXT1__=1", "-I" + str(SOURCE)]
        fake = work / "fake-worker"
        supervisor = work / "phase1-supervisor"
        linked = work / "sqlcipher-linked-worker"
        run("build-fake-worker", flags + [str(SOURCE / n) for n in ["worker.c", "protocol.c"]] + ["-o", str(fake)])
        run("build-supervisor", flags + [str(SOURCE / n) for n in ["supervisor_tests.c", "supervisor.c", "protocol.c"]] +
            ["-framework", "Security", "-o", str(supervisor)])
        link_map = attempt / "worker-link.map"
        run("build-linked-worker", flags + ["-DSQLITE_HAS_CODEC", "-I" + str(ARCHIVE.parent)] +
            [str(SOURCE / n) for n in ["worker.c", "protocol.c", "link_identity.c"]] +
            [str(ARCHIVE), "-framework", "Security", "-framework", "CoreFoundation",
             "-Wl,-map," + str(link_map), "-o", str(linked)])
        nm = run("linked-symbols", ["/usr/bin/nm", "-g", str(linked)])
        libraries = run("linked-dependencies", ["xcrun", "otool", "-L", str(linked)])
        run("linked-load-commands", ["xcrun", "otool", "-l", str(linked)])
        run("linked-architecture", ["/usr/bin/lipo", "-info", str(linked)])
        strings = run("linked-strings", ["/usr/bin/strings", str(linked)])
        mapping = link_map.read_text()
        archive_entry = re.search(r"^\[\s*(\d+)\]\s+(.+" + re.escape(str(ARCHIVE)) + r"\([^\n]+\))$", mapping, re.M)
        if not archive_entry:
            # Apple's map format can print the path without any leading directory text.
            archive_entry = re.search(r"^\[\s*(\d+)\]\s+(" + re.escape(str(ARCHIVE)) + r"\([^\n]+\))$", mapping, re.M)
        if not archive_entry:
            raise RuntimeError("Link map does not identify the pinned archive member")
        member = archive_entry.group(1)
        symbols = ["sqlite3_key", "sqlite3_open_v2", "sqlite3_close", "sqlite3_libversion",
                   "sqlite3_sourceid", "sqlcipher_cc_setup", "sqlcipher_extra_init",
                   "sqlite3_backup_init", "sqlite3_wal_checkpoint_v2"]
        resolutions = {}
        for symbol in symbols:
            match = re.search(r"^0x[0-9A-Fa-f]+\s+0x[0-9A-Fa-f]+\s+\[\s*" + member +
                              r"\]\s+_" + re.escape(symbol) + r"$", mapping, re.M)
            resolutions[symbol] = bool(match) and bool(re.search(r"\bT _" + symbol + r"$", nm, re.M))
        if not all(resolutions.values()):
            raise RuntimeError("Expected provider symbols are not resolved to the pinned archive")
        if "libsqlite3" in libraries.lower():
            raise RuntimeError("Unexpected direct dynamic SQLite dependency")
        source_id = re.search(r'#define SQLITE_SOURCE_ID\s+"([^"]+)"',
                              (ARCHIVE.parent / "sqlite3.h").read_text()).group(1)
        if "4.20.0" not in strings or "3.54.1" not in strings or source_id not in strings:
            raise RuntimeError("Missing binary-level provider/SQLite identity strings")
        identity = {"status": "PASS", "source_pin": PIN, "archive": str(ARCHIVE),
                    "archive_sha256": digest(ARCHIVE), "header_sha256": HEADER_HASH,
                    "archive_member": archive_entry.group(2), "symbols": resolutions,
                    "binary": str(linked), "binary_sha256": digest(linked),
                    "sqlcipher_binary_version_string": "4.20.0", "sqlite_binary_version_string": "3.54.1",
                    "sqlite_source_id": source_id, "direct_dynamic_sqlite": False,
                    "linked_image_executed": False, "provider_functions_called": False,
                    "authenticity_limit": "Vendor signed source correspondence passed previously; separate tag unknown_key remains historical. This is binary linkage evidence only."}
        (attempt / "library-identity.json").write_text(json.dumps(identity, indent=2) + "\n")
        output = run("fake-provider-tests", [str(supervisor), str(fake)])
        rows = [json.loads(line) for line in output.splitlines() if line.startswith("{")]
        summary = next(row for row in rows if row.get("summary"))
        if summary["failed"]:
            raise RuntimeError("Fake-provider conformance failures")
        (attempt / "test-results.json").write_text(json.dumps(rows, indent=2) + "\n")
        result = {"status": "PASS", "attempt": str(attempt), "work_directory": str(work),
                  "tests": summary, "linked_image_executed": False,
                  "provider_databases_opened": 0, "PQR_runtime_cases_executed": 0,
                  "worker_and_supervisor_sources": {p.name: digest(p) for p in SOURCE.glob("*.[ch]")}}
        (attempt / "result.json").write_text(json.dumps(result, indent=2) + "\n")
        print(json.dumps(result, indent=2))
    except Exception as error:
        (attempt / "failure.json").write_text(json.dumps({"status": "FAIL", "reason": str(error)}, indent=2) + "\n")
        raise

if __name__ == "__main__":
    main()
