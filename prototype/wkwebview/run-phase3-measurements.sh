#!/bin/bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")" && pwd)"
TEMP_BUILD="$(mktemp -d "${TMPDIR:-/private/tmp}/wkwebview-measurements.XXXXXX")"
SERVER_PID=""
IDLE_PID=""
cleanup() {
  if [[ -n "$IDLE_PID" ]] && kill -0 "$IDLE_PID" 2>/dev/null; then kill "$IDLE_PID" 2>/dev/null || true; wait "$IDLE_PID" 2>/dev/null || true; fi
  if [[ -n "$SERVER_PID" ]]; then kill "$SERVER_PID" 2>/dev/null || true; wait "$SERVER_PID" 2>/dev/null || true; fi
  rm -rf "$TEMP_BUILD"
}
trap cleanup EXIT
BUNDLE_ID="internal.vezham.WKPrototype.Measurements.$(date +%s).$$"
RUN_ID="$(date -u +%Y%m%dT%H%M%SZ)-$$"
WK_BUILD_DIR="$TEMP_BUILD/build" WK_BUNDLE_ID="$BUNDLE_ID" bash "$ROOT/build.sh"
EXECUTABLE="$TEMP_BUILD/build/VezhamWKPrototype.app/Contents/MacOS/VezhamWKPrototype"
RESULTS="$HOME/Library/Containers/$BUNDLE_ID/Data/Library/Application Support/WKPrototype"
EVIDENCE="$ROOT/Evidence/measurements-$RUN_ID"
mkdir -p "$EVIDENCE"
echo "Measurement identity: $BUNDLE_ID"
echo "Run: $RUN_ID"
python3 - "$EVIDENCE/environment.json" <<'PY'
import json,pathlib,re,subprocess,sys
def command(args):
 p=subprocess.run(args,capture_output=True,text=True)
 return {'exitCode':p.returncode,'output':p.stdout.strip(),'error':p.stderr.strip()}
identities=command(['/usr/bin/security','find-identity','-v','-p','codesigning'])
match=re.search(r'(\d+) valid identities',identities['output'])
data={'hostModel':command(['/usr/sbin/sysctl','-n','hw.model']),'memoryBytes':command(['/usr/sbin/sysctl','-n','hw.memsize']),'power':command(['/usr/bin/pmset','-g','batt']),'OS':command(['/usr/bin/sw_vers']),'toolchain':command(['/usr/bin/xcodebuild','-version']),'validSigningIdentityCount':int(match.group(1)) if match else None,'method':'Existing interactive work session; other user apps remain running; hidden test host windows; no OS cache flush. Synthetic timing results require a controlled release baseline before a full performance-gate pass.','targetsRatifiedByUser':True}
pathlib.Path(sys.argv[1]).write_text(json.dumps(data,indent=2,sort_keys=True)+'\n')
PY
otool -L "$EXECUTABLE" > "$EVIDENCE/linked-libraries.txt"
python3 "$ROOT/Fixtures/phase3_server.py" >"$TEMP_BUILD/server.log" 2>&1 &
SERVER_PID=$!
for _ in $(seq 1 50); do
  if ! kill -0 "$SERVER_PID" 2>/dev/null; then cat "$TEMP_BUILD/server.log" >&2; exit 1; fi
  if curl --max-time 2 --silent --fail 'http://127.0.0.1:18765/state' --output /dev/null; then break; fi
  sleep 0.1
done
curl --max-time 2 --silent --fail 'http://127.0.0.1:18765/benchmark-page' --output "$TEMP_BUILD/page.html"
python3 -c 'import pathlib,sys; assert pathlib.Path(sys.argv[1]).stat().st_size==1048576' "$TEMP_BUILD/page.html"
for i in $(seq 1 30); do
  "$EXECUTABLE" --test-performance-sample --test-run-id "$RUN_ID-sample-$i" >"$TEMP_BUILD/sample.log" 2>&1
  cp "$RESULTS/performance-sample-$RUN_ID-sample-$i.json" "$EVIDENCE/"
  if (( i % 5 == 0 )); then echo "Timing samples collected: $i/30"; fi
done
echo "Starting public-page smoke checks; approved public pages only."
"$EXECUTABLE" --test-public-sites --test-run-id "$RUN_ID-sites" >"$TEMP_BUILD/sites.log" 2>&1 &
SITES_PID=$!
while kill -0 "$SITES_PID" 2>/dev/null; do
  sleep 10
  tail -1 "$TEMP_BUILD/sites.log" || true
done
wait "$SITES_PID"
cp "$RESULTS/public-sites-results-$RUN_ID-sites.json" "$EVIDENCE/"
echo "Starting ten-view, ten-minute idle observation."
"$EXECUTABLE" --test-ten-idle-views --test-run-id "$RUN_ID-idle" >"$TEMP_BUILD/idle.log" 2>&1 &
IDLE_PID=$!
for _ in $(seq 1 300); do
  if [[ -f "$RESULTS/idle-ready-$RUN_ID-idle.json" || -f "$RESULTS/performance-idle-$RUN_ID-idle.json" ]]; then break; fi
  if ! kill -0 "$IDLE_PID" 2>/dev/null; then cat "$TEMP_BUILD/idle.log" >&2; exit 1; fi
  sleep 0.2
done
python3 - "$IDLE_PID" "$RESULTS/performance-idle-$RUN_ID-idle.json" "$EVIDENCE/idle-resource-observations.json" <<'PY'
import json,pathlib,subprocess,sys,time
pid=int(sys.argv[1]);result=pathlib.Path(sys.argv[2]);observations=[];started=time.monotonic()
for sample in range(37):
 p=subprocess.run(['/bin/ps','-p',str(pid),'-o','rss=,%cpu='],capture_output=True,text=True)
 values=p.stdout.split()
 all_processes=subprocess.run(['/bin/ps','-axo','rss=,comm='],capture_output=True,text=True)
 webkit=[]
 for line in all_processes.stdout.splitlines():
  parts=line.strip().split(None,1)
  if len(parts)==2 and ('WebKit' in parts[1] or 'WebContent' in parts[1]):
   try:webkit.append(int(parts[0]))
   except ValueError:pass
 observation={'elapsedSeconds':time.monotonic()-started,'hostRSSKiB':int(values[0]) if len(values)>=2 else None,'hostPSAverageCPUPercent':float(values[1]) if len(values)>=2 else None,'allWebKitProcessesRSSKiBUpperBound':sum(webkit),'allWebKitProcessCount':len(webkit)}
 observations.append(observation)
 pathlib.Path(sys.argv[3]).write_text(json.dumps({'scope':'Host RSS plus an upper-bound sum of every running WebKit process. Engine ownership cannot be established. ps CPU is a cumulative process average, not a full energy measurement.','samples':observations},indent=2,sort_keys=True)+'\n')
 print('Idle observation:',int(observation['elapsedSeconds']),'seconds; host RSS',observation['hostRSSKiB'],'KiB',flush=True)
 if result.exists():break
 if p.returncode!=0:break
 time.sleep(20)
PY
wait "$IDLE_PID"
IDLE_PID=""
cp "$RESULTS/performance-idle-$RUN_ID-idle.json" "$EVIDENCE/"
if [[ -f "$RESULTS/idle-ready-$RUN_ID-idle.json" ]]; then cp "$RESULTS/idle-ready-$RUN_ID-idle.json" "$EVIDENCE/"; fi
python3 - "$EVIDENCE" "$RUN_ID" <<'PY'
import json,math,pathlib,statistics,sys
root=pathlib.Path(sys.argv[1]);samples=[json.loads(p.read_text()) for p in sorted(root.glob('performance-sample-*.json'))]
metrics={}
targets={'engineFirstViewReadyMs':2000,'warmEmptyViewConstructorMs':500,'localPageDOMReadyMs':1500}
for name in ('engineFirstViewReadyMs','processEntryToReadyMs','warmEmptyViewConstructorMs','localPageDOMReadyMs','localPageNativeLoadMs'):
 values=[float(x['metrics'][name]) for x in samples if x['status']=='observed' and isinstance(x['metrics'].get(name),(float,int))]
 ordered=sorted(values)
 entry={'sampleCount':len(values),'medianMs':statistics.median(values) if values else None,'p95Ms':ordered[math.ceil(len(values)*.95)-1] if values else None,'varianceMsSquared':statistics.variance(values) if len(values)>1 else None}
 if name in targets:entry.update({'approvedTargetMs':targets[name],'numericThresholdMet':len(values)==30 and entry['p95Ms']<=targets[name]})
 metrics[name]=entry
idle=json.loads(next(root.glob('performance-idle-*.json')).read_text())
public=json.loads(next(root.glob('public-sites-results-*.json')).read_text())
result={'mode':'phase3-measurements','runID':sys.argv[2],'status':'partially_verified','metrics':metrics,'exactOneMBResponseConfirmed':len(samples)==30 and all(x['metrics'].get('encodedBodyBytes')==1048576 for x in samples),'tenIdleViews':idle,'aggregateRSSGate':'blocked: no reliable app-to-WebKit-process attribution; host-only and all-WebKit upper-bound values retained separately','crashRecoveryTiming':'blocked: safe WebContent process attribution unavailable','publicSiteLoadedCount':sum(x['status']=='loaded' for x in public['observations']),'publicSiteAttemptCount':len(public['observations']),'accountWorkflows':'blocked by user direction: public pages only','coldLaunch':'Not measured from OS launch request; process-main-entry timing is reported separately.','limitations':['Existing interactive session, other apps active; hidden windows; no OS cache flush','First-view ready includes WebKit initialization and first view; warm constructor excludes asynchronous renderer readiness','No conferencing room, peak conference memory, 30-minute authenticated workflow, or full energy observation','No aggregate host-plus-attributed-engine RSS acceptance claim']}
(root/'measurement-summary.json').write_text(json.dumps(result,indent=2,sort_keys=True)+'\n')
print('Measurement evidence:',root)
print('Public pages loaded:',result['publicSiteLoadedCount'],'/',result['publicSiteAttemptCount'])
for key,value in metrics.items():print(key,value)
PY
