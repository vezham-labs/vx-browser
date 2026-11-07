#!/bin/bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
TEMP_BUILD="$(mktemp -d "${TMPDIR:-/private/tmp}/wkwebview-download.XXXXXX")"
SERVER_PID=""
cleanup() {
  if [[ -n "$SERVER_PID" ]]; then
    kill "$SERVER_PID" 2>/dev/null || true
    wait "$SERVER_PID" 2>/dev/null || true
  fi
  rm -rf "$TEMP_BUILD"
}
trap cleanup EXIT
BUNDLE_ID="internal.vezham.WKPrototype.Download.$(date +%s).$$"
RUN_ID="$(date -u +%Y%m%dT%H%M%SZ)-$$"
BUILD_DIR="$TEMP_BUILD/build"

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

EXECUTABLE="$BUILD_DIR/VezhamWKPrototype.app/Contents/MacOS/VezhamWKPrototype"
"$EXECUTABLE" --test-download --test-run-id "$RUN_ID"
RESULTS_DIR="$HOME/Library/Containers/$BUNDLE_ID/Data/Library/Application Support/WKPrototype"
RESULT="$RESULTS_DIR/download-results-$RUN_ID.json"
python3 -c 'import json,sys; result=json.load(open(sys.argv[1])); assert result["status"] == "passed", json.dumps(result, indent=2); assert result["failureCount"] == 0; print("Local download harness passed:", len(result["tests"]), "checks")' "$RESULT"
echo "Results: $RESULT"
