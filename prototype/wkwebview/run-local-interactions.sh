#!/bin/bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")" && pwd)"
TEMP_BUILD="$(mktemp -d "${TMPDIR:-/private/tmp}/wkwebview-interactions.XXXXXX")"
SERVER_PID=""
APP_WAIT_PID=""
cleanup() {
  if [[ -n "$APP_WAIT_PID" ]]; then wait "$APP_WAIT_PID" 2>/dev/null || true; fi
  if [[ -n "$SERVER_PID" ]]; then
    kill "$SERVER_PID" 2>/dev/null || true
    wait "$SERVER_PID" 2>/dev/null || true
  fi
  rm -rf "$TEMP_BUILD"
}
trap cleanup EXIT
BUNDLE_ID="internal.vezham.WKPrototype.Interactions.$(date +%s).$$"
RUN_ID="$(date -u +%Y%m%dT%H%M%SZ)-$$"
mkdir -p "$TEMP_BUILD/picker" "$TEMP_BUILD/destination"
printf 'Synthetic cancellation fixture\n' > "$TEMP_BUILD/picker/do-not-select.txt"
WK_BUILD_DIR="$TEMP_BUILD/build" WK_BUNDLE_ID="$BUNDLE_ID" bash "$ROOT/build.sh"
python3 "$ROOT/Fixtures/interaction_server.py" >"$TEMP_BUILD/fixture.log" 2>&1 &
SERVER_PID=$!
for _ in $(seq 1 50); do
  if ! kill -0 "$SERVER_PID" 2>/dev/null; then cat "$TEMP_BUILD/fixture.log" >&2; exit 1; fi
  if curl --max-time 2 --silent --fail 'http://127.0.0.1:18765/interaction-state' --output "$TEMP_BUILD/state.json"; then break; fi
  sleep 0.1
done
curl --max-time 2 --silent --fail 'http://127.0.0.1:18765/interaction-state' --output "$TEMP_BUILD/state.json"
RESULTS_DIR="$HOME/Library/Containers/$BUNDLE_ID/Data/Library/Application Support/WKPrototype"
EVENTS="$RESULTS_DIR/interaction-events-$RUN_ID.json"
RESULT="$RESULTS_DIR/interaction-results-$RUN_ID.json"
echo "Opening isolated interaction app: $BUNDLE_ID"
echo "Run: $RUN_ID"
open -n -W -a "$TEMP_BUILD/build/VezhamWKPrototype.app" --args --test-local-interactions --test-run-id "$RUN_ID" --test-upload-directory "$TEMP_BUILD/picker" --test-download-directory "$TEMP_BUILD/destination" >"$TEMP_BUILD/open.log" 2>&1 &
APP_WAIT_PID=$!
for _ in $(seq 1 520); do
  curl --max-time 2 --silent --fail 'http://127.0.0.1:18765/interaction-state' --output "$TEMP_BUILD/state.json" || true
  if python3 - "$EVENTS" "$TEMP_BUILD/state.json" >/dev/null 2>&1 <<'PY'
import json,pathlib,sys
try:
    native=json.loads(pathlib.Path(sys.argv[1]).read_text())
    page=json.loads(pathlib.Path(sys.argv[2]).read_text())
except (OSError,ValueError):raise SystemExit(1)
assert {'upload-cancelled','download-cancelled','popup-opened','navigation-blocked'} <= {e['event'] for e in native}
assert {'upload-check','redirect','popup'} <= {e['kind'] for e in page['events']}
PY
  then break; fi
  if ! kill -0 "$APP_WAIT_PID" 2>/dev/null; then break; fi
  sleep 0.5
done
# Allow pending page events and transfer callbacks to settle before checking.
sleep 1
curl --max-time 2 --silent --fail 'http://127.0.0.1:18765/interaction-state' --output "$TEMP_BUILD/state.json"
python3 - "$EVENTS" "$TEMP_BUILD/state.json" "$TEMP_BUILD/destination" "$RESULT" "$RUN_ID" "$(sw_vers -productVersion)" <<'PY'
import json,pathlib,sys
native_path=pathlib.Path(sys.argv[1])
native=json.loads(native_path.read_text()) if native_path.exists() else []
page=json.loads(pathlib.Path(sys.argv[2]).read_text())
def event(name):return next((e for e in native if e.get('event')==name),{})
def page_event(name):return next((e for e in page['events'] if e.get('kind')==name),{})
initial=next((e for e in native if e.get('event')=='navigation-finished' and e.get('path')=='/interaction-fixture'),{})
popup=event('popup-opened')
popup_load=next((e for e in native if e.get('event')=='navigation-finished' and e.get('fixtureCase')=='popup' and e.get('store')==popup.get('store')), {})
tests=[]
def check(label,passed):tests.append({'label':label,'passed':bool(passed)})
check('upload picker cancellation returned zero file URLs',event('upload-cancelled').get('fileCount')==0)
check('page FileList stayed empty after cancellation',page_event('upload-check').get('fileCount')==0)
check('fixture received zero upload requests and bytes',page['uploadRequests']==0 and page['uploadBytes']==0)
check('download save panel cancellation returned no destination',bool(event('download-cancelled')))
check('attachment response reached the save-panel path once',page['downloadResponses']==1)
check('isolated download destination stayed empty',not list(pathlib.Path(sys.argv[3]).iterdir()))
for name in ('redirect','popup'):
    e=page_event(name)
    check(name+' page retained the private localStorage marker and cookie',e.get('marker')=='synthetic-private-marker' and e.get('cookiePresent') is True)
check('popup used the originating native data store',bool(initial) and bool(popup_load) and initial.get('store')==popup.get('store'))
check('popup used the originating private-session label',bool(initial) and initial.get('profile','').startswith('Private') and initial.get('profile')==popup.get('profile'))
blocked=event('navigation-blocked')
check('unsupported scheme cancelled while fixture remained current',blocked.get('scheme')=='vezham-unsupported' and blocked.get('currentPath')=='/interaction-fixture')
check('redirect and popup pages had no vezham native bridge',all(page_event(name).get('bridgeAbsent') is True for name in ('redirect','popup')))
check('no file selection or successful download followed cancellation',not any(e.get('event') in ('upload-selected','download-selected','download-finished') for e in native))
failures=[t['label'] for t in tests if not t['passed']]
result={'mode':'local-interactions','runID':sys.argv[5],'hostOSVersion':sys.argv[6],'deploymentTarget':'macOS 26.0','status':'failed' if failures else 'passed','failureCount':len(failures),'failures':failures,'tests':tests,'nativeEvents':native,'fixtureObservations':page}
output=pathlib.Path(sys.argv[4]);output.parent.mkdir(parents=True,exist_ok=True)
output.write_text(json.dumps(result,indent=2,sort_keys=True)+'\n')
print('Local interaction checks:',result['status'],str(len(tests)-len(failures))+'/'+str(len(tests)))
print('Results:',output)
if failures:raise SystemExit(1)
PY
wait "$APP_WAIT_PID"
APP_WAIT_PID=""
