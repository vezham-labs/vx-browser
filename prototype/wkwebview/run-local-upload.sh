#!/bin/bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
TEMP_BUILD="$(mktemp -d "${TMPDIR:-/private/tmp}/wkwebview-upload.XXXXXX")"
SERVER_PID=""
cleanup() {
  if [[ -n "$SERVER_PID" ]]; then
    kill "$SERVER_PID" 2>/dev/null || true
    wait "$SERVER_PID" 2>/dev/null || true
  fi
  rm -rf "$TEMP_BUILD"
}
trap cleanup EXIT

BUNDLE_ID="internal.vezham.WKPrototype.Upload.$(date +%s).$$"
RUN_ID="$(date -u +%Y%m%dT%H%M%SZ)-$$"
BUILD_DIR="$TEMP_BUILD/build"
UPLOAD_DIR="$TEMP_BUILD/upload-fixture"
mkdir -p "$UPLOAD_DIR"
printf 'Vezham synthetic upload fixture\n' > "$UPLOAD_DIR/upload-fixture.txt"

WK_BUILD_DIR="$BUILD_DIR" WK_BUNDLE_ID="$BUNDLE_ID" bash "$ROOT/build.sh"
python3 "$ROOT/Fixtures/server.py" >"$TEMP_BUILD/fixture.log" 2>&1 &
SERVER_PID=$!
for _ in $(seq 1 50); do
  if ! kill -0 "$SERVER_PID" 2>/dev/null; then
    echo "Loopback fixture server failed to start; see $TEMP_BUILD/fixture.log" >&2
    exit 1
  fi
  if curl --silent --fail --output /dev/null 'http://127.0.0.1:18765/upload-status'; then break; fi
  sleep 0.1
done
if ! curl --silent --fail --output /dev/null 'http://127.0.0.1:18765/upload-status'; then
  echo "Loopback fixture server did not become ready; see $TEMP_BUILD/fixture.log" >&2
  exit 1
fi

APP_BUNDLE="$BUILD_DIR/VezhamWKPrototype.app"
echo "Opening isolated upload app: $BUNDLE_ID"
echo "Synthetic picker folder: $UPLOAD_DIR"
open -n -a "$APP_BUNDLE" --args --test-upload --test-upload-directory "$UPLOAD_DIR" --test-upload-timeout-seconds 210
STATUS="missing"
for _ in $(seq 1 360); do
  curl --silent --fail 'http://127.0.0.1:18765/upload-status' --output "$TEMP_BUILD/upload-status.json" || true
  STATUS="$(python3 -c 'import json,sys; print(json.load(open(sys.argv[1])).get("status", "missing"))' "$TEMP_BUILD/upload-status.json" 2>/dev/null || true)"
  if [[ "$STATUS" == "passed" || "$STATUS" == "failed" ]]; then break; fi
  sleep 0.5
done
if [[ "$STATUS" != "passed" && "$STATUS" != "failed" ]]; then
  echo "Upload test timed out before a file was submitted" >&2
  exit 1
fi

RESULTS_DIR="$HOME/Library/Containers/$BUNDLE_ID/Data/Library/Application Support/WKPrototype"
mkdir -p "$RESULTS_DIR"
RESULT="$RESULTS_DIR/upload-results-$RUN_ID.json"
cp "$TEMP_BUILD/upload-status.json" "$RESULT"
python3 -c 'import json,sys; result=json.load(open(sys.argv[1])); assert result["status"] == "passed", json.dumps(result, indent=2); assert result["failureCount"] == 0; print("Local upload harness passed:", len(result["tests"]), "checks; uploaded", result["byteCount"], "bytes")' "$RESULT"
echo "Results: $RESULT"
