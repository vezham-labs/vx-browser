#!/bin/bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
TEMP_BUILD="$(mktemp -d "${TMPDIR:-/private/tmp}/wkwebview-permission.XXXXXX")"
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

BUNDLE_ID="internal.vezham.WKPrototype.PermissionDeny.$(date +%s).$$"
RUN_ID="$(date -u +%Y%m%dT%H%M%SZ)-$$"
BUILD_DIR="$TEMP_BUILD/build"
TEST_ENTITLEMENTS="$TEMP_BUILD/test-entitlements.plist"
cp "$ROOT/entitlements.plist" "$TEST_ENTITLEMENTS"
/usr/libexec/PlistBuddy -c 'Add :com.apple.security.device.camera bool true' "$TEST_ENTITLEMENTS"
/usr/libexec/PlistBuddy -c 'Add :com.apple.security.device.audio-input bool true' "$TEST_ENTITLEMENTS"

WK_BUILD_DIR="$BUILD_DIR" WK_BUNDLE_ID="$BUNDLE_ID" WK_ENTITLEMENTS="$TEST_ENTITLEMENTS" WK_MEDIA_CAPTURE_TEST=1 bash "$ROOT/build.sh"
APP_BUNDLE="$BUILD_DIR/VezhamWKPrototype.app"
codesign -d --entitlements :- "$APP_BUNDLE" >"$TEMP_BUILD/signed-entitlements.plist" 2>/dev/null
plutil -lint "$TEMP_BUILD/signed-entitlements.plist" "$APP_BUNDLE/Contents/Info.plist" >/dev/null
/usr/libexec/PlistBuddy -c 'Print :com.apple.security.device.camera' "$TEMP_BUILD/signed-entitlements.plist" | rg -q true
/usr/libexec/PlistBuddy -c 'Print :com.apple.security.device.audio-input' "$TEMP_BUILD/signed-entitlements.plist" | rg -q true
/usr/libexec/PlistBuddy -c 'Print :NSCameraUsageDescription' "$APP_BUNDLE/Contents/Info.plist" >/dev/null
/usr/libexec/PlistBuddy -c 'Print :NSMicrophoneUsageDescription' "$APP_BUNDLE/Contents/Info.plist" >/dev/null
echo "Temporary camera/microphone entitlements and purpose strings verified."
python3 "$ROOT/Fixtures/server.py" >"$TEMP_BUILD/fixture.log" 2>&1 &
SERVER_PID=$!
for _ in $(seq 1 50); do
  if ! kill -0 "$SERVER_PID" 2>/dev/null; then
    echo "Loopback fixture server failed to start; see $TEMP_BUILD/fixture.log" >&2
    exit 1
  fi
  if curl --silent --fail --output /dev/null 'http://127.0.0.1:18765/permission-status'; then break; fi
  sleep 0.1
done
if ! curl --silent --fail --output /dev/null 'http://127.0.0.1:18765/permission-fixture'; then
  echo "Loopback fixture server did not become ready; see $TEMP_BUILD/fixture.log" >&2
  exit 1
fi

echo "Opening isolated permission-denial app: $BUNDLE_ID"
open -n -W -a "$APP_BUNDLE" --args --test-permission-deny --test-permission-run-id "$RUN_ID" --test-permission-timeout-seconds 210 >"$TEMP_BUILD/open.log" 2>&1 &
APP_WAIT_PID=$!

RESULTS_DIR="$HOME/Library/Containers/$BUNDLE_ID/Data/Library/Application Support/WKPrototype"
RESULT="$RESULTS_DIR/permission-deny-results-$RUN_ID.json"
EVENT_LOG="$RESULTS_DIR/permission-ui-events-$RUN_ID.log"
STATUS="pending"
for _ in $(seq 1 360); do
  curl --silent --fail 'http://127.0.0.1:18765/permission-status' --output "$TEMP_BUILD/permission-status.json" || true
  STATUS="$(python3 -c 'import json,sys; print(json.load(open(sys.argv[1])).get("status", "pending"))' "$TEMP_BUILD/permission-status.json" 2>/dev/null || true)"
  if [[ "$STATUS" != "pending" ]]; then break; fi
  if ! kill -0 "$APP_WAIT_PID" 2>/dev/null; then break; fi
  sleep 0.5
done

python3 - "$TEMP_BUILD/permission-status.json" "$EVENT_LOG" "$RESULT" "$(sw_vers -productVersion)" <<'PY'
import json
import pathlib
import sys

status_path = pathlib.Path(sys.argv[1])
event_path = pathlib.Path(sys.argv[2])
observed = json.loads(status_path.read_text()) if status_path.exists() else {"status": "pending"}
events = event_path.read_text().splitlines() if event_path.exists() else []
denied = observed.get("status") == "denied" and observed.get("errorName") == "NotAllowedError"
prompt_shown = any(event.startswith("native permission prompt shown:") for event in events)
prompt_denied = "native permission prompt choice: deny" in events and "native permission prompt decision: deny" in events
tests = [
    {"label": "website received NotAllowedError", "passed": denied},
    {"label": "website received no media stream", "passed": denied},
    {"label": "native allow/deny prompt was displayed", "passed": prompt_shown},
    {"label": "native prompt was answered Deny", "passed": prompt_denied},
]
failures = [test["label"] for test in tests if not test["passed"]]
status = "passed" if not failures else ("partially_verified" if denied else "failed")
result = {
    "mode": "permission-deny",
    "hostOSVersion": sys.argv[4],
    "status": status,
    "observedPageResult": observed,
    "nativeEvents": events,
    "tests": tests,
    "failureCount": len(failures),
    "failures": failures,
}
output = pathlib.Path(sys.argv[3])
output.parent.mkdir(parents=True, exist_ok=True)
output.write_text(json.dumps(result, indent=2, sort_keys=True) + "\n")
print("Native permission-denial check:", result["status"], "(" + str(len(tests) - len(failures)) + "/" + str(len(tests)) + " checks)")
print("Results:", output)
if status == "failed":
    raise SystemExit(1)
PY

# Keep the app available for desktop inspection until it is closed or its
# 210-second safety timeout fires.
wait "$APP_WAIT_PID"
APP_WAIT_PID=""
