#!/usr/bin/env python3
"""Cleanup-only follow-up. No rerun of completed seed/verify observations."""
from pathlib import Path
import datetime,hashlib,json,subprocess
R=Path(__file__).resolve().parent.parent
O=R/'results'
W=Path('/private/tmp/vx-m1-native-20261108T094414Z')
A=W/'VXM1Validation.app'
B=A/'Contents/MacOS/VXM1Validation'
def run(label,args):
    start=datetime.datetime.now(datetime.timezone.utc).isoformat()
    try:
        p=subprocess.run(args,text=True,capture_output=True,timeout=90)
        d={'started_at':start,'command':args,'returncode':p.returncode,'stdout':p.stdout,'stderr':p.stderr}
    except (OSError,subprocess.TimeoutExpired) as e:d={'started_at':start,'command':args,'returncode':None,'error':str(e)}
    (O/(label+'.json')).write_text(json.dumps(d,indent=2)+'\n')
    return d
cmd=['xcrun','swiftc','-parse-as-library','-swift-version','6','-target','arm64-apple-macosx26.0','-module-cache-path',str(W/'module-cache'),'-framework','AppKit','-framework','WebKit',str(R/'harness/NativeProbe.swift'),'-o',str(B)]
build=run('cleanup-only-build',cmd)
if build['returncode']!=0:raise SystemExit('cleanup-only compile failed; owned stores remain registered')
sign=run('cleanup-only-debug-sign',['codesign','--force','--sign','-','--options','runtime','--entitlements',str(W/'entitlements.plist'),str(A)])
verify=run('cleanup-only-static-signature-check',['codesign','--verify','--strict','--verbose=2',str(A)])
if sign['returncode']!=0 or verify['returncode']!=0:raise SystemExit('cleanup prerequisite failed')
f=json.loads((R/'fixtures.json').read_text())
result=run('cleanup-only-native',[str(B),'cleanup',f['storeA'],f['storeB'],'http://127.0.0.1/','http://127.0.0.1/','run20261108T094414Z'])
observations=[json.loads(l[len('VX_RESULT '):]) for l in result.get('stdout','').splitlines() if l.startswith('VX_RESULT ')]
status='PASS' if result['returncode']==0 and observations and all(c['passed'] for d in observations for c in d['checks']) and not any(d.get('error') for d in observations) else 'INCONCLUSIVE'
d={'status':status,'observations':observations,'source_sha256':hashlib.sha256((R/'harness/NativeProbe.swift').read_bytes()).hexdigest(),'binary_sha256':hashlib.sha256(B.read_bytes()).hexdigest(),'scope':'cleanup-only after prior app exit; does not change retained failed EXP-01 run'}
(O/'cleanup-only-result.json').write_text(json.dumps(d,indent=2)+'\n');print(json.dumps(d))
