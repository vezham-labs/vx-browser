#!/bin/bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
TEMP_BUILD="$(mktemp -d "${TMPDIR:-/private/tmp}/wkwebview-recovery.XXXXXX")"
SERVER_PID=""
APP_PID=""
READY=""
cleanup() {
  if [[ -n "$APP_PID" ]] && kill -0 "$APP_PID" 2>/dev/null; then
    kill "$APP_PID" 2>/dev/null || true
    wait "$APP_PID" 2>/dev/null || true
  fi
  if [[ -n "$SERVER_PID" ]]; then
    kill "$SERVER_PID" 2>/dev/null || true
    wait "$SERVER_PID" 2>/dev/null || true
  fi
  if [[ -n "$READY" ]]; then
    rm -f "$READY"
  fi
  rm -rf "$TEMP_BUILD"
}
trap cleanup EXIT
BUNDLE_ID="internal.vezham.WKPrototype.Recovery.$(date +%s).$$"
RUN_ID="$(date -u +%Y%m%dT%H%M%SZ)-$$"
BUILD_DIR="$TEMP_BUILD/build"
RESULTS_DIR="$HOME/Library/Containers/$BUNDLE_ID/Data/Library/Application Support/WKPrototype"
READY="$RESULTS_DIR/crash-ready-$RUN_ID.json"
RESULT="$RESULTS_DIR/crash-recovery-results-$RUN_ID.json"
BASELINE_WEB_CONTENT_PIDS="$(ps -axo pid,comm | awk '$2 ~ /WebContent/ {print $1}')"

WK_BUILD_DIR="$BUILD_DIR" WK_BUNDLE_ID="$BUNDLE_ID" bash "$ROOT/build.sh"
python3 "$ROOT/Fixtures/server.py" >"$TEMP_BUILD/fixture.log" 2>&1 &
SERVER_PID=$!
for _ in $(seq 1 50); do
  if ! kill -0 "$SERVER_PID" 2>/dev/null; then
    echo "Loopback fixture server failed to start; see $TEMP_BUILD/fixture.log" >&2
    exit 1
  fi
  if curl --silent --fail --output /dev/null 'http://127.0.0.1:18765/crash-fixture'; then break; fi
  sleep 0.1
done
if ! curl --silent --fail --output /dev/null 'http://127.0.0.1:18765/crash-fixture'; then
  echo "Loopback fixture server did not become ready; see $TEMP_BUILD/fixture.log" >&2
  exit 1
fi

EXECUTABLE="$BUILD_DIR/VezhamWKPrototype.app/Contents/MacOS/VezhamWKPrototype"
"$EXECUTABLE" --test-crash-recovery --test-run-id "$RUN_ID" >"$TEMP_BUILD/app.log" 2>&1 &
APP_PID=$!
for _ in $(seq 1 120); do
  if [[ -f "$READY" ]]; then break; fi
  if ! kill -0 "$APP_PID" 2>/dev/null; then
    cat "$TEMP_BUILD/app.log" >&2
    echo "Crash recovery app exited before the fixture loaded" >&2
    exit 1
  fi
  sleep 0.25
done
if [[ ! -f "$READY" ]]; then
  cat "$TEMP_BUILD/app.log" >&2
  echo "Crash recovery app did not reach its ready state" >&2
  exit 1
fi

CONTENT_PID=""
for candidate in $(ps -axo pid,comm | awk '$2 ~ /WebContent/ {print $1}'); do
  if ! grep -qw "$candidate" <<<"$BASELINE_WEB_CONTENT_PIDS"; then
    CONTENT_PID="$candidate"
    break
  fi
done
if [[ -z "$CONTENT_PID" || "$CONTENT_PID" == "$APP_PID" ]]; then
  ps -axo pid,ppid,command | rg 'WebContent|WKPrototype' >&2 || true
  echo "Could not identify a WebContent process belonging to the isolated test app; no process was terminated" >&2
  exit 1
fi

CONTENT_PPID="$(ps -p "$CONTENT_PID" -o ppid= | tr -d ' ')"
CONTENT_COMMAND="$(ps -p "$CONTENT_PID" -o command=)"
if [[ "$CONTENT_PPID" != "$APP_PID" && "$CONTENT_COMMAND" != *"$BUNDLE_ID"* ]]; then
  launchctl procinfo "$CONTENT_PID" >"$TEMP_BUILD/procinfo.log" 2>&1 || true
  cat "$TEMP_BUILD/procinfo.log" >&2
  echo "The new WebContent process is not attributable to the isolated app; no process was terminated" >&2
  exit 1
fi

echo "Terminating isolated WebContent PID $CONTENT_PID for test app PID $APP_PID"
kill -9 "$CONTENT_PID"
for _ in $(seq 1 120); do
  if [[ -f "$RESULT" ]]; then break; fi
  if ! kill -0 "$APP_PID" 2>/dev/null; then
    cat "$TEMP_BUILD/app.log" >&2
    echo "Host app exited before recording recovery results" >&2
    exit 1
  fi
  sleep 0.25
done
if [[ ! -f "$RESULT" ]]; then
  cat "$TEMP_BUILD/app.log" >&2
  echo "Crash recovery result was not written" >&2
  exit 1
fi
python3 -c 'import json,sys; result=json.load(open(sys.argv[1])); assert result["status"] == "passed", json.dumps(result, indent=2); assert result["failureCount"] == 0; print("Local crash recovery harness passed:", len(result["tests"]), "checks")' "$RESULT"
echo "Results: $RESULT"
