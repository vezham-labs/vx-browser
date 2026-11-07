#!/usr/bin/env python3
"""Host-only Phase 3 diagnostics. No private APIs are imported by the app.

Uses process_metadata.py's read-only Darwin diagnostic ABI, validated with two
simultaneous isolated hosts. Refuses ambiguous/missing identities before signals.
"""
import argparse, datetime, hashlib, json, math, os, pathlib, shutil, signal, subprocess
import tempfile, threading, time
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from process_metadata import metadata, snapshot

parser=argparse.ArgumentParser()
parser.add_argument('--resume-crash-evidence',type=pathlib.Path)
args=parser.parse_args()
TASK=pathlib.Path(__file__).resolve().parents[1]
PROJECT=TASK.parent/'https-chatgpt-com-share-6aee2c10-10e8'
ROOT=PROJECT/'prototype/wkwebview'
RUN=datetime.datetime.now(datetime.timezone.utc).strftime('%Y%m%dT%H%M%SZ')+'-'+str(os.getpid())
EVIDENCE=ROOT/'Evidence'/('attributed-checks-'+RUN)
EVIDENCE.mkdir(parents=True)
TEMP=pathlib.Path(tempfile.mkdtemp(prefix='attributed-checks.',dir=TASK/'work'))
BUNDLE='internal.vezham.WKPrototype.Diagnostics.'+str(int(time.time()))+'.'+str(os.getpid())
APP=TEMP/'build/VezhamWKPrototype.app'
EXECUTABLE=str(APP/'Contents/MacOS/VezhamWKPrototype')
RESULTS=pathlib.Path.home()/'Library/Containers'/BUNDLE/'Data/Library/Application Support/WKPrototype'
CRASH_PAYLOAD=b"<!doctype html><meta charset='utf-8'><title>WK Recovery Fixture</title><h1>Local recovery page</h1>"
PREFIX=b'<!doctype html><meta charset=utf-8><title>Phase 3 1 MB fixture</title><main>'
MEMORY_PAYLOAD=PREFIX+b'x'*(1048576-len(PREFIX)-len(b'</main>'))+b'</main>'
VALIDATION=json.loads((TASK/'work/process-attribution-current.json').read_text())
VALIDATION_FILE=pathlib.Path(VALIDATION['evidenceDirectory'])/'two-host-attribution-validation.json'
assert json.loads(VALIDATION_FILE.read_text())['status']=='validated-on-current-host'
shutil.copy2(VALIDATION_FILE,EVIDENCE/'two-host-attribution-validation.json')

shutil.copy2(pathlib.Path(__file__),EVIDENCE/'host-runner-executed.py')
shutil.copy2(pathlib.Path(__file__).with_name('process_metadata.py'),EVIDENCE/'process_metadata.py')

def write(name,value):
    (EVIDENCE/name).write_text(json.dumps(value,indent=2,sort_keys=True)+'\n')

def power(name):
    value=subprocess.run(['/usr/bin/pmset','-g','batt'],capture_output=True,text=True,check=True).stdout
    (EVIDENCE/name).write_text(value)
    return 'AC Power' in value

def identity_matches(a,b):
    keys=['pid','uniqueID','executablePath','resourceCoalitionID','jetsamCoalitionID']
    return all(a.get(k) is not None and a[k]==b.get(k) for k in keys)

def host_identity(pid):
    value=metadata(pid)
    assert value['executablePath']==EXECUTABLE,'Host executable mismatch'
    assert value['uniqueID'] and value['resourceCoalitionID'] and value['jetsamCoalitionID'],'Missing host identity'
    return value

def own_rows(host):
    current=snapshot(host['pid'])
    assert identity_matches(host,current['host']),'Host identity changed'
    selected=[]
    for row in current['processes']:
        if (row['resourceCoalitionID'],row['jetsamCoalitionID']) != (host['resourceCoalitionID'],host['jetsamCoalitionID']):continue
        assert row['uid']==os.getuid(),'Unexpected process owner'
        path=row['executablePath'] or ''
        if row['pid']!=host['pid']:
            roots=('/System/Library/Frameworks/WebKit.framework/','/System/Volumes/Preboot/Cryptexes/OS/System/Library/Frameworks/WebKit.framework/')
            assert path.startswith(roots) and '.xpc/Contents/MacOS/com.apple.WebKit.' in path,'Unexpected coalition executable'
        assert row['uniqueID'],'Missing process unique ID'
        selected.append(row)
    assert any(r['pid']==host['pid'] for r in selected),'Host absent from snapshot'
    return selected

def wait_json(path,waiter,timeout=42):
    deadline=time.monotonic()+timeout
    while time.monotonic()<deadline:
        if path.exists():return json.loads(path.read_text())
        if waiter.poll() is not None:raise RuntimeError('App exited before '+path.name)
        time.sleep(.02)
    raise TimeoutError(path.name)

class Fixture(BaseHTTPRequestHandler):
    def do_GET(self):
        body=CRASH_PAYLOAD if self.path=='/crash-fixture' else MEMORY_PAYLOAD if self.path=='/benchmark-page' else None
        if body is None:self.send_error(404);return
        self.send_response(200);self.send_header('Content-Type','text/html; charset=utf-8');self.send_header('Content-Length',str(len(body)));self.send_header('Cache-Control','no-store');self.end_headers();self.wfile.write(body)
    def log_message(self,*args):pass

summary={'runID':RUN,'bundleIdentifier':BUNDLE,'method':'Host-specific private Darwin coalition/unique-ID diagnostics outside app source; exact path, owner and identity checks. Active desktop; hidden AppKit windows; OS caches untouched.','sources':json.loads(VALIDATION_FILE.read_text())['sources'],'sourceSHA256':{f.name:hashlib.sha256(f.read_bytes()).hexdigest() for f in (ROOT/'Sources').glob('*.swift')},'security':'Normal App Sandbox/network-client/user-selected-file entitlements and Hardened Runtime; no debug/media entitlements. No root or security relaxation.'}
write('session.json',{'runID':RUN,'evidenceDirectory':str(EVIDENCE),'temporaryDirectory':str(TEMP),'appPath':str(APP),'bundleIdentifier':BUNDLE,'resultsDirectory':str(RESULTS)})
(TASK/'work/attributed-checks-current.json').write_text((EVIDENCE/'session.json').read_text())
server=None;waiter=None;host=None;all_crashes=[];memory_samples=[]
try:
    assert power('power-start.txt'),'AC power required'
    with (EVIDENCE/'build.log').open('w') as log:
        subprocess.run(['/bin/bash',str(ROOT/'build.sh')],env={**os.environ,'WK_BUILD_DIR':str(TEMP/'build'),'WK_BUNDLE_ID':BUNDLE},stdout=log,stderr=log,check=True)
    # Preserve only the normal signature/entitlement audit, never environment dumps.
    audit=subprocess.run(['/usr/bin/codesign','-d','--entitlements',':-',str(APP)],capture_output=True,text=True,check=True)
    (EVIDENCE/'signed-entitlements.plist').write_text(audit.stdout)
    bind_deadline=time.monotonic()+60
    while True:
        try:server=ThreadingHTTPServer(('127.0.0.1',18765),Fixture);break
        except OSError:
            if time.monotonic()>bind_deadline:raise RuntimeError('Loopback fixture port in use; no existing server was stopped')
            time.sleep(.25)
    threading.Thread(target=server.serve_forever,daemon=True).start()
    if args.resume_crash_evidence:
        previous=json.loads((args.resume_crash_evidence/'attributed-checks-summary.json').read_text())
        assert previous['sourceSHA256']==summary['sourceSHA256'],'Resume evidence source mismatch'
        assert previous['crashRecovery']['samples']==30
        for i in range(1,31):
            result=json.loads((args.resume_crash_evidence/('crash-result-'+str(i)+'.json')).read_text())
            guard=json.loads((args.resume_crash_evidence/('crash-guard-'+str(i)+'.json')).read_text())
            assert result['status']=='passed' and result['failureCount']==0 and len(result['tests'])==7 and all(t['passed'] for t in result['tests'])
            assert guard['guardPassed'] and guard['host']['resourceCoalitionID']==guard['target']['resourceCoalitionID'] and guard['host']['jetsamCoalitionID']==guard['target']['jetsamCoalitionID']
            all_crashes.append(result)
            for prefix in ['crash-result-','crash-guard-']:shutil.copy2(args.resume_crash_evidence/(prefix+str(i)+'.json'),EVIDENCE/(prefix+str(i)+'.json'))
        summary['crashSourceRunID']=previous['runID']
        summary['crashEvidenceProvenance']='Copied without changing raw sample run IDs after the first idle observation was interrupted to allow timer coalescing. Native source hashes match.'
        print('Reused 30 verified crash samples from',previous['runID'],flush=True)
    for i in ([] if args.resume_crash_evidence else range(1,31)):
        sample=RUN+'-crash-'+str(i)
        waiter=subprocess.Popen(['/usr/bin/open','-n','-W','-a',str(APP),'--args','--test-crash-recovery','--test-run-id',sample],stdout=subprocess.DEVNULL,stderr=subprocess.DEVNULL)
        ready=wait_json(RESULTS/('crash-ready-'+sample+'.json'),waiter)
        host=host_identity(ready['hostProcessIdentifier']);rows=own_rows(host)
        contents=[r for r in rows if r['executablePath'].endswith('/com.apple.WebKit.WebContent.xpc/Contents/MacOS/com.apple.WebKit.WebContent')]
        assert len(contents)==1,'Ambiguous content process: no signal sent'
        target=contents[0]
        host_recheck=metadata(host['pid']);target_recheck=metadata(target['pid'])
        assert identity_matches(host,host_recheck) and identity_matches(target,target_recheck),'Identity changed: no signal sent'
        assert target['pid']!=host['pid'] and target['resourceCoalitionID']==host['resourceCoalitionID'] and target['jetsamCoalitionID']==host['jetsamCoalitionID']
        guard={'sample':i,'host':host_recheck,'target':target_recheck,'selectedGroup':rows,'guardPassed':True}
        write('crash-guard-'+str(i)+'.json',guard)
        # Recheck after writing evidence, immediately before the one targeted signal.
        assert identity_matches(host,metadata(host['pid'])) and identity_matches(target,metadata(target['pid'])),'Identity changed before signal'
        begin=time.perf_counter_ns();os.kill(target['pid'],signal.SIGKILL)
        result=wait_json(RESULTS/('crash-recovery-results-'+sample+'.json'),waiter)
        elapsed=(time.perf_counter_ns()-begin)/1e6
        result['signalToResultObservedUpperBoundMs']=elapsed
        result['pollIntervalMs']=20
        result['guardEvidence']='crash-guard-'+str(i)+'.json'
        write('crash-result-'+str(i)+'.json',result)
        all_crashes.append(result)
        waiter.wait(timeout=15);waiter=None;host=None
        assert result['status']=='passed' and result['failureCount']==0,'Recovery fixture failed'
        if i%5==0:print('Crash recovery:',i,'/30 passed; latest signal-to-result',round(elapsed,2),'ms',flush=True)
    times=sorted(r['signalToResultObservedUpperBoundMs'] for r in all_crashes)
    callback=sorted(r['callbackToDOMReadyMs'] for r in all_crashes)
    summary['crashRecovery']={'status':'passed for bounded single-view harness','samples':30,'checksPerSample':len(all_crashes[0]['tests']),'signalToResultObservedUpperBoundMs':{'median':(times[14]+times[15])/2,'p95':times[math.ceil(.95*len(times))-1],'maximum':max(times)},'callbackToDOMReadyMs':{'median':(callback[14]+callback[15])/2,'p95':callback[math.ceil(.95*len(callback))-1],'maximum':max(callback)},'approvedTargetMs':2000,'numericThresholdMet':times[math.ceil(.95*len(times))-1]<=2000,'limitations':'Single hidden private fixture, automatic reload. Does not validate visible recovery UI, multi-view/stale callbacks, user recovery choice, host/GPU/network-process crashes, or durable product state.'}
    write('attributed-checks-summary.json',summary)
    assert power('power-before-memory.txt'),'AC power required'
    sample=RUN+'-idle'
    waiter=subprocess.Popen(['/usr/bin/open','-n','-W','-a',str(APP),'--args','--test-ten-idle-views','--test-run-id',sample,'--test-idle-report-grace-seconds','60'],stdout=subprocess.DEVNULL,stderr=subprocess.DEVNULL)
    ready=wait_json(RESULTS/('idle-ready-'+sample+'.json'),waiter)
    write('idle-ready.json',ready);assert ready['viewCount']==10
    host=host_identity(ready['hostPID']);rows=own_rows(host)
    assert sum('WebContent.xpc/Contents/MacOS' in r['executablePath'] for r in rows)==10
    identities={r['pid']:r for r in rows}
    write('memory-initial-group.json',{'host':host,'rows':rows})
    begin=time.monotonic();next_progress=60
    print('Memory: ten fixture views ready; waiting 600 seconds before 30 one-second samples.',flush=True)
    while time.monotonic()-begin<600:
        elapsed=time.monotonic()-begin
        if waiter.poll() is not None:raise RuntimeError('Idle app exited early')
        if elapsed>=next_progress:
            print('Memory idle elapsed:',int(elapsed),'seconds',flush=True);next_progress+=60
        time.sleep(.25)
    native=wait_json(RESULTS/('performance-idle-'+sample+'.json'),waiter,timeout=65)
    assert native['status']=='observed' and native['idleSeconds']>=600 and native['loadedViewCount']==10
    write('performance-idle.json',native)
    for i in range(30):
        tick=time.monotonic();rows=own_rows(host)
        assert set(r['pid'] for r in rows)==set(identities),'Engine membership changed during idle observation'
        assert all(identity_matches(identities[r['pid']],r) for r in rows),'Engine identity changed'
        total=sum(r['rssKiB'] for r in rows)*1024
        memory_samples.append({'sample':i+1,'secondsSinceReadyObserved':time.monotonic()-begin,'hostPlusEngineRSSBytes':total,'hostRSSBytes':next(r['rssKiB']*1024 for r in rows if r['pid']==host['pid']),'rows':rows})
        time.sleep(max(0,1-(time.monotonic()-tick)))
    write('memory-samples.json',memory_samples)
    (EVIDENCE/'system-vm-stat-after-sampling.txt').write_text(subprocess.run(['/usr/bin/vm_stat'],capture_output=True,text=True,check=True).stdout)
    end_power=power('power-end.txt')
    rss=sorted(r['hostPlusEngineRSSBytes'] for r in memory_samples)
    summary['tenIdleViewsMemory']={'status':'observed','sampleCount':30,'sampleIntervalSeconds':1,'nativeIdleSeconds':native['idleSeconds'],'loadedViewCount':10,'engineProcessCount':len(identities)-1,'RSSBytes':{'median':(rss[14]+rss[15])/2,'p95':rss[math.ceil(.95*len(rss))-1],'maximum':max(rss)},'approvedTargetBytes':1500000000,'numericThresholdMet':max(rss)<=1500000000,'ACPowerConfirmedAtStartAndEnd':end_power,'limitations':'RSS only, not physical footprint/compressed-memory accounting. Hidden windows and active desktop; no true cold-cache, energy or conferencing acceptance. One 10-minute run; 30 sequential samples are not 30 independent runs.'}
    summary['status']='completed bounded diagnostics'
    write('attributed-checks-summary.json',summary)
    print(json.dumps({k:v for k,v in summary.items() if k in ['crashRecovery','tenIdleViewsMemory','status']},indent=2),flush=True)
    waiter.wait(timeout=40);waiter=None;host=None
except BaseException as error:
    summary['status']='failed or blocked';summary['error']=str(error);summary['completedCrashSamples']=len(all_crashes)
    if memory_samples:write('memory-samples-partial.json',memory_samples)
    write('attributed-checks-summary.json',summary)
    raise
finally:
    if host is not None and identity_matches(host,metadata(host['pid'])):
        os.kill(host['pid'],signal.SIGTERM)
    if waiter is not None:
        try:waiter.wait(timeout=10)
        except subprocess.TimeoutExpired:pass
    if server is not None:server.shutdown();server.server_close()
    shutil.rmtree(TEMP)
    write('cleanup.json',{'temporaryBuildRemoved':not TEMP.exists(),'fixtureServerClosed':True,'onlyIdentifiedDisposableHostSignalledDuringCleanup':host is not None,'noMediaAccessRequested':True})
