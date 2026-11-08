"""Finalize new evidence once; read-only repository audit, no provider/crypto execution."""
import ast,datetime,hashlib,json,pathlib,re,subprocess
HERE=pathlib.Path(__file__).resolve().parent
ROOT=HERE.parents[4]
REL=HERE.relative_to(ROOT).as_posix()
BASE='docs/architecture/phase-5/reports/M1/'
ALLOWED={BASE+x for x in ['README.md','m1-provider-trust-and-runtime-qualification.md','m1-source-catalog.md','m1-validation-readiness-remediation.md']}
REPORT=BASE+'m1-sqlcipher-publisher-authenticity-evidence.md'
EXPECTED={'artifact-index.json','changed-files.json','preservation-audit.json','SHA256SUMS'}
def write(name,obj):
 with (HERE/name).open('x') as f:json.dump(obj,f,indent=2);f.write('\n')
def digest(p):return hashlib.sha256(p.read_bytes()).hexdigest()
commands=[]
def git(*args):
 p=subprocess.run(['git',*args],cwd=ROOT,capture_output=True,text=True)
 commands.append({'argv':['git',*args],'returncode':p.returncode,'stdout':p.stdout,'stderr':p.stderr})
 return p
base=json.loads((HERE/'baseline.json').read_text()); checks=[]
def check(name,ok,detail=None):checks.append({'check':name,'passed':bool(ok),'detail':detail})
branch=git('branch','--show-current').stdout.strip()
head=git('rev-parse','HEAD').stdout.strip();parent=git('rev-parse','HEAD^').stdout.strip()
check('branch unchanged',branch==base['branch'],branch)
check('HEAD unchanged',head==base['HEAD'],head)
check('parent unchanged',parent==base['parent'],parent)
check('no staged diff',git('diff','--cached','--quiet').returncode==0)
current={x['path']:digest(ROOT/x['path']) if (ROOT/x['path']).is_file() else None for x in base['tracked_files']}
missing=[p for p,h in current.items() if h is None]
changed=[x['path'] for x in base['tracked_files'] if current[x['path']]!=x['sha256']]
check('no tracked deletion',not missing,missing)
check('only four allowed tracked reference files changed',set(changed)==ALLOWED,sorted(changed))
appends=[]
for path in sorted(ALLOWED):
 original=git('show','HEAD:'+path).stdout
 appends.append({'path':path,'original_body_preserved':(ROOT/path).read_text().startswith(original)})
check('historical canonical report bodies preserved; updates append-only',all(x['original_body_preserved'] for x in appends),appends)
check('all other baseline tracked bytes unchanged',not(set(changed)-ALLOWED),{'baseline_tracked_files':len(current),'unchanged_files':len(current)-len(changed)})
for label,predicate in [
 ('all previous Phase 5 evidence unchanged',lambda p:p.startswith('docs/architecture/phase-5/evidence/')),
 ('Phase 3/prototype source/evidence/manifests unchanged',lambda p:('phase-3/' in p or 'prototype/' in p)),
 ('owner decisions/ADRs/matrix unchanged',lambda p:p.startswith('docs/decisions/') or p.endswith(('m1-owner-decision-register.md','m1-case-level-traceability.md')))]:
 selected=[x for x in base['tracked_files'] if predicate(x['path'])]
 check(label,all(current[x['path']]==x['sha256'] for x in selected),{'tracked_files':len(selected)})
untracked=[p for p in git('ls-files','--others','--exclude-standard','-z').stdout.split('\0') if p]
unexpected=[p for p in untracked if p!=REPORT and not p.startswith(REL+'/')]
check('new files limited to current evidence and publisher report',not unexpected,unexpected)
check('tracked diff whitespace',git('diff','--check').returncode==0)
broken=[];deferred=[]
for path in sorted(ALLOWED|{REPORT}):
 for target in re.findall(r'\]\(([^)]+)\)',(ROOT/path).read_text()):
  if target.startswith(('https:','http:','#','mailto:')):continue
  dest=((ROOT/path).parent/target.split('#')[0].strip('<>')).resolve()
  if dest.parent==HERE and dest.name in EXPECTED:
   deferred.append(str(dest.relative_to(ROOT)));continue
  if not dest.exists():broken.append({'path':path,'target':target})
check('existing document link targets resolve; declared finalizer outputs checked after emission',not broken,{'broken':broken,'deferred_own_outputs':sorted(set(deferred))})
for script in sorted(HERE.glob('*.py')):ast.parse(script.read_text(),filename=script.name)
check('new source-inspection/finalization scripts parse; no provider tests',True)
provenance=json.loads((HERE/'results/source-and-key-provenance.json').read_text())
check('unchanged exact tag/pin relationship recorded',provenance['pin']==provenance['fresh_commit']==provenance['tag_target']['sha']=='355d4db92d3404e71faa8088d071a71d767807f4')
verification=json.loads((HERE/'results/signature-verification-status.json').read_text())
check('verification and runtime stop represented without fabricated results',
 verification['status']=='NOT EXECUTED' and not verification['executed_signature_commands']
 and not verification['provider_executed'] and not verification['software_installed']
 and verification['final_authenticity_status']=='BLOCKED')
status=git('status','--short','--branch').stdout
all_paths=sorted({str(p.relative_to(ROOT)) for p in HERE.rglob('*') if p.is_file()}|
                 {REL+'/'+name for name in EXPECTED}|ALLOWED|{REPORT})
write('changed-files.json',{'tracked_modified':[{'path':p,'change':'Append-only canonical reference','sha256':digest(ROOT/p)} for p in sorted(ALLOWED)],
 'new_report':{'path':REPORT,'sha256':digest(ROOT/REPORT)},
 'new_evidence_files':[p for p in all_paths if p.startswith(REL+'/')],
 'hash_inventory':'SHA256SUMS covers every evidence file except itself; report/reference hashes are above',
 'staged':False,'committed':False,'pushed':False})
artifact_paths=sorted({str(p.relative_to(HERE)) for p in HERE.rglob('*') if p.is_file()}|EXPECTED)
write('artifact-index.json',{
 'purpose':'Publisher authenticity acquisition; no cryptographic or provider runtime evidence generated',
 'report':'../../reports/M1/m1-sqlcipher-publisher-authenticity-evidence.md',
 'evidence_files':artifact_paths,
 'sha256_manifest':'SHA256SUMS',
 'source_provenance':'results/source-and-key-provenance.json',
 'signature_verification':'results/signature-verification-status.json',
 'inquiry':'vendor-inquiry-draft.md — UNSENT, no communication authorized',
 'executed_python_commands':[['python3',REL+'/'+name] for name in ['acquire_public_evidence.py','decode_public_evidence.py','acquire_publisher_artifacts.py','finalize_authenticity_evidence.py']],
 'command_outputs':{
  'acquisition':'results/acquisition-summary.json and sources/*.json retain URL/status/time/raw hashes',
  'decoded_responses':'results/decoded-body-records.json; raw bytes retained even where gzip encoded',
  'followup':'results/followup-acquisitions.json retains single bounded 504 follow-ups and publisher key/signature acquisition',
  'final_git_commands':'preservation-audit.json includes actual argv, stdout, stderr and exit codes'},
 'inspection_limitations':[
  'Initial read_text of a gzip HTTP body raised UnicodeDecodeError; decoded copies were subsequently created without replacing raw bodies',
  'Initial filtered link extraction missed the .gpg key link; full-page/browser inspection established its vendor-published URL',
  'Web lookup of GitHub release/commit APIs failed; separate successful HTTP follow-up responses retained',
  'Attestation404 is scoped, inconclusive, not proof of global absence',
  'No gpg, signature/key verification, installation, provider build/runtime, original-store/native qualification, external message, commit or push'],
 'append_only_usage':'Do not rerun into this evidence directory. New acquisition attempts require new paths.'
})
write('preservation-audit.json',{
 'time':datetime.datetime.now(datetime.timezone.utc).isoformat(),
 'kind':'Repository/document preservation audit, not product or authenticity test passes',
 'branch':branch,'HEAD':head,'parent':parent,'baseline_tracked_files':len(current),
 'checks':checks,'passed':sum(x['passed'] for x in checks),'failed':sum(not x['passed'] for x in checks),
 'all_passed':all(x['passed'] for x in checks),'ending_git_status':status,'commands':commands,
 'original_browser_stores':'Not accessed or inspected; no state inference',
 'no_crypto_runtime_or_external_message':'See explicit non-execution status and source-only command records'})
manifest=[]
for p in sorted(HERE.rglob('*')):
 if p.is_file() and p.name!='SHA256SUMS':manifest.append(digest(p)+'  '+str(p.relative_to(HERE)))
with (HERE/'SHA256SUMS').open('x') as f:f.write('\n'.join(manifest)+'\n')
missing_outputs=[p for p in sorted(set(deferred)) if not(ROOT/p).is_file()]
mismatched=[]
for line in manifest:
 expected,filename=line.split('  ',1)
 if digest(HERE/filename)!=expected:mismatched.append(filename)
ok=all(x['passed'] for x in checks) and not missing_outputs and not mismatched
print(json.dumps({'audit_passed':sum(x['passed'] for x in checks),'audit_failed':sum(not x['passed'] for x in checks),
 'audit_failures':[x for x in checks if not x['passed']],'generated_link_targets_missing':missing_outputs,
 'SHA256SUMS_entries':len(manifest),'manifest_hash_mismatches':mismatched,'new_evidence_files':len(artifact_paths),
 'HEAD':head,'branch':branch,'authenticity':'BLOCKED','cryptographic_verification':'NOT EXECUTED',
 'provider_runtime_tests':0,'status':status},indent=2))
raise SystemExit(0 if ok else 1)

