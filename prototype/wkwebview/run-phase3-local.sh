#!/bin/bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")" && pwd)"
TEMP_BUILD="$(mktemp -d "${TMPDIR:-/private/tmp}/wkwebview-final.XXXXXX")"
SERVER_PID=""
APP_WAIT_PID=""
cleanup() {
  if [[ -n "$APP_WAIT_PID" ]]; then wait "$APP_WAIT_PID" 2>/dev/null || true; fi
  if [[ -n "$SERVER_PID" ]]; then kill "$SERVER_PID" 2>/dev/null || true; wait "$SERVER_PID" 2>/dev/null || true; fi
  rm -rf "$TEMP_BUILD"
}
trap cleanup EXIT
BUNDLE_ID="internal.vezham.WKPrototype.Phase3.$(date +%s).$$"
RUN_ID="$(date -u +%Y%m%dT%H%M%SZ)-$$"
DOWNLOAD_ONLY="${WK_PHASE3_DOWNLOAD_ONLY:-0}"
if [[ "$DOWNLOAD_ONLY" != "0" && "$DOWNLOAD_ONLY" != "1" ]]; then echo "WK_PHASE3_DOWNLOAD_ONLY must be 0 or 1" >&2; exit 1; fi
python3 - "$TEMP_BUILD" <<'PY'
import pathlib,sys
p=pathlib.Path(sys.argv[1])
for name,content in {'multi/alpha.txt':'alpha synthetic\n','multi/..odd name;.txt':'odd synthetic\n','directory-parent/fixture-folder/child.txt':'folder synthetic\n','directory-parent/fixture-folder/nested/leaf.txt':'nested synthetic\n','destination/existing.txt':'original must remain\n'}.items():
 f=p/name;f.parent.mkdir(parents=True,exist_ok=True);f.write_text(content)
PY
WK_BUILD_DIR="$TEMP_BUILD/build" WK_BUNDLE_ID="$BUNDLE_ID" bash "$ROOT/build.sh"
python3 "$ROOT/Fixtures/phase3_server.py" >"$TEMP_BUILD/server.log" 2>&1 &
SERVER_PID=$!
for _ in $(seq 1 50); do
  if ! kill -0 "$SERVER_PID" 2>/dev/null; then cat "$TEMP_BUILD/server.log" >&2; exit 1; fi
  if curl --max-time 2 --silent --fail 'http://127.0.0.1:18765/state' --output "$TEMP_BUILD/state.json"; then break; fi
  sleep 0.1
done
curl --max-time 2 --silent --fail 'http://127.0.0.1:18766/state' --output /dev/null
RESULTS_DIR="$HOME/Library/Containers/$BUNDLE_ID/Data/Library/Application Support/WKPrototype"
EVENTS="$RESULTS_DIR/interaction-events-$RUN_ID.json"
RESULT="$RESULTS_DIR/phase3-local-results-$RUN_ID.json"
echo "Opening final local app: $BUNDLE_ID"
echo "Run: $RUN_ID"
open -n -W -a "$TEMP_BUILD/build/VezhamWKPrototype.app" --args --test-phase3-local --test-run-id "$RUN_ID" --test-upload-directory "$TEMP_BUILD/multi" --test-directory-fixture-root "$TEMP_BUILD/directory-parent" --test-download-directory "$TEMP_BUILD/destination" >"$TEMP_BUILD/open.log" 2>&1 &
APP_WAIT_PID=$!
for _ in $(seq 1 1000); do
  curl --max-time 2 --silent --fail 'http://127.0.0.1:18765/state' --output "$TEMP_BUILD/state.json" || true
  if python3 - "$EVENTS" "$TEMP_BUILD/state.json" "$DOWNLOAD_ONLY" >/dev/null 2>&1 <<'PY'
import json,pathlib,sys
try:native=json.loads(pathlib.Path(sys.argv[1]).read_text()); state=json.loads(pathlib.Path(sys.argv[2]).read_text())
except (OSError,ValueError):raise SystemExit(1)
selected=next(e for e in native if e['event']=='download-selected' and e.get('suggestedName')=='interrupted.bin')
assert any(e['event']=='download-error' and e.get('downloadID')==selected['downloadID'] for e in native)
complete=next(e for e in native if e['event']=='download-selected' and e.get('suggestedName')=='complete.txt')
assert any(e['event'] in ('download-finished','download-save-error') and e.get('downloadID')==complete['downloadID'] for e in native)
if sys.argv[3]=='1':raise SystemExit(0)
assert {'frame-result','redirect','popup'} <= {e.get('kind') for e in state['events']}
assert {'multiple','directory'} <= {e.get('kind') for e in state['uploads']}
assert any(e['event']=='download-cancelled' and e.get('suggestedName')=='existing.txt' for e in native)
assert any(e['event']=='navigation-blocked' and e.get('mainFrame') and e.get('scheme')=='vezham-ui' for e in native)
PY
  then break; fi
  if ! kill -0 "$APP_WAIT_PID" 2>/dev/null; then break; fi
  sleep 0.5
done
sleep 1
curl --max-time 2 --silent --fail 'http://127.0.0.1:18765/state' --output "$TEMP_BUILD/state.json"
python3 - "$EVENTS" "$TEMP_BUILD/state.json" "$TEMP_BUILD/destination" "$RESULT" "$RUN_ID" "$(sw_vers -productVersion)" "$DOWNLOAD_ONLY" <<'PY'
import json,pathlib,sys
path=pathlib.Path(sys.argv[1]);native=json.loads(path.read_text()) if path.exists() else []
state=json.loads(pathlib.Path(sys.argv[2]).read_text());dest=pathlib.Path(sys.argv[3])
def event(kind):return next((e for e in state['events'] if e.get('kind')==kind),{})
def upload(kind):return next((e for e in state['uploads'] if e.get('kind')==kind),{})
tests=[]
def check(label,passed):tests.append({'label':label,'passed':bool(passed)})
frame=event('frame-result')
check('cross-origin frame could not read parent DOM',frame.get('parentReadDenied') is True)
check('100 malformed and forged native-channel attempts executed',frame.get('attemptCount')==100)
check('no native channel was reachable in 100 attempts',frame.get('reachable')==0 and frame.get('throws')==100 and frame.get('bridgeAbsent') is True)
check('100 untrusted frame messages arrived without native dispatch',frame.get('receivedMessages')==100 and len([e for e in native if e['event']=='popup-opened'])==1)
check('privileged-scheme frame navigation was blocked',any(e['event']=='navigation-blocked' and e.get('scheme')=='vezham-ui' and not e.get('mainFrame') for e in native))
for kind in ('redirect','popup'):
 e=event(kind)
 check('cross-origin '+kind+' loaded second origin',e.get('origin')=='http://127.0.0.1:18766')
 check('cross-origin '+kind+' could not read origin A localStorage',e.get('AStorageAbsent') is True)
 check('cross-origin '+kind+' had no native page bridge',e.get('bridgeAbsent') is True)
initial=next((e for e in native if e['event']=='navigation-finished' and e.get('path')=='/phase3'),{})
popup=next((e for e in native if e['event']=='popup-opened'),{})
popup_load=next((e for e in native if e['event']=='navigation-finished' and e.get('fixtureCase')=='popup'),{})
check('cross-origin popup retained native private data store',bool(initial) and initial.get('store')==popup.get('store')==popup_load.get('store'))
check('cross-origin popup retained private-session label',bool(initial) and initial.get('profile','').startswith('Private') and initial.get('profile')==popup.get('profile')==popup_load.get('profile'))
check('redirect to privileged app scheme received native cancel decision',any(e['event']=='navigation-blocked' and e.get('scheme')=='vezham-ui' and e.get('mainFrame') for e in native))
multiple=upload('multiple').get('files',[])
check('multiple upload disclosed exactly the two chosen basenames',len(multiple)==2 and {f.get('name') for f in multiple}=={'alpha.txt','..odd name;.txt'})
check('multiple upload contents matched the synthetic files',{f.get('name'):f.get('content') for f in multiple}=={'alpha.txt':'alpha synthetic\n','..odd name;.txt':'odd synthetic\n'})
folder=upload('directory').get('files',[])
check('directory upload enumerated exactly the selected tree',len(folder)==2 and {f.get('relativePath') for f in folder}=={'fixture-folder/child.txt','fixture-folder/nested/leaf.txt'})
check('directory upload contents matched selected tree',{f.get('name'):f.get('content') for f in folder}=={'child.txt':'folder synthetic\n','leaf.txt':'nested synthetic\n'})
check('native picker reported both multi-file and directory selections',any(e['event']=='upload-selected' and e.get('fileCount')==2 and not e.get('directoriesAllowed') for e in native) and any(e['event']=='upload-selected' and e.get('directoriesAllowed') for e in native))
check('no extra upload payloads were received',len(state['uploads'])==2)
check('duplicate-name save was cancelled',any(e['event']=='download-cancelled' and e.get('suggestedName')=='existing.txt' for e in native))
check('original duplicate-name file was unchanged',(dest/'existing.txt').read_bytes()==b'original must remain\n')
interrupted=next((e for e in native if e['event']=='download-selected' and e.get('suggestedName')=='interrupted.bin'),{})
check('interrupted download used selected test filename',interrupted.get('selectedBasename')=='interrupted.bin')
check('interrupted download surfaced a network error',bool(interrupted) and any(e['event']=='download-error' and e.get('downloadID')==interrupted.get('downloadID') and e.get('code')!=-999 for e in native))
check('interrupted download was not reported as finished',bool(interrupted) and not any(e['event']=='download-finished' and e.get('downloadID')==interrupted.get('downloadID') for e in native))
files=[{'name':p.name,'bytes':p.stat().st_size} for p in dest.iterdir() if p.is_file()]
check('incomplete download left no completed artifact',not (dest/'interrupted.bin').exists())
check('interrupted download staging directory was removed',bool(interrupted) and any(e['event']=='download-cleanup' and e.get('downloadID')==interrupted.get('downloadID') and e.get('removed') is True for e in native))
complete=next((e for e in native if e['event']=='download-selected' and e.get('suggestedName')=='complete.txt'),{})
check('completed download was moved to selected final destination',(dest/'complete.txt').is_file() and (dest/'complete.txt').read_bytes()==b'complete synthetic payload\n')
check('completed download reported success only after saving',bool(complete) and any(e['event']=='download-finished' and e.get('downloadID')==complete.get('downloadID') for e in native))
check('completed download staging directory was removed',bool(complete) and any(e['event']=='download-cleanup' and e.get('downloadID')==complete.get('downloadID') and e.get('removed') is True for e in native))
if sys.argv[7]=='1':
    tests=[t for t in tests if t['label'].startswith(('interrupted download','incomplete download','completed download','original duplicate-name'))]
failures=[t['label'] for t in tests if not t['passed']]
result={'mode':'phase3-local','runID':sys.argv[5],'hostOSVersion':sys.argv[6],'deploymentTarget':'macOS 26.0','status':'failed' if failures else 'passed','tests':tests,'failureCount':len(failures),'failures':failures,'nativeEvents':native,'fixtureObservations':state,'destinationArtifacts':files,'scope':'Two loopback HTTP origins; no production UI/native transport exists. No actual validator-rejection claim for unreachable bridge attempts.'}
output=pathlib.Path(sys.argv[4]);output.parent.mkdir(parents=True,exist_ok=True);output.write_text(json.dumps(result,indent=2,sort_keys=True)+'\n')
print('Final local suite:',result['status'],str(len(tests)-len(failures))+'/'+str(len(tests)))
print('Results:',output)
if failures:print('Failures:',failures)
PY
wait "$APP_WAIT_PID"
APP_WAIT_PID=""
python3 -c 'import json,sys; sys.exit(0 if json.load(open(sys.argv[1]))["status"]=="passed" else 1)' "$RESULT"
