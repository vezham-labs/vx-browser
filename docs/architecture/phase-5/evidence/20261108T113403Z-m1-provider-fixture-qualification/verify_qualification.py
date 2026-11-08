#!/usr/bin/env python3
"""Audit qualification evidence/preservation without running an EXP or native app."""
from pathlib import Path
import ast,collections,datetime,hashlib,json,os,re,subprocess,urllib.parse
E=Path(__file__).resolve().parent.parent if Path(__file__).resolve().parent.name=='harness' else Path(__file__).resolve().parent
R=next(p for p in E.parents if (p/'.git').exists())
M=R/'docs/architecture/phase-5/reports/M1'
ENV={**os.environ,'GIT_OPTIONAL_LOCKS':'0'}
def git(*args):return subprocess.check_output(['git',*args],cwd=R,text=True,env=ENV)
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
checks=[]
def check(n,ok,d=None):checks.append({'check':n,'satisfied':bool(ok),'detail':d})
base=json.loads((E/'baseline.json').read_text());expected='f5733fabeee1b0eb559d472c6c86f317b74d8108'
check('expected starting/ending HEAD and branch',base['head']==git('rev-parse','HEAD').strip()==expected and base['branch']==git('branch','--show-current').strip()=='timeline')
check('baseline initially clean',base['status']=='')
allowed={str((M/n).relative_to(R)) for n in ['README.md','m1-validation-readiness-remediation.md','m1-source-catalog.md']}
changed=[];missing=[]
for f in base['files']:
 p=R/f['path']
 if not p.is_file():missing.append(f['path'])
 elif sha(p)!=f['sha256']:changed.append(f['path'])
check('only three canonical link updates',not set(changed)-allowed,changed)
check('no original tracked files deleted',not missing,missing)
check('all prior evidence immutable',not any('/evidence/' in p for p in changed))
check('production dependencies/configuration ADR owner decisions unchanged',not any(p.startswith(('apps/','packages/','prototype/','docs/decisions/')) or p in ['package.json','pnpm-lock.yaml','pnpm-workspace.yaml'] or p.endswith('m1-owner-decision-register.md') for p in changed))
check('index unstaged',not git('diff','--cached','--name-only').strip())
src=json.loads((E/'results/provider-source-record.json').read_text());manifest=json.loads((E/'sources/source-file-manifest.json').read_text());S=Path(src['source_directory'])
check('source version/commit and2325 upstream blob matches',src['commit']=='355d4db92d3404e71faa8088d071a71d767807f4' and src['all_archive_blob_ids_match_immutable_upstream_tree'] and len(manifest)==2325)
check('verified source files remain unchanged',all((S/f['path']).is_file() and sha(S/f['path'])==f['sha256'] for f in manifest))
archive=S.parent/'sqlcipher-source.tar.gz';check('source archive SHA256 matches retained record',sha(archive)==src['archive_sha256'])
build=json.loads((E/'results/provider-build-record.json').read_text());check('two static archives actually built and equal',len(build['builds'])==2 and build['two_archive_hashes_equal'] and len({f['sha256'] for f in build['builds']})==1)
check('actual static archive hashes still match',all(Path(f['archive']).is_file() and sha(Path(f['archive']))==f['sha256'] for f in build['builds']))
static=json.loads((E/'results/provider-static-inspection.json').read_text());check('CommonCrypto and temp-store compile facts retained',static['temp_store_compile_setting_3'] and 'TEMP_STORE=3' in static['compiled_object_public_strings'] and any('_CCCryptorCreate' in x for x in static['static_commoncrypto_symbols']))
check('runtime provider/temp claims remain false',not static['runtime_temp_store_observed'] and not static['runtime_provider_version_or_settings_observed'] and not build['provider_runtime_or_database_qualification_performed'])
binding=json.loads((E/'results/key-binding-syntax-check.json').read_text());check('final key-binding syntax source matches and succeeds',binding['returncode']==0 and binding['source_sha256']==sha(E/'harness/key_binding_compile_fixture.c') and not binding['execution_performed'])
vectors=json.loads((E/'results/recovery-fixture-observations.json').read_text());vrun=json.loads((E/'results/recovery-fixture-run.json').read_text())
check('final29 bounded recovery observations and exact source',vrun['returncode']==0 and vrun['source_sha256']==sha(E/'harness/RecoveryVectors.swift') and len(vectors['checks'])==29 and all(x['satisfied'] for x in vectors['checks']))
check('fixture does not claim EXP04 native or cross-Mac qualification',not vectors['EXP04_qualified'] and not vectors['native_keychain_test'] and not vectors['cross_mac_recovery'] and not vectors['database_restore_test'])
check('fixture outputs contain no secret fields/key hashes',not vectors['secret_or_key_hash_output'] and not any(k in vectors for k in ['secret','key','dek','recovery_secret','key_hash','ciphertext','tag','capsule']))
cleanup=json.loads((E/'results/recovery-fixture-cleanup-check.json').read_text());check('no retained transient capsule names found',not cleanup['matching_fixture_names'])
interop=json.loads((E/'results/public-cbor-interop.json').read_text());check('public structural interoperability observation only',interop['matches_independently_decoded_structure'] and interop['matches_expected_canonical_hex'] and not interop['full_VXKE_VXRF_or_crypto_interoperability_qualified'])
controls=json.loads((E/'results/database-control-fixtures.json').read_text());check('prepared plaintext controls honestly labelled',controls['positive_control_marker_detected_in_main'] and controls['positive_control_marker_detected_in_wal'] and not controls['encrypted_fixtures_created'] and not controls['EXP03_executed'])
check('prepared control artifact hashes match',all(Path(a['path']).is_file() and sha(Path(a['path']))==a['sha256'] for a in controls['artifacts']))
before=json.loads((E/'results/original-store-before.json').read_text());after=json.loads((E/'results/original-store-after.json').read_text())
check('original store bytes/presence unchanged',before['stores']==after['stores'])
check('original logical states not silently resolved',all(x['logical_state']=='UNKNOWN' for x in after['stores']) and not after['registry_enumeration'] and not after['store_creation_or_removal'])
native=json.loads((E/'results/native-identity-and-registry-feasibility.json').read_text());check('native/signing/registry boundary preserved',not native['signing_performed'] and not native['keychain_test_executed'] and not native['registry_enumeration_performed'])
old=R/'docs/architecture/phase-5/evidence/20261108T094414Z-m1-consolidated-closeout';rows=json.loads((old/'traceability-results.json').read_text())['items']
cases=[x for x in rows if x['kind']=='validation-case'];refs=[x for x in rows if x['kind']=='experiment-reference']
check('existing154 cases11 references and outcomes unchanged',len(cases)==154 and len(refs)==11 and dict(collections.Counter(x['outcome'] for x in cases))=={'BLOCKED':154} and dict(collections.Counter(x['outcome'] for x in refs))=={'FAIL':1,'INCONCLUSIVE':1,'BLOCKED':9})
check('original EXP01 FAIL and cleanup crash remain','**Outcome:FAIL.**' in (old/'reports/EXP-01.md').read_text() and json.loads((old/'results/cleanup-only-native.json').read_text())['returncode']==-11)
doc=M/'m1-provider-and-fixture-qualification.md';text=doc.read_text();broken=[]
for p in [doc]+[R/x for x in changed]:
 for target in re.findall(r'(?<!!)\[[^\]]*\]\(([^)]+)\)',p.read_text()):
  target=target.strip('<>')
  if re.match(r'^[a-zA-Z][a-zA-Z0-9+.-]*:',target) or target.startswith('#'):continue
  target=re.sub(r':\d+$','',urllib.parse.unquote(target.split('#')[0]));q=(p.parent/target).resolve()
  if target and not q.exists() and q not in [(E/'qualification-audit.json').resolve(),(E/'changed-files.json').resolve()]:broken.append({'file':str(p.relative_to(R)),'target':target})
check('updated local links resolve',not broken,broken)
for p in (E/'harness').glob('*.py'):
 try:ast.parse(p.read_text());ok=True
 except SyntaxError:ok=False
 check(p.name+' syntax',ok)
ws=subprocess.run(['git','diff','--check'],cwd=R,text=True,capture_output=True,env=ENV);check('tracked whitespace',ws.returncode==0,ws.stdout+ws.stderr)
out={'time':datetime.datetime.now(datetime.timezone.utc).isoformat(),'all_audit_checks_satisfied':all(c['satisfied'] for c in checks),'checks':checks,'starting_head':base['head'],'ending_head':git('rev-parse','HEAD').strip(),'branch':git('branch','--show-current').strip(),'modified_tracked_files':changed,'baseline_tracked_count':len(base['files']),'working_tree_status':git('status','--short'),'existing_outcomes_unchanged':True,'production_or_dependency_changes':False,'signing_or_native_keychain_registry_execution':False,'full_EXP03_EXP04_or_downstream_campaign_executed':False,'independent_security_signoff':False}
(E/'qualification-audit.json').write_text(json.dumps(out,indent=2)+'\n');print(json.dumps({'all_audit_checks_satisfied':out['all_audit_checks_satisfied'],'checks':len(checks),'failed':[x for x in checks if not x['satisfied']],'modified_tracked_files':len(changed),'baseline_tracked_count':len(base['files'])}))
raise SystemExit(0 if out['all_audit_checks_satisfied'] else 1)
