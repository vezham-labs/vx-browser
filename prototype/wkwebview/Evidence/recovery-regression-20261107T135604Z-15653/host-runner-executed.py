import datetime,hashlib,json,os,pathlib,shutil,subprocess,tempfile,time,urllib.request
TASK=pathlib.Path(__file__).resolve().parents[1];ROOT=TASK.parent/'https-chatgpt-com-share-6aee2c10-10e8/prototype/wkwebview'
RUN=datetime.datetime.now(datetime.timezone.utc).strftime('%Y%m%dT%H%M%SZ')+'-'+str(os.getpid());E=ROOT/'Evidence'/('recovery-regression-'+RUN);E.mkdir()
TEMP=pathlib.Path(tempfile.mkdtemp(prefix='recovery-regression.',dir=TASK/'work'));BUNDLE='internal.vezham.WKPrototype.RecoveryRegression.'+str(int(time.time()))+'.'+str(os.getpid());APP=TEMP/'build/VezhamWKPrototype.app'
RESULTS=pathlib.Path.home()/'Library/Containers'/BUNDLE/'Data/Library/Application Support/WKPrototype'
info={'runID':RUN,'evidenceDirectory':str(E),'bundleIdentifier':BUNDLE,'resultsDirectory':str(RESULTS)};(TASK/'work/recovery-regression-current.json').write_text(json.dumps(info,indent=2)+'\n');(E/'session.json').write_text(json.dumps(info,indent=2)+'\n');shutil.copy2(__file__,E/'host-runner-executed.py')
(E/'source-hashes.json').write_text(json.dumps({f.name:hashlib.sha256(f.read_bytes()).hexdigest() for f in (ROOT/'Sources').glob('*.swift')},indent=2)+'\n')
server=None
try:
 with (E/'build.log').open('w') as log:subprocess.run(['/bin/bash',str(ROOT/'build.sh')],env={**os.environ,'WK_BUILD_DIR':str(TEMP/'build'),'WK_BUNDLE_ID':BUNDLE},stdout=log,stderr=log,check=True)
 server_log=(E/'fixture.log').open('w');server=subprocess.Popen(['python3',str(ROOT/'Fixtures/server.py')],stdout=server_log,stderr=server_log)
 for _ in range(50):
  assert server.poll() is None,'Fixture server exited'
  try:
   with urllib.request.urlopen('http://127.0.0.1:18765/fixture?profile=a&mode=verify',timeout=2) as r:assert r.status==200
   break
  except OSError:time.sleep(.1)
 summaries=[]
 for flag,name,expected in [('--test-seed','isolation-results-'+RUN+'-seed.json',12),('--test-verify','isolation-results-'+RUN+'-verify.json',6),('--test-private-windows','window-lifecycle-results-'+RUN+'.json',3),('--test-find-zoom','find-zoom-results-'+RUN+'.json',14)]:
  subprocess.run(['/usr/bin/open','-n','-W','-a',str(APP),'--args',flag,'--test-run-id',RUN],check=True,timeout=90)
  value=json.loads((RESULTS/name).read_text());assert value['status']=='passed' and value['failureCount']==0 and len(value['tests'])==expected
  shutil.copy2(RESULTS/name,E/name);summaries.append({'mode':flag,'passedChecks':len(value['tests']),'result':name});print(flag,expected,'checks passed',flush=True)
 # Foundation URL policy in the same 26.0 deployment target, separate result path.
 sdk=subprocess.run(['xcrun','--show-sdk-path'],capture_output=True,text=True,check=True).stdout.strip()
 subprocess.run(['swiftc','-sdk',sdk,'-target','arm64-apple-macosx26.0','-module-cache-path',str(TEMP/'policy-cache'),'-parse-as-library','-o',str(TEMP/'policy-tests'),str(ROOT/'Sources/NavigationPolicy.swift'),str(ROOT/'Tests/NavigationPolicyTests.swift')],check=True)
 value=json.loads(subprocess.run([str(TEMP/'policy-tests')],capture_output=True,text=True,check=True).stdout);assert value['status']=='passed' and value['failureCount']==0 and len(value['tests'])==13
 (E/'url-policy-results.json').write_text(json.dumps(value,indent=2)+'\n');summaries.append({'mode':'URL policy','passedChecks':13,'result':'url-policy-results.json'})
 (E/'regression-summary.json').write_text(json.dumps({'status':'passed','runID':RUN,'suites':summaries,'totalPassedChecks':sum(s['passedChecks'] for s in summaries),'method':'One isolated normal-entitlement build; sequential fresh LaunchServices processes; loopback only. Foundation URL policy is a separate executable.','sourceHashes':'source-hashes.json'},indent=2)+'\n');print('Regression passed',sum(s['passedChecks'] for s in summaries),'checks',flush=True)
finally:
 if server:server.terminate();server.wait(timeout=10)
 shutil.rmtree(TEMP)
 (E/'cleanup.json').write_text(json.dumps({'temporaryBuildRemoved':not TEMP.exists(),'fixtureServerClosed':True},indent=2)+'\n')
