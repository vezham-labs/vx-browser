#!/usr/bin/env python3
"""Read-only documentation/preservation verification, except its own audit records."""
from pathlib import Path
import ast,collections,datetime,hashlib,json,os,re,subprocess,urllib.parse
E=Path(__file__).resolve().parent
R=next(p for p in E.parents if (p/'.git').exists())
M=R/'docs/architecture/phase-5/reports/M1'
checks=[]
def check(name,ok,detail=None):checks.append({'check':name,'passed':bool(ok),'detail':detail})
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
def git(*args):return subprocess.check_output(['git',*args],cwd=R,text=True,env={**os.environ,'GIT_OPTIONAL_LOCKS':'0'})
baseline=json.loads((E/'repository-baseline.json').read_text())
data=json.loads((E/'traceability-results.json').read_text())
src=(E/'supplied/case-level-traceability-v1.1-proposed.md').read_text()
raw=[l.split('|')[1:-1] for l in src.splitlines() if re.match(r'^\| (PKG-|BRIDGE-|PERM-|OFFLINE-|RECOVERY-|ISO-|PRIV-|CRYPTO-|KEY-|LOCK-|XFER-|BACKUP-|DELETE-)',l)]
raw=[[x.strip() for x in r] for r in raw]
items=data['items'];by={x['id']:x for x in items}
keys=['description','requirements','acceptance','specifications','owner_dispositions','adrs','parent','artifacts','environment','platform','policy_dependency','prerequisites','source_readiness']
check('165 unique source/current row identifiers',len(raw)==len(items)==len(by)==165 and {r[0] for r in raw}==set(by))
check('all original individual mappings/readiness preserved',all([by[r[0]][k] for k in keys]==r[1:] for r in raw))
cases=[x for x in items if x['kind']=='validation-case'];refs=[x for x in items if x['kind']=='experiment-reference']
check('154 validation cases,11 references',len(cases)==154 and len(refs)==11)
check('all120 permission rows preserved',len([x for x in cases if x['id'].startswith('PERM-')])==120)
check('historical validation statuses36B48U70PN',dict(collections.Counter(x['source_readiness'] for x in cases))=={'B':36,'U':48,'PN':70})
check('historical reference statuses0B9U2PN',dict(collections.Counter(x['source_readiness'] for x in refs))=={'U':9,'PN':2})
check('exactly one allowed current outcome per row',all(x['outcome'] in {'PASS','FAIL','BLOCKED','INCONCLUSIVE','NOT RUN'} for x in items))
check('current outcomes independently counted',dict(collections.Counter(x['outcome'] for x in cases))=={'BLOCKED':154} and dict(collections.Counter(x['outcome'] for x in refs))=={'BLOCKED':9,'FAIL':1,'INCONCLUSIVE':1})
check('PERM-016 remains AC09/14',by['PERM-016']['acceptance']=='09,14')
check('RECOVERY-010 remains OP04',by['RECOVERY-010']['policy_dependency']=='04')
old=(E/'supplied/developer-specification-v1.0-proposed.md').read_text();owner=(M/'m1-owner-decision-register.md').read_text();ds=(M/'m1-developer-specification.md').read_text()
verbatim=old[old.index('### Verbatim normative owner entries'):old.index('## 28.')]
check('all20 original owner entries verbatim',verbatim in owner and verbatim in ds)
def historical(s):
 a=s.index('## 26.');b=s.index('## 27.',a)
 return [l.split('|')[1:3] for l in s[a:b].splitlines() if re.match(r'^\| OD\d',l)]
check('WS01.1 historical crosswalk meanings preserved',len(historical(old))==20 and historical(old)==historical(ds))
auth=(E/'supplied/owner-task-authorization.txt').read_text();scope=auth[auth.index('## 3.2 '):auth.index('# 4. Close')]
check('current OP/scope instruction preserved verbatim',scope in owner)
svc=(M/'m1-supporting-validation-charters.md').read_text()
check('C02 SVC summary corrected without row reassignment','| AC07 | LOCK-001, RECOVERY-006 |' in svc and '| AC07 | LOCK-001, PERM-016, RECOVERY-006 |' not in svc)
check('C03 older OP01 recovery010 association absent from maintained table','OFFLINE-005; RECOVERY-004/010;' not in svc and by['RECOVERY-010']['policy_dependency']=='04')
for prefix,n in [('REQ-',22),('SPEC-',16),('AC',15)]:
 found={int(v) for v in re.findall(r'\b'+prefix+r'(\d{2})\b',ds)}
 check(prefix+' complete without extra IDs',found==set(range(1,n+1)),sorted(found))
check('REQ21 stays separate StageC/no new AC16','## REQ-21: retained Stage C qualification reference' in (M/'m1-case-level-traceability.md').read_text() and not re.search(r'\bAC16\b',ds))
check('REQ22 qualification route preserved',all(x in ds for x in ['### 24.3 REQ-22','**Technical specification:** SPEC-08','**Acceptance criterion:** AC08','**Experiments:** EXP-01, EXP-02, EXP-05, EXP-07']))
check('all26 selected capabilities assessed',len(re.findall(r'^\| \d+ \|',ds[ds.index('## 31.'):ds.index('## 32.')],re.M))==26)
check('19 implementation packages',(len(re.findall(r'^### WP\d{2} ',(M/'m1-implementation-plan.md').read_text(),re.M))==19))
for id in [f'EXP-{i:02}' for i in range(1,9)]+[f'SVC-{i:02}' for i in range(1,6)]:
 p=E/'reports'/(id+'.md');check(id+' report and classified outcome',p.exists() and re.search(r'\*\*Outcome:(PASS|FAIL|BLOCKED|INCONCLUSIVE|NOT RUN)\.\*\*',p.read_text()) is not None)
adr={}
for p in sorted((R/'docs/decisions').glob('000[1-5]-*.md')):
 adr[p.name]=re.search(r'\*\*Status:\*\* ([^\n]+)',p.read_text()).group(1).strip()
check('ADR statuses unchanged',[v.split(';')[0].strip() for v in adr.values()]==['Proposed','Accepted','Proposed','Proposed','Proposed'],adr)
modified=[];missing=[]
for f in baseline['tracked_files']:
 p=R/f['path']
 if not p.is_file():missing.append(f['path'])
 elif sha(p)!=f['sha256']:modified.append(f['path'])
protected=[p for p in modified if not p.startswith('docs/') or p.startswith(('docs/architecture/phase-3/','docs/architecture/prototype/','docs/decisions/'))]
check('no tracked files missing',not missing,missing)
check('production/Phase3/ADR source and evidence preserved',not protected,protected)
check('no unrelated application/package/config changes',all(p.startswith('docs/') for p in modified),modified)
check('same branch/HEAD',git('branch','--show-current').strip()==baseline['branch'] and git('rev-parse','HEAD').strip()==baseline['head'])
check('index unstaged',not git('diff','--cached','--name-only').strip())
broken=[]
canonical=list(M.glob('m1-*.md'))+[M/'README.md']
for p in canonical:
 for target in re.findall(r'(?<!!)\[[^\]]*\]\(([^)]+)\)',p.read_text()):
  target=target.strip('<>')
  if re.match(r'^[a-zA-Z][a-zA-Z0-9+.-]*:',target) or target.startswith('#'):continue
  target=urllib.parse.unquote(target.split('#')[0]);target=re.sub(r':\d+$','',target)
  if target and not (p.parent/target).exists():broken.append({'file':str(p.relative_to(R)),'target':target})
check('canonical local links resolve',not broken,broken)
for p in (E/'harness').glob('*.py'):
 try:ast.parse(p.read_text());ok=True
 except SyntaxError:ok=False
 check(p.name+' Python syntax',ok)
whitespace=subprocess.run(['git','diff','--check'],cwd=R,text=True,capture_output=True,env={**os.environ,'GIT_OPTIONAL_LOCKS':'0'})
check('tracked documentation whitespace check',whitespace.returncode==0,whitespace.stdout+whitespace.stderr)
source_manifest=[{'path':str(p.relative_to(E)),'sha256':sha(p),'bytes':p.stat().st_size} for p in sorted((E/'supplied').glob('*')) if p.is_file()]
(E/'supplied-source-manifest.json').write_text(json.dumps(source_manifest,indent=2)+'\n')
out={'recorded_at':datetime.datetime.now(datetime.timezone.utc).isoformat(),'passed':all(c['passed'] for c in checks),'checks':checks,'initial_tracked_files':len(baseline['tracked_files']),'modified_tracked_files':modified,'missing_tracked_files':missing,'protected_changes':protected,'branch':git('branch','--show-current').strip(),'head':git('rev-parse','HEAD').strip(),'working_tree_status':git('status','--short'),'product_implementation_authorized':False,'release_authorized':False,'validation_authorized_within_scope':True,'independent_security_signoff':False}
(E/'final-audit.json').write_text(json.dumps(out,indent=2)+'\n')
print(json.dumps({'passed':out['passed'],'checks':len(checks),'failed':[c for c in checks if not c['passed']],'modified_tracked_files':len(modified),'initial_tracked_files':out['initial_tracked_files']}))
raise SystemExit(0 if out['passed'] else 1)
