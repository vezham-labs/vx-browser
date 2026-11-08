#!/usr/bin/env python3
"""Finite, isolated native validation runner. Never launches or edits the product."""
from pathlib import Path
import datetime,hashlib,importlib.util,json,os,plistlib,subprocess,sys,threading

RUN=Path(__file__).resolve().parent.parent
OUT=RUN/'results'
OUT.mkdir(exist_ok=True)
WORK=Path('/private/tmp/vx-m1-native-20261108T094414Z')
APP=WORK/'VXM1Validation.app'
BIN=APP/'Contents/MacOS/VXM1Validation'
def now(): return datetime.datetime.now(datetime.timezone.utc).isoformat()
records=[]
def command(label,args,timeout=60):
    start=now()
    try:
        p=subprocess.run(args,text=True,capture_output=True,timeout=timeout)
        result={'started_at':start,'ended_at':now(),'command':args,'returncode':p.returncode,'stdout':p.stdout,'stderr':p.stderr}
    except (subprocess.TimeoutExpired,OSError) as e:
        result={'started_at':start,'ended_at':now(),'command':args,'error':str(e),'returncode':None}
    (OUT/(label+'.json')).write_text(json.dumps(result,indent=2)+'\n')
    records.append({'label':label,'returncode':result['returncode'],'error':result.get('error')})
    return result
def finish(status,reason):
    (OUT/'native-run-summary.json').write_text(json.dumps({'status':status,'reason':reason,'records':records,'ended_at':now(),'product_qualification':False,'macos26_qualification':False},indent=2)+'\n')
    print(json.dumps({'status':status,'reason':reason,'records':records}))

WORK.mkdir(exist_ok=True);BIN.parent.mkdir(parents=True,exist_ok=True)
info={'CFBundleExecutable':'VXM1Validation','CFBundleIdentifier':'internal.vx.M1Validation.run20261108T094414Z','CFBundleName':'VX M1 disposable validation','CFBundlePackageType':'APPL','CFBundleVersion':'1','CFBundleShortVersionString':'0.1','LSMinimumSystemVersion':'26.0','NSPrincipalClass':'NSApplication','NSAppTransportSecurity':{'NSAllowsLocalNetworking':True}}
(APP/'Contents/Info.plist').write_bytes(plistlib.dumps(info))
ent=WORK/'entitlements.plist'
ent.write_bytes(plistlib.dumps({'com.apple.security.app-sandbox':True,'com.apple.security.network.client':True}))
if '--run-built' not in sys.argv:
    build=command('native-build',['xcrun','swiftc','-parse-as-library','-swift-version','6','-target','arm64-apple-macosx26.0','-module-cache-path',str(WORK/'module-cache'),'-framework','AppKit','-framework','WebKit',str(RUN/'harness/NativeProbe.swift'),'-o',str(BIN)],120)
    if build['returncode']!=0: finish('BLOCKED','Validation harness compilation failed; no website procedure ran.');sys.exit(0)
    sign=command('native-adhoc-debug-sign',['codesign','--force','--sign','-','--options','runtime','--entitlements',str(ent),str(APP)])
    verify=command('native-static-signature-check',['codesign','--verify','--strict','--verbose=2',str(APP)])
    if sign['returncode']!=0 or verify['returncode']!=0: finish('BLOCKED','Disposable debug harness signature prerequisite failed.');sys.exit(0)
    (OUT/'native-binary-provenance.json').write_text(json.dumps({'sha256':hashlib.sha256(BIN.read_bytes()).hexdigest(),'bundle_identifier':info['CFBundleIdentifier'],'entitlements':plistlib.loads(ent.read_bytes()),'release_signing':False},indent=2)+'\n')
else:
    provenance=json.loads((OUT/'native-binary-provenance.json').read_text())
    if not BIN.is_file() or hashlib.sha256(BIN.read_bytes()).hexdigest()!=provenance['sha256']:
        finish('BLOCKED','Built disposable binary no longer matches retained provenance.');sys.exit(0)
if '--build-only' in sys.argv: finish('NOT RUN','Build-only prerequisite check; native procedures not launched.');sys.exit(0)
spec=importlib.util.spec_from_file_location('fixture_server',RUN/'harness/fixture_server.py')
module=importlib.util.module_from_spec(spec);spec.loader.exec_module(module)
servers=[]
try:
    for _ in range(2):
        server=module.ThreadingHTTPServer(('127.0.0.1',0),module.Handler)
        servers.append(server);threading.Thread(target=server.serve_forever,daemon=True).start()
except OSError as e:
    for server in servers:server.server_close()
    finish('BLOCKED','Owned loopback fixture unavailable: '+str(e));sys.exit(0)
fixtures=json.loads((RUN/'fixtures.json').read_text())
urls=['http://127.0.0.1:'+str(s.server_port)+'/' for s in servers]
(OUT/'loopback-fixture.json').write_text(json.dumps({'origins':urls,'ownership':'synthetic loopback only; no external accounts'},indent=2)+'\n')
try:
    for stage in ['seed','verify']:
        result=command('native-'+stage,[str(BIN),stage,fixtures['storeA'],fixtures['storeB'],*urls,'run20261108T094414Z'],60)
        parsed=[]
        for line in result.get('stdout','').splitlines():
            if line.startswith('VX_RESULT '):parsed.append(json.loads(line[len('VX_RESULT '):]))
        (OUT/('native-'+stage+'-observations.json')).write_text(json.dumps({'results':parsed,'launch_returncode':result['returncode']},indent=2)+'\n')
        if result['returncode']!=0 or not parsed:
            finish('BLOCKED','Native launch did not complete diagnostic procedure at '+stage+'; no acceptance claimed.');break
        if any(x.get('error') for x in parsed):
            finish('INCONCLUSIVE','Native procedure reported an error at '+stage+'; retain observations and cleanup requirements.');break
        if any(not c['passed'] for x in parsed for c in x['checks']):
            finish('FAIL','At least one defined native subset observation failed.');break
    else:finish('INCONCLUSIVE','Defined native subset observations completed; full EXP-01/02 criteria include uncovered product/lifecycle cases.')
finally:
    for server in servers:server.shutdown();server.server_close()
