"""Finalize source-only evidence and audit preservation; do not rerun into this directory."""
import ast,datetime,hashlib,json,pathlib,re,subprocess
HERE=pathlib.Path(__file__).resolve().parent
ROOT=HERE.parents[4]
REL=HERE.relative_to(ROOT).as_posix()
BASE='docs/architecture/phase-5/reports/M1/'
ALLOWED={BASE+n for n in ['m1-sqlcipher-publisher-authenticity-evidence.md','README.md','m1-source-catalog.md','m1-provider-trust-and-runtime-qualification.md','m1-validation-readiness-remediation.md']}
OUTPUTS={'artifact-index.json','changed-files.json','preservation-audit.json','SHA256SUMS'}
def write(name,obj):
 with (HERE/name).open('x') as f:json.dump(obj,f,indent=2);f.write('\n')
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
commands=[]
def git(*args):
 p=subprocess.run(['git',*args],cwd=ROOT,capture_output=True,text=True)
 commands.append({'argv':['git',*args],'returncode':p.returncode,'stdout':p.stdout,'stderr':p.stderr});return p
checks=[]
def check(name,ok,details=None):checks.append({'check':name,'passed':bool(ok),'details':details})
base=json.loads((HERE/'baseline.json').read_text())
head=git('rev-parse','HEAD').stdout.strip();parent=git('rev-parse','HEAD^').stdout.strip();branch=git('branch','--show-current').stdout.strip()
check('baseline HEAD unchanged',head==base['HEAD']== '0139c80a519f1b90c2d06bacea9d2af2620b16cc',head)
check('parent unchanged',parent==base['parent'],parent)
check('branch unchanged',branch==base['branch']=='timeline',branch)
check('no staged changes',git('diff','--cached','--quiet').returncode==0)
current={x['path']:sha(ROOT/x['path']) if (ROOT/x['path']).is_file() else None for x in base['tracked_files']}
missing=[p for p,h in current.items() if h is None]
changed=[x['path'] for x in base['tracked_files'] if current[x['path']]!=x['sha256']]
check('no tracked files deleted',not missing,missing)
check('only five declared canonical append-only updates',set(changed)==ALLOWED,sorted(changed))
old={}
for path in sorted(ALLOWED):old[path]=git('show','HEAD:'+path).stdout
check('original canonical bodies preserved byte-for-byte',all((ROOT/p).read_text().startswith(old[p]) for p in ALLOWED))
check('all other baseline tracked bytes unchanged',not(set(changed)-ALLOWED),{'baseline_files':len(current),'unchanged':len(current)-len(changed)})
for label,predicate in [
 ('previous evidence and manifests unchanged',lambda p:p.startswith('docs/architecture/phase-5/evidence/')),
 ('Phase 3/prototype bytes unchanged',lambda p:'phase-3/' in p or 'prototype/' in p),
 ('ADRs and owner decisions unchanged',lambda p:p.startswith('docs/decisions/') or p.endswith('m1-owner-decision-register.md')),
 ('product dependency manifests and acceptance matrix unchanged',lambda p:p.endswith(('package.json','pnpm-lock.yaml','Package.swift','Package.resolved','m1-case-level-traceability.md')))]:
 rows=[x for x in base['tracked_files'] if predicate(x['path'])]
 check(label,all(current[x['path']]==x['sha256'] for x in rows),{'tracked_files_checked':len(rows)})
unexpected=[p for p in git('ls-files','--others','--exclude-standard','-z').stdout.split('\0') if p and not p.startswith(REL+'/')]
check('new repository files only in new evidence directory',not unexpected,unexpected)
check('git diff whitespace',git('diff','--check').returncode==0)
broken=[];deferred=[]
def slug(s):
 s=re.sub(r'[^\w\s-]','',s.strip().lower())
 return re.sub(r'\s','-',s)
for path in sorted(ALLOWED):
 tail=(ROOT/path).read_text()[len(old[path]):]
 for target in re.findall(r'\]\(([^)]+)\)',tail):
  if target.startswith(('https:','http:','#','mailto:')):continue
  name,sep,fragment=target.partition('#');dest=((ROOT/path).parent/name.strip('<>')).resolve()
  if dest.parent==HERE and dest.name in OUTPUTS:deferred.append(dest);continue
  if not dest.exists():broken.append({'source':path,'target':target})
  elif sep and dest.suffix=='.md':
   headings=[slug(line.lstrip('#').strip()) for line in dest.read_text().splitlines() if line.startswith('#')]
   if fragment not in headings:broken.append({'source':path,'target':target,'reason':'fragment missing'})
check('new local links/anchors resolve; own final outputs checked after emission',not broken,broken)
for file in HERE.glob('*.py'):ast.parse(file.read_text(),filename=file.name)
check('evidence script syntax inspection',True)
acq=json.loads((HERE/'results/vendor-acquisition.json').read_text())
artifact_checks=[]
for item in acq['artifacts']:
 artifact_checks.append({'artifact':item['entity_artifact'],'unchanged':sha(HERE/item['entity_artifact'])==item['entity_sha256'] and sha(HERE/item['raw_artifact'])==item['sha256']})
check('original ZIP/signature/key acquisition bytes unchanged',all(x['unchanged'] for x in artifact_checks),artifact_checks)
decision=json.loads((HERE/'results/qualification-decision.json').read_text())
sig=json.loads((HERE/'results/signature-verification.json').read_text());key=json.loads((HERE/'results/key-structure-review.json').read_text())
comp=json.loads((HERE/'results/archive-to-commit-comparison.json').read_text())['summary']
check('source-authenticity PASS has signature/key/complete-comparison evidence',
 decision['bounded_source_authenticity']=='PASS' and sig['cryptographic_signature_status']=='PASS' and key['status']=='PASS'
 and comp['comparison_status']=='PASS' and comp['exact_byte_matches']==comp['archive_files']==comp['git_files']==2325
 and not any(comp[x] for x in ['archive_only_files','git_only_files','content_differences','mode_differences']))
direct=json.loads((HERE/'results/retained-pinned-source-byte-comparison.json').read_text())
check('supplemental direct bytes and retained-source SHA-256 manifest match',direct['status']=='PASS' and direct['exact_byte_matches']==direct['retained_source_sha256_matches']==2325)
check('deterministic comparison digest matches report',sha(HERE/'results/archive-to-commit-deterministic.json')=='7cde345937ded908c50d392eb3c72413ae6f08bf3fc0e52d7bde9461adc88c4d')
env=json.loads((HERE/'results/verifier-environment.json').read_text())
cleanup=json.loads((HERE/'results/disposable-keyring-cleanup.json').read_text())
check('only disposable keyring removed; approved verifier retained',
 not pathlib.Path(env['GNUPGHOME']).exists() and cleanup['keyring_absent_after']
 and sha(pathlib.Path(env['gpg_binary']))==env['gpg_binary_sha256'])
check('no source result converted to runtime/EXP-03 pass',
 decision['runtime_provider_tests_executed']==0 and decision['EXP_03']=='BLOCKED'
 and not decision['production_implementation_authorized'] and not decision['release_authorized'])
status=git('status','--short','--branch').stdout
evidence_paths=sorted({p.relative_to(HERE).as_posix() for p in HERE.rglob('*') if p.is_file()}|OUTPUTS)
write('changed-files.json',{'tracked_modified':[{'path':p,'change':'Append-only current verification/reference addendum','sha256':sha(ROOT/p)} for p in sorted(ALLOWED)],
 'created_evidence_files':[REL+'/'+p for p in evidence_paths],
 'host_changes':'Explicitly approved Homebrew GnuPG and required tool dependencies; see results/tool-installation-record.json',
 'hash_manifest':'SHA256SUMS covers all new evidence except itself; canonical file hashes are above',
 'no_stage_commit_push_or_branch_change':True})
write('artifact-index.json',{
 'purpose':'Bounded vendor archive signature and complete pinned-source verification; no provider runtime evidence',
 'current_report':'../../reports/M1/m1-sqlcipher-publisher-authenticity-evidence.md#8-vendor-archive-cryptographic-verification--2026-11-08-current-checkpoint',
 'artifacts':evidence_paths,'hash_manifest':'SHA256SUMS',
 'key_records':['results/verifier-environment.json','results/gpg-commands.json','results/key-structure-review.json','results/signature-verification.json'],
 'comparison_records':['results/archive-file-manifest.json','results/archive-to-commit-comparison.json','results/archive-to-commit-deterministic.json','results/pinned-tree-object-verification.json','results/retained-pinned-source-byte-comparison.json'],
 'execution_commands':[['python3',REL+'/'+name] for name in ['acquire_vendor_archive.py','verify_vendor_archive.py','compare_authenticated_source.py','finalize_archive_evidence.py']],
 'other_executed_actions':[
  'Read-only Git baseline/canonical/prior manifest/tool-path inspection; exact Git argv/outputs in baseline/preservation records',
  'Explicitly owner-approved Homebrew installation; exact command, exit and relevant excerpts in results/tool-installation-record.json',
  'Python preflight/provenance collection captured exact GnuPG/version/dump-options, brew/version and environment command outputs in results/verifier-environment.json',
  'Python parsed maintained GnuPG public-key/status output into results/key-structure-review.json; no custom signature verification',
  'Python generated deterministic comparison; supplemental direct equality of authenticated/retained pinned bytes plus retained SHA-256 checks',
  'Removed only registered task-specific disposable GNUPGHOME; results/disposable-keyring-cleanup.json'],
 'source_or_provider_contents_executed':False,'provider_builds_or_runtime_tests':0,
 'output_limits':'Full relevant GnuPG stdout/stderr and exact argv/exit codes are retained; installation record labels its excerpts rather than claiming a complete terminal transcript',
 'reuse':'Scripts write exclusive new evidence. Do not rerun into this completed evidence directory; a future run requires new paths and a new disposable keyring.'
})
write('preservation-audit.json',{'time':datetime.datetime.now(datetime.timezone.utc).isoformat(),'kind':'Repository/source/document preservation audit, not runtime or acceptance tests',
 'HEAD':head,'parent':parent,'branch':branch,'baseline_tracked_files':len(current),
 'checks':checks,'passed':sum(x['passed'] for x in checks),'failed':sum(not x['passed'] for x in checks),'all_passed':all(x['passed'] for x in checks),
 'git_commands':commands,'ending_git_status':status,
 'host_changes':'Approved GnuPG/tool dependency installation; original user keyring/stores not accessed',
 'runtime_provider_tests_executed':0})
lines=[]
for file in sorted(HERE.rglob('*')):
 if file.is_file() and file.name!='SHA256SUMS':lines.append(sha(file)+'  '+file.relative_to(HERE).as_posix())
with (HERE/'SHA256SUMS').open('x') as f:f.write('\n'.join(lines)+'\n')
bad_manifest=[name for line in lines for expected,name in [line.split('  ',1)] if sha(HERE/name)!=expected]
missing_final=[str(p) for p in set(deferred) if not p.is_file()]
print(json.dumps({'preservation_passed':sum(x['passed'] for x in checks),'preservation_failed':sum(not x['passed'] for x in checks),
 'failures':[x for x in checks if not x['passed']],'manifest_entries':len(lines),'manifest_mismatches':bad_manifest,
 'missing_generated_link_targets':missing_final,'source_authenticity':decision['bounded_source_authenticity'],
 'provider_runtime_tests':0,'HEAD':head,'status':status},indent=2))
raise SystemExit(0 if all(x['passed'] for x in checks) and not bad_manifest and not missing_final else 1)

