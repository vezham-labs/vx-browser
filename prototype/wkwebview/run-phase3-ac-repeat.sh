#!/bin/bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")" && pwd)"
SOURCE_APP="${1:?Pass the already-built measurement app}"
PRIOR_EVIDENCE="${2:?Pass the prior measurement evidence directory}"
TEMP_BUILD="$(mktemp -d "${TMPDIR:-/private/tmp}/wkwebview-acrepeat.XXXXXX")"
SERVER_PID=""
cleanup() {
  if [[ -n "$SERVER_PID" ]]; then kill "$SERVER_PID" 2>/dev/null || true; wait "$SERVER_PID" 2>/dev/null || true; fi
  rm -rf "$TEMP_BUILD"
}
trap cleanup EXIT
codesign --verify --strict "$SOURCE_APP"
ditto "$SOURCE_APP" "$TEMP_BUILD/VezhamWKPrototype.app"
codesign --verify --strict "$TEMP_BUILD/VezhamWKPrototype.app"
BUNDLE_ID="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleIdentifier' "$TEMP_BUILD/VezhamWKPrototype.app/Contents/Info.plist")"
if [[ "$BUNDLE_ID" != internal.vezham.WKPrototype.Measurements.* ]]; then echo "Expected an isolated measurement identity" >&2; exit 1; fi
RUN_ID="$(date -u +%Y%m%dT%H%M%SZ)-$$-AC"
EVIDENCE="$ROOT/Evidence/measurements-$RUN_ID"
RESULTS="$HOME/Library/Containers/$BUNDLE_ID/Data/Library/Application Support/WKPrototype"
mkdir -p "$EVIDENCE"
echo "Prepared AC timing repeat: $RUN_ID; waiting for the idle observation to finish."
for _ in $(seq 1 900); do
  if [[ -f "$PRIOR_EVIDENCE/measurement-summary.json" ]]; then break; fi
  sleep 1
done
if [[ ! -f "$PRIOR_EVIDENCE/measurement-summary.json" ]]; then echo "Prior idle run did not finish; timing repeat not started" >&2; exit 1; fi
for _ in $(seq 1 100); do
  if ! curl --max-time 1 --silent --fail 'http://127.0.0.1:18765/state' --output /dev/null; then break; fi
  sleep 0.1
done
/usr/bin/pmset -g batt > "$EVIDENCE/power-start.txt"
if ! rg -q "AC Power" "$EVIDENCE/power-start.txt"; then echo "External power not detected; repeat not started" >&2; exit 1; fi
python3 "$ROOT/Fixtures/phase3_server.py" >"$TEMP_BUILD/server.log" 2>&1 &
SERVER_PID=$!
for _ in $(seq 1 50); do
  if ! kill -0 "$SERVER_PID" 2>/dev/null; then cat "$TEMP_BUILD/server.log" >&2; exit 1; fi
  if curl --max-time 2 --silent --fail 'http://127.0.0.1:18765/state' --output /dev/null; then break; fi
  sleep 0.1
done
for i in $(seq 1 30); do
  "$TEMP_BUILD/VezhamWKPrototype.app/Contents/MacOS/VezhamWKPrototype" --test-performance-sample --test-run-id "$RUN_ID-sample-$i" >"$TEMP_BUILD/sample.log" 2>&1
  cp "$RESULTS/performance-sample-$RUN_ID-sample-$i.json" "$EVIDENCE/"
  if (( i % 5 == 0 )); then echo "AC timing samples collected: $i/30"; fi
done
/usr/bin/pmset -g batt > "$EVIDENCE/power-end.txt"
python3 - "$EVIDENCE" "$RUN_ID" <<'PY'
import json,math,pathlib,statistics,sys
root=pathlib.Path(sys.argv[1]);records=[json.loads(f.read_text()) for f in root.glob('performance-sample-*.json')]
metrics={};targets={'engineFirstViewReadyMs':2000,'warmEmptyViewConstructorMs':500,'localPageDOMReadyMs':1500}
for name in ('engineFirstViewReadyMs','processEntryToReadyMs','warmEmptyViewConstructorMs','localPageDOMReadyMs','localPageNativeLoadMs'):
 values=sorted(float(x['metrics'][name]) for x in records if x['status']=='observed' and isinstance(x['metrics'].get(name),(int,float)))
 r={'sampleCount':len(values),'medianMs':statistics.median(values) if values else None,'p95Ms':values[math.ceil(.95*len(values))-1] if values else None,'varianceMsSquared':statistics.variance(values) if len(values)>1 else None}
 if name in targets:r.update({'approvedTargetMs':targets[name],'numericThresholdMet':len(values)==30 and r['p95Ms']<=targets[name]})
 metrics[name]=r
result={'mode':'AC-timing-repeat','runID':sys.argv[2],'status':'observed','metrics':metrics,'exactOneMBResponseConfirmed':len(records)==30 and all(x['metrics'].get('encodedBodyBytes')==1048576 for x in records),'externalPowerConfirmedAtStartAndEnd':all('AC Power' in (root/name).read_text() for name in ('power-start.txt','power-end.txt')),'limitations':['Hidden-window timing proxies; warm empty-view measurement is constructor time, not asynchronous renderer-ready time','Existing interactive host with other apps active; caches not flushed','No aggregate attributable-engine RSS, true OS cold-launch, full energy, or crash-recovery timing acceptance claim']}
(root/'AC-measurement-summary.json').write_text(json.dumps(result,indent=2,sort_keys=True)+'\n')
print('AC evidence:',root)
for key,value in metrics.items():print(key,value)
PY
