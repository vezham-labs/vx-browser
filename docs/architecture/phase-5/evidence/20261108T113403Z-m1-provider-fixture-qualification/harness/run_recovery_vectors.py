#!/usr/bin/env python3
"""Run only synthetic format vectors through existing Swift interpreter; no signing."""
from pathlib import Path
import datetime,hashlib,json,subprocess
E=Path(__file__).resolve().parent.parent
S=E/'harness/RecoveryVectors.swift'
args=['xcrun','swift','-swift-version','6','-target','arm64-apple-macosx26.0','-module-cache-path','/private/tmp/vx-m1-provider-fixtures-20261108T113403Z/swift-module-cache',str(S)]
start=datetime.datetime.now(datetime.timezone.utc).isoformat()
try:
 p=subprocess.run(args,text=True,capture_output=True,timeout=120)
 d={'started_at':start,'ended_at':datetime.datetime.now(datetime.timezone.utc).isoformat(),'command':args,'returncode':p.returncode,'stdout':p.stdout,'stderr':p.stderr,'source_sha256':hashlib.sha256(S.read_bytes()).hexdigest(),'no_signing_command':True,'fixture_only_not_EXP04':True}
except (OSError,subprocess.TimeoutExpired) as ex:d={'started_at':start,'command':args,'error':str(ex)}
(E/'results/recovery-fixture-run.json').write_text(json.dumps(d,indent=2)+'\n')
parsed=[json.loads(l) for l in d.get('stdout','').splitlines() if l.startswith('{')]
if parsed:(E/'results/recovery-fixture-observations.json').write_text(json.dumps(parsed[-1],indent=2)+'\n')
print(json.dumps({'returncode':d.get('returncode'),'observations':parsed[-1] if parsed else None,'stderr':d.get('stderr','')[-1800:],'error':d.get('error')}))
