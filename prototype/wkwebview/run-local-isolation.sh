#!/bin/bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
TEMP_BUILD="$(mktemp -d "${TMPDIR:-/private/tmp}/wkwebview-isolation.XXXXXX")"
SERVER_PID=""
cleanup() {
  if [[ -n "$SERVER_PID" ]]; then
    kill "$SERVER_PID" 2>/dev/null || true
    wait "$SERVER_PID" 2>/dev/null || true
  fi
  rm -rf "$TEMP_BUILD"
}
trap cleanup EXIT

BUNDLE_ID="internal.vezham.WKPrototype.Isolation.$(date +%s).$$"
RUN_ID="$(date -u +%Y%m%dT%H%M%SZ)-$$"
BUILD_DIR="$TEMP_BUILD/build"
RESULTS_DIR="$HOME/Library/Containers/$BUNDLE_ID/Data/Library/Application Support/WKPrototype"

WK_BUILD_DIR="$BUILD_DIR" WK_BUNDLE_ID="$BUNDLE_ID" bash "$ROOT/build.sh"
python3 "$ROOT/Fixtures/server.py" >"$TEMP_BUILD/fixture.log" 2>&1 &
SERVER_PID=$!
for _ in $(seq 1 50); do
  if ! kill -0 "$SERVER_PID" 2>/dev/null; then
    echo "Loopback fixture server failed to start; see $TEMP_BUILD/fixture.log" >&2
    exit 1
  fi
  if curl --silent --fail 'http://127.0.0.1:18765/fixture?profile=a&mode=verify' >/dev/null; then break; fi
  sleep 0.1
done
if ! curl --silent --fail 'http://127.0.0.1:18765/fixture?profile=a&mode=verify' >/dev/null; then
  echo "Loopback fixture server did not become ready; see build/fixture.log" >&2
  exit 1
fi
EXECUTABLE="$BUILD_DIR/VezhamWKPrototype.app/Contents/MacOS/VezhamWKPrototype"
"$EXECUTABLE" --test-seed --test-run-id "$RUN_ID"
python3 -c 'import json,sys; result=json.load(open(sys.argv[1])); assert result["status"] == "passed", json.dumps(result, indent=2)' "$RESULTS_DIR/isolation-results-$RUN_ID-seed.json"
"$EXECUTABLE" --test-verify --test-run-id "$RUN_ID"
python3 -c 'import json,sys; result=json.load(open(sys.argv[1])); assert result["status"] == "passed", json.dumps(result, indent=2)' "$RESULTS_DIR/isolation-results-$RUN_ID-verify.json"
"$EXECUTABLE" --test-private-windows --test-run-id "$RUN_ID"
python3 -c 'import json,sys; result=json.load(open(sys.argv[1])); assert result["status"] == "passed", json.dumps(result, indent=2)' "$RESULTS_DIR/window-lifecycle-results-$RUN_ID.json"
echo "Local storage and private-window lifecycle harness passed. Results: $RESULTS_DIR/*results-$RUN_ID*.json"
