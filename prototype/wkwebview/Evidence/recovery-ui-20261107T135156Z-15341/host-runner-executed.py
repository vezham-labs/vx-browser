import datetime,hashlib,json,os,pathlib,shutil,signal,subprocess,tempfile,threading,time
from http.server import BaseHTTPRequestHandler,ThreadingHTTPServer
from process_metadata import metadata,snapshot
TASK=pathlib.Path(__file__).resolve().parents[1]
ROOT=TASK.parent/'https-chatgpt-com-share-6aee2c10-10e8/prototype/wkwebview'
RUN=datetime.datetime.now(datetime.timezone.utc).strftime('%Y%m%dT%H%M%SZ')+'-'+str(os.getpid())
E=ROOT/'Evidence'/('recovery-ui-'+RUN);E.mkdir()
TEMP=pathlib.Path(tempfile.mkdtemp(prefix='recovery-ui.',dir=TASK/'work'))
BUNDLE='internal.vezham.WKPrototype.RecoveryUI.'+str(int(time.time()))+'.'+str(os.getpid())
APP=TEMP/'build/VezhamWKPrototype.app';EXEC=str(APP/'Contents/MacOS/VezhamWKPrototype')
RESULTS=pathlib.Path.home()/'Library/Containers'/BUNDLE/'Data/Library/Application Support/WKPrototype'
STATE=RESULTS/('recovery-ui-state-'+RUN+'.json');RESULT=RESULTS/('recovery-ui-results-'+RUN+'.json')
info={'runID':RUN,'evidenceDirectory':str(E),'temporaryDirectory':str(TEMP),'appPath':str(APP),'bundleIdentifier':BUNDLE,'resultsDirectory':str(RESULTS),'statePath':str(STATE),'resultPath':str(RESULT)}
(E/'session.json').write_text(json.dumps(info,indent=2)+'\n');(TASK/'work/recovery-ui-current.json').write_text(json.dumps(info,indent=2)+'\n')
(E/'source-hashes.json').write_text(json.dumps({f.name:hashlib.sha256(f.read_bytes()).hexdigest() for f in (ROOT/'Sources').glob('*.swift')},indent=2)+'\n')
shutil.copy2(__file__,E/'host-runner-executed.py');shutil.copy2(TASK/'work/process_metadata.py',E/'process_metadata.py')
validated=json.loads((TASK/'work/process-attribution-current.json').read_text());validation=pathlib.Path(validated['evidenceDirectory'])/'two-host-attribution-validation.json';assert json.loads(validation.read_text())['status']=='validated-on-current-host';shutil.copy2(validation,E/validation.name)

def same(a,b):return all(a.get(k) is not None and a[k]==b.get(k) for k in ['pid','uniqueID','executablePath','resourceCoalitionID','jetsamCoalitionID'])
def write(name,value):(E/name).write_text(json.dumps(value,indent=2,sort_keys=True)+'\n')
def group(host):
 snap=snapshot(host['pid']);assert same(host,snap['host'])
 rows=[r for r in snap['processes'] if r['resourceCoalitionID']==host['resourceCoalitionID'] and r['jetsamCoalitionID']==host['jetsamCoalitionID']]
 for r in rows:
  assert r['uid']==os.getuid() and r['uniqueID']
  if r['pid']!=host['pid']:assert r['executablePath'].startswith(('/System/Library/Frameworks/WebKit.framework/','/System/Volumes/Preboot/Cryptexes/OS/System/Library/Frameworks/WebKit.framework/')) and '.xpc/Contents/MacOS/com.apple.WebKit.' in r['executablePath']
 return rows

class Fixture(BaseHTTPRequestHandler):
 def do_GET(self):
  if not self.path.startswith('/recovery-ui?role='):self.send_error(404);return
  role=self.path.split('=')[-1]
  if role not in ['A','B','Private']:self.send_error(400);return
  body=("<!doctype html><meta charset=utf-8><title>Vezham Recovery Fixture "+role+"</title><h1>Recovery profile "+role+"</h1><p>Synthetic loopback fixture. Use the native toolbar Reload only after the recovery message appears.</p><script>window.fixtureDocumentID=crypto.randomUUID()</script>").encode()
  self.send_response(200);self.send_header('Content-Type','text/html; charset=utf-8');self.send_header('Content-Length',str(len(body)));self.send_header('Cache-Control','no-store');self.end_headers();self.wfile.write(body)
 def log_message(self,*a):pass

waiter=None;server=None;host=None;targets=[]
try:
 with (E/'build.log').open('w') as log:subprocess.run(['/bin/bash',str(ROOT/'build.sh')],env={**os.environ,'WK_BUILD_DIR':str(TEMP/'build'),'WK_BUNDLE_ID':BUNDLE},stdout=log,stderr=log,check=True)
 audit=subprocess.run(['/usr/bin/codesign','-d','--entitlements',':-',str(APP)],capture_output=True,text=True,check=True);(E/'signed-entitlements.plist').write_text(audit.stdout)
 server=ThreadingHTTPServer(('127.0.0.1',18765),Fixture);threading.Thread(target=server.serve_forever,daemon=True).start()
 waiter=subprocess.Popen(['/usr/bin/open','-n','-W','-a',str(APP),'--args','--test-recovery-ui','--test-run-id',RUN],stdout=subprocess.DEVNULL,stderr=subprocess.DEVNULL)
 deadline=time.monotonic()+290;round_sent=0;initial=[];last_phase=None
 while time.monotonic()<deadline:
  if RESULT.exists():
   result=json.loads(RESULT.read_text());write('recovery-ui-results.json',result);assert result['status']=='passed',result
   print('RECOVERY UI PASSED',len(result['tests']),'checks',flush=True);waiter.wait(timeout=15);waiter=None;host=None;break
  if waiter.poll() is not None:raise RuntimeError('App exited before native test results')
  if STATE.exists():
   state=json.loads(STATE.read_text());phase=(state['phase'],state['round'],state['affectedRole'])
   if phase!=last_phase:
    print('Native state:',json.dumps({'phase':state['phase'],'round':state['round'],'affectedRole':state['affectedRole'],'windowTitle':state['windowTitle']}),flush=True);last_phase=phase
   if state['phase']=='readyForCrash' and state['round']>round_sent:
    if host is None:
     host=metadata(state['hostPID']);assert host['executablePath']==EXEC and host['uniqueID'] and host['resourceCoalitionID'] and host['jetsamCoalitionID']
     rows=group(host);initial=[r for r in rows if r['executablePath'].endswith('/com.apple.WebKit.WebContent.xpc/Contents/MacOS/com.apple.WebKit.WebContent')];assert len(initial)==3,'Expected three isolated content helpers'
    target=next((r for r in initial if r['uniqueID'] not in [x['uniqueID'] for x in targets] and same(r,metadata(r['pid']))),None);assert target,'No remaining untested original helper'
    rows=group(host);assert any(same(r,target) for r in rows)
    write('crash-guard-'+str(state['round'])+'.json',{'host':host,'target':target,'rows':rows,'state':state,'guardPassed':True})
    assert same(host,metadata(host['pid'])) and same(target,metadata(target['pid']))
    os.kill(target['pid'],signal.SIGKILL);targets.append(target);round_sent=state['round']
   if state['phase']=='awaitingUserReload':write('awaiting-reload-'+str(state['round'])+'.json',state)
  time.sleep(.1)
 else:raise TimeoutError('UI test timed out')
except BaseException as error:
 write('runner-failure.json',{'error':str(error),'completedSignals':len(targets)})
 if RESULT.exists():shutil.copy2(RESULT,E/'recovery-ui-results.json')
 raise
finally:
 if host and same(host,metadata(host['pid'])):os.kill(host['pid'],signal.SIGTERM)
 if waiter:
  try:waiter.wait(timeout=10)
  except subprocess.TimeoutExpired:pass
 if server:server.shutdown();server.server_close()
 shutil.rmtree(TEMP)
 write('cleanup.json',{'temporaryBuildRemoved':not TEMP.exists(),'fixtureServerClosed':True,'targetedContentSignals':len(targets),'noMediaAccessRequested':True})
