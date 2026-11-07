#!/bin/bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
TEMP_BUILD="$(mktemp -d "${TMPDIR:-/private/tmp}/wkwebview-download-panel.XXXXXX")"
SERVER_PID=""
APP_WAIT_PID=""
cleanup() {
  if [[ -n "$APP_WAIT_PID" ]] && kill -0 "$APP_WAIT_PID" 2>/dev/null; then
    kill "$APP_WAIT_PID" 2>/dev/null || true
    wait "$APP_WAIT_PID" 2>/dev/null || true
  fi
  if [[ -n "$SERVER_PID" ]]; then
    kill "$SERVER_PID" 2>/dev/null || true
    wait "$SERVER_PID" 2>/dev/null || true
  fi
  rm -rf "$TEMP_BUILD"
}
trap cleanup EXIT

BUNDLE_ID="internal.vezham.WKPrototype.DownloadPanel.$(date +%s).$$"
RUN_ID="$(date -u +%Y%m%dT%H%M%SZ)-$$"
BUILD_DIR="$TEMP_BUILD/build"
DOWNLOAD_DIR="$TEMP_BUILD/download-destination"
mkdir -p "$DOWNLOAD_DIR"

WK_BUILD_DIR="$BUILD_DIR" WK_BUNDLE_ID="$BUNDLE_ID" bash "$ROOT/build.sh"
python3 "$ROOT/Fixtures/server.py" >"$TEMP_BUILD/fixture.log" 2>&1 &
SERVER_PID=$!
for _ in $(seq 1 50); do
  if ! kill -0 "$SERVER_PID" 2>/dev/null; then
    echo "Loopback fixture server failed to start; see $TEMP_BUILD/fixture.log" >&2
    exit 1
  fi
  if curl --silent --fail --output /dev/null 'http://127.0.0.1:18765/transfer-download'; then break; fi
  sleep 0.1
done
if ! curl --silent --fail --output /dev/null 'http://127.0.0.1:18765/transfer-download'; then
  echo "Loopback fixture server did not become ready; see $TEMP_BUILD/fixture.log" >&2
  exit 1
fi

APP_BUNDLE="$BUILD_DIR/VezhamWKPrototype.app"
echo "Opening isolated download-panel app: $BUNDLE_ID"
echo "Synthetic save destination: $DOWNLOAD_DIR"
open -n -W -a "$APP_BUNDLE" --args --test-download-panel --test-download-directory "$DOWNLOAD_DIR" --test-download-panel-timeout-seconds 210 >"$TEMP_BUILD/open.log" 2>&1 &
APP_WAIT_PID=$!

RESULTS_DIR="$HOME/Library/Containers/$BUNDLE_ID/Data/Library/Application Support/WKPrototype"
RESULT="$RESULTS_DIR/download-panel-results-$RUN_ID.json"
FOUND_FILE=""
for _ in $(seq 1 360); do
  FOUND_FILE="$(find "$DOWNLOAD_DIR" -maxdepth 1 -type f -print -quit)"
  if [[ -n "$FOUND_FILE" ]]; then
    if python3 -c 'import pathlib,sys; p=pathlib.Path(sys.argv[1]); expected=b"Vezham synthetic download fixture\n"; assert p.read_bytes()==expected' "$FOUND_FILE" 2>/dev/null; then
      break
    fi
  fi
  if ! kill -0 "$APP_WAIT_PID" 2>/dev/null; then break; fi
  sleep 0.5
done

python3 - "$DOWNLOAD_DIR" "$FOUND_FILE" "$RESULT" <<'PY'
import json
import pathlib
import sys

directory = pathlib.Path(sys.argv[1]).resolve()
candidate = pathlib.Path(sys.argv[2]).resolve() if sys.argv[2] else None
expected = b"Vezham synthetic download fixture\n"
exists = candidate is not None and candidate.is_file()
inside = exists and candidate.parent == directory
safe_name = exists and candidate.name not in {".", ".."} and "/" not in candidate.name
payload_matches = exists and candidate.read_bytes() == expected
tests = [
    {"label": "native save panel selected a destination inside the isolated folder", "passed": inside},
    {"label": "download filename remained a safe basename", "passed": safe_name},
    {"label": "downloaded bytes match the loopback fixture", "passed": payload_matches},
]
failures = [test["label"] for test in tests if not test["passed"]]
result = {
    "mode": "download-panel",
    "status": "passed" if not failures else "failed",
    "filename": candidate.name if exists else None,
    "byteCount": candidate.stat().st_size if exists else 0,
    "tests": tests,
    "failureCount": len(failures),
    "failures": failures,
}
output = pathlib.Path(sys.argv[3])
output.parent.mkdir(parents=True, exist_ok=True)
output.write_text(json.dumps(result, indent=2, sort_keys=True) + "\n")
print("Native download save-panel check:", result["status"], "(" + str(len(tests) - len(failures)) + "/" + str(len(tests)) + " checks)")
print("Results:", output)
if failures:
    raise SystemExit(1)
PY

# Keep the app bundle alive for desktop inspection until it is closed. The app
# also exits on its own after 210 seconds if the desktop controller is absent.
wait "$APP_WAIT_PID"
APP_WAIT_PID=""
