#!/usr/bin/env python3
"""Documentation/preservation audit; no native/crypto/store experiment."""
from pathlib import Path
import ast,collections,datetime,hashlib,json,os,re,subprocess,urllib.parse
E=Path(__file__).resolve().parent
R=next(p for p in E.parents if (p/'.git').exists())
M=R/'docs/architecture/phase-5/reports/M1'
ENV={**os.environ,'GIT_OPTIONAL_LOCKS':'0'}
def git(*args):return subprocess.check_output(['git',*args],cwd=R,text=True,env=ENV)
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
checks=[]
def check(name,ok,detail=None):checks.append({'name':name,'passed':bool(ok),'detail':detail})
base=json.loads((E/'baseline.json').read_text())
allowed={str((M/n).relative_to(R)) for n in ['README.md','m1-source-catalog.md','m1-developer-specification.md','m1-validation-plan.md','m1-supporting-validation-charters.md','m1-case-level-traceability.md','m1-implementation-plan.md','m1-closeout-report.md']}
modified=[];missing=[]
for f in base['files']:
 p=R/f['path']
 if not p.is_file():missing.append(f['path'])
 elif sha(p)!=f['sha256']:modified.append(f['path'])
unexpected=[p for p in modified if p not in allowed]
check('no tracked file deleted',not missing,missing)
check('only scoped canonical documents changed',not unexpected,unexpected)
old=R/'docs/architecture/phase-5/evidence/20261108T094414Z-m1-consolidated-closeout'
changed_old=[p for p in modified if p.startswith(str(old.relative_to(R))+'/')]
check('all original EXP01/cleanup/evidence files immutable',not changed_old,changed_old)
check('production/prototype/ADR and owner register unchanged',not any(p.startswith(('apps/','packages/','prototype/','docs/decisions/')) or p.endswith('m1-owner-decision-register.md') for p in modified))
check('same baseline branch HEAD and cached tracking tip',git('branch','--show-current').strip()==base['branch']=='timeline' and git('rev-parse','HEAD').strip()==base['head']==base['origin_tracking'])
check('index not staged',not git('diff','--cached','--name-only').strip())
def matrix_rows(s):
 a=s.index('## Consolidated individual rows');b=s.index('## Per-row reasons',a)
 return [l for l in s[a:b].splitlines() if re.match(r'^\| (PKG-|BRIDGE-|PERM-|OFFLINE-|RECOVERY-|ISO-|PRIV-|CRYPTO-|KEY-|LOCK-|XFER-|BACKUP-|DELETE-)',l)]
rel=str((M/'m1-case-level-traceability.md').relative_to(R));before=git('show',base['head']+':'+rel);after=(M/'m1-case-level-traceability.md').read_text()
check('all165 row mappings/readiness/outcomes byte-identical',matrix_rows(before)==matrix_rows(after) and len(matrix_rows(after))==165)
rows=json.loads((old/'traceability-results.json').read_text())['items'];cases=[r for r in rows if r['kind']=='validation-case'];refs=[r for r in rows if r['kind']=='experiment-reference']
check('154 cases11 references and120 permission rows',len(cases)==154 and len(refs)==11 and len([r for r in cases if r['id'].startswith('PERM-')])==120)
check('original outcome counts unchanged',dict(collections.Counter(r['outcome'] for r in cases))=={'BLOCKED':154} and dict(collections.Counter(r['outcome'] for r in refs))=={'BLOCKED':9,'FAIL':1,'INCONCLUSIVE':1})
by={r['id']:r for r in rows};check('PERM016 AC09/14 and RECOVERY010 OP04',by['PERM-016']['acceptance']=='09,14' and by['RECOVERY-010']['policy_dependency']=='04')
check('original EXP01 FAIL/crashed cleanup retained','**Outcome:FAIL.**' in (old/'reports/EXP-01.md').read_text() and json.loads((old/'results/cleanup-only-result.json').read_text())['status']=='INCONCLUSIVE')
ds=(M/'m1-developer-specification.md').read_text()
for prefix,n in [('REQ-',22),('SPEC-',16),('AC',15)]:
 ids={int(v) for v in re.findall(r'\b'+prefix+r'(\d{2})\b',ds)};check(prefix+' complete with no extra IDs',ids==set(range(1,n+1)),sorted(ids))
check('REQ22 SPEC08 AC08 experiment route preserved',all(x in ds for x in ['### 24.3 REQ-22','**Technical specification:** SPEC-08','**Acceptance criterion:** AC08','**Experiments:** EXP-01, EXP-02, EXP-05, EXP-07']))
check('REQ21 separately retained', '## REQ-21: retained Stage C qualification reference' in after)
state=json.loads((E/'results/original-store-state.json').read_text());unchanged=[]
for st in state['stores']:
 p=Path(st['expected_path']);ok=p.exists()==st['present']
 if p.exists() and not p.is_symlink():
  now={str(f.relative_to(p)):sha(f) for f in p.rglob('*') if f.is_file() and not f.is_symlink()}
  expected={f['relative_path']:f['sha256'] for f in st['files']};ok=ok and now==expected
 unchanged.append({'name':st['name'],'unchanged':ok,'classification':st['classification']})
check('original synthetic store presence/bytes unchanged by remediation',all(x['unchanged'] for x in unchanged),unchanged)
check('both states explicitly unknown',all(x['classification']=='State unknown' for x in state['stores']))
check('retained binary matches original provenance',json.loads((E/'results/retained-binary-hash.json').read_text())['matches_original_cleanup_provenance'])
crash=json.loads((E/'results/cleanup-crash-extract.json').read_text());check('actual cleanup crash phase retained',any('removeDataStoreWithIdentifierImpl' in x.get('symbol','') for x in crash['frames']) and crash['exception']['signal']=='SIGSEGV')
unified=json.loads((E/'results/unified-log-removal-summary.json').read_text());check('A removal-start corroboration retained',unified['A_start_recorded'] and unified['record_count']==138)
enc=(M/'m1-persistent-profile-encryption-specification.md').read_text();keys=(M/'m1-keychain-and-independent-recovery-specification.md').read_text();ready=(M/'m1-validation-readiness-remediation.md').read_text()
classes=['Browser catalog','Profile SQLite','WAL','Rollback/statement/super journals','Shared-memory/WAL index','Temporary database/sort/index files','Profile metadata','History','Download metadata','User-created snapshots','Internal recovery snapshots','Session state','Recently closed tabs/windows','Permission grants','Bookmarks/favorites/saved pages','Backup archives','Recovery manifests/capsules','Key metadata','WebKit website data','External downloaded files']
check('all20 protection classes explicitly inventoried',all('| '+x+' |' in enc for x in classes))
check('recovery and failure contracts present',all(x in keys for x in ['## 2.','## 3.','## 4.','## 5.','## 6.','## 7.','VXKE','VXRF','userPresence','256-bit','checksum','Partial restore','Interrupted KEK/DEK/R rotation']))
check('EXP03/04 blocked independently of spec closure', '**Overall: Blocked.' in ready and '## 1. EXP-03 prerequisite checklist' in ready and '## 2. EXP-04 prerequisite checklist' in ready)
check('all downstream activities reassessed',all('| '+x+' |' in ready for x in ['EXP-05','EXP-07','EXP-08','SVC-04','SVC-05']))
required=['m1-exp-01-cleanup-diagnosis.md','m1-persistent-profile-encryption-specification.md','m1-keychain-and-independent-recovery-specification.md','m1-validation-readiness-remediation.md','m1-validation-remediation-report.md']
check('D01-D07 documents/sections exist',all((M/n).is_file() for n in required))
broken=[]
for p in [M/n for n in required]+[R/x for x in modified]:
 if p.suffix!='.md':continue
 for target in re.findall(r'(?<!!)\[[^\]]*\]\(([^)]+)\)',p.read_text()):
  target=target.strip('<>')
  if re.match(r'^[a-zA-Z][a-zA-Z0-9+.-]*:',target) or target.startswith('#'):continue
  target=re.sub(r':\d+$','',urllib.parse.unquote(target.split('#')[0]))
  if target and not (p.parent/target).exists() and (p.parent/target).resolve() not in [(E/'remediation-audit.json').resolve(),(E/'changed-files.json').resolve()]:broken.append({'file':str(p.relative_to(R)),'target':target})
check('updated local document links resolve',not broken,broken)
for p in E.glob('*.py'):
 try:ast.parse(p.read_text());ok=True
 except SyntaxError:ok=False
 check(p.name+' syntax',ok)
ws=subprocess.run(['git','diff','--check'],cwd=R,text=True,capture_output=True,env=ENV);check('tracked whitespace check',ws.returncode==0,ws.stdout+ws.stderr)
out={'time':datetime.datetime.now(datetime.timezone.utc).isoformat(),'passed':all(x['passed'] for x in checks),'checks':checks,'baseline_head':base['head'],'branch':git('branch','--show-current').strip(),'modified_tracked_files':modified,'tracked_file_count':len(base['files']),'original_evidence_modified':changed_old,'original_store_byte_check':unchanged,'working_tree_status':git('status','--short'),'new_store_cleanup_or_creation':False,'new_harness_launch':False,'signing_or_keychain_crypto_experiment':False,'product_implementation':False,'release_authorized':False,'independent_security_validation':False}
(E/'remediation-audit.json').write_text(json.dumps(out,indent=2)+'\n');print(json.dumps({'passed':out['passed'],'checks':len(checks),'failed':[x for x in checks if not x['passed']],'modified_tracked_files':len(modified),'baseline_tracked_files':len(base['files'])}))
raise SystemExit(0 if out['passed'] else 1)
