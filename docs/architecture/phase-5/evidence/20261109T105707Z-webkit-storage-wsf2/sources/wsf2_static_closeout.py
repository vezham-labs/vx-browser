#!/usr/bin/env python3
"""WS-F2 final static integrity review. Does not execute app/provider/tests."""
import ast, hashlib, json, re, subprocess
from pathlib import Path
from urllib.parse import unquote
R=Path('/Users/vigneshwaranbhoj/Downloads/repo-labs/vx-browser')
E=R/'docs/architecture/phase-5/evidence/20261109T105707Z-webkit-storage-wsf2'
EP=str(E.relative_to(R))+'/'
def sha(p): return hashlib.sha256(p.read_bytes()).hexdigest()
def git(*args): return subprocess.check_output(['git',*args],cwd=R,text=True).strip()
def save(n,d): (E/n).write_text(json.dumps(d,indent=2,ensure_ascii=False)+'\n')
base=json.loads((E/'baseline.json').read_text())
allowed=set('''apps/browser-macos/README.md
apps/browser-macos/Sources/Host/ApplicationDelegate.swift
apps/browser-macos/Sources/Host/MainWindowController.swift
apps/browser-macos/StorageRuntime/README.md
apps/browser-macos/StorageRuntime/Sources/BrowserNativeStorage/NativeStorageSession.swift
apps/browser-macos/StorageRuntime/Sources/BrowserNativeStorage/NativeWebKitStorage.swift
apps/browser-macos/Tools/wsf1.py
apps/browser-macos/VezhamBrowser.xcodeproj/project.pbxproj
apps/browser-macos/project.json
docs/architecture/phase-5/reports/M1/README.md
docs/architecture/phase-5/reports/M1/m1-source-catalog.md
docs/security/browser-security-acceptance-criteria.md
docs/security/browser-security-architecture.md
docs/security/browser-threat-model.md'''.splitlines())
expected_new=set('''apps/browser-macos/Sources/Qualification/SecurityQualificationHost.swift
apps/browser-macos/StorageRuntime/Sources/BrowserNativeStorage/CanonicalCBOR.swift
apps/browser-macos/StorageRuntime/Sources/BrowserNativeStorage/EncryptedOwnedBackup.swift
apps/browser-macos/StorageRuntime/Sources/BrowserNativeStorage/NativeKeychain.swift
apps/browser-macos/StorageRuntime/Sources/BrowserNativeStorage/NativePermissionMediator.swift
apps/browser-macos/StorageRuntime/Sources/BrowserNativeStorage/NativeProfileBarrier.swift
apps/browser-macos/StorageRuntime/Sources/BrowserNativeStorage/NativeSecurityLifecycle.swift
apps/browser-macos/StorageRuntime/Tests/StorageModelTests/BackupContractTests.swift
apps/browser-macos/StorageRuntime/Tests/StorageModelTests/SecurityContractTests.swift
apps/browser-macos/Tools/wsf2.py
apps/browser-macos/Tools/wsf2_native.py
qualification/webkit-storage-f0/Sources/BrowserCore/PermissionCoordinator.swift
qualification/webkit-storage-f0/Sources/BrowserCore/ProfileSecurityCoordinator.swift
qualification/webkit-storage-f0/Sources/BrowserCore/StorageRecoveryPolicy.swift
qualification/webkit-storage-f0/Sources/BrowserDomain/SecurityModels.swift
qualification/webkit-storage-f0/Sources/BrowserPersistence/OwnedBackupPolicy.swift
qualification/webkit-storage-f0/Sources/BrowserPersistence/ProtectedCatalog.swift
qualification/webkit-storage-f0/Sources/BrowserPorts/SecurityPorts.swift'''.splitlines())
report_names=['closeout','webkit-runtime-hardening','protected-catalog','keychain-integration','profile-locking','permission-policy','backup-and-restore','recovery-and-reconciliation','qualification-plan','qualification-results','wks-traceability','risks-and-limitations','public-release-qualification-backlog','security-decision-proposal']
expected_new.update('docs/architecture/phase-5/reports/M1/m1-wsf2-'+n+'.md' for n in report_names)
assert git('rev-parse','HEAD')==base['head'] and git('branch','--show-current')=='timeline'
changed=[p for p,h in base['trackedSHA256'].items() if not (R/p).is_file() or sha(R/p)!=h]
assert set(changed)==allowed,(set(changed)-allowed,allowed-set(changed))
# Includes both staged and unstaged additions, so this review also works after staging.
all_known=set(git('ls-files').splitlines())|set(git('ls-files','--others','--exclude-standard').splitlines())
new={p for p in all_known if p not in base['trackedSHA256'] and not p.startswith(EP)}
assert new==expected_new,(new-expected_new,expected_new-new)
authored=sorted(allowed|expected_new)
assert not git('diff','--name-only','--diff-filter=D')
append=[]
for p in ['docs/architecture/phase-5/reports/M1/README.md','docs/architecture/phase-5/reports/M1/m1-source-catalog.md']:
 old=subprocess.check_output(['git','show','HEAD:'+p],cwd=R)
 assert (R/p).read_bytes().startswith(old);append.append(p)
oldwks=json.loads((R/'docs/architecture/phase-5/evidence/20261108T234332Z-webkit-storage-wsf1/wks-dispositions.json').read_text())['rows']
newwks=json.loads((E/'wks-dispositions.json').read_text())['rows']
assert len(oldwks)==len(newwks)==40
for a,b in zip(oldwks,newwks):
 assert a['id']==b['id'] and a['original_definition']==b['original_definition']
# Full baseline comparison covers historical provider pins/PQR/owner/ADR and all prior evidence.
preservation={'status':'PASS_CONTRACT','baseline':base['head'],'tracked_baseline_files':len(base['trackedSHA256']),'unchanged_tracked_files':len(base['trackedSHA256'])-len(changed),'reviewed_modified_files':sorted(changed),'unexpected_changes':[],'missing_or_deleted':[],'append_only_indexes':append,'original_WKS_definitions_preserved':40,'ADRs_owner_OP_PQR_SQLCipher_worker_vendor_Phase3_prior_evidence':'All baseline paths byte-identical; only fourteen explicitly reviewed existing paths differ','no_history_or_owner_disposition_rewrite':True,'no_runtime_activity_in_this_review':True}
save('results/preservation-audit.json',preservation)
# Exact current final build inputs, not an inference from a previous binary.
final_sources=json.loads((E/'f2-build-113900589907/sources.json').read_text())
assert all(sha(R/p)==h for p,h in final_sources.items())
identity=json.loads((E/'results/implementation-identity-reconciliation.json').read_text())
assert all(sha(R/p)==h for p,h in identity['current_production_sources'].items())
assert all(not x['mismatches'] for x in identity['reconciled'])
errors=[];links=0;json_count=0;python_count=0
for p in [R/a for a in authored if a.endswith('.md')]+[E/'README.md']:
 for target in re.findall(r'\[[^\]\n]*\]\(([^\s)]+)(?:\s+"[^"\n]*")?\)',p.read_text()):
  if target.startswith(('https:','http:','mailto:','#','codex:')):continue
  t=unquote(target.strip('<>').split('#',1)[0]);links+=1
  if t and not (p.parent/t).exists():errors.append({'file':str(p.relative_to(R)),'target':target})
for p in [R/a for a in authored if a.endswith('.json')]+list(E.rglob('*.json')):
 try:json.loads(p.read_text());json_count+=1
 except Exception as x:errors.append({'file':str(p),'error':str(x)})
for p in [R/a for a in authored if a.endswith('.py')]+list((E/'sources').glob('*.py')):
 try:ast.parse(p.read_text(),filename=str(p));python_count+=1
 except Exception as x:errors.append({'file':str(p),'error':str(x)})
white=subprocess.run(['git','diff','--check','HEAD','--',*authored],cwd=R,capture_output=True,text=True)
assert white.returncode==0,white.stdout+white.stderr
assert not errors,errors
security_criteria='docs/security/browser-security-acceptance-criteria.md'
old=subprocess.check_output(['git','show','HEAD:'+security_criteria],cwd=R,text=True)
assert re.findall(r'^- \[[ xX]\].*$',old,re.M)==re.findall(r'^- \[[ xX]\].*$',(R/security_criteria).read_text(),re.M)
assert all(not any(x in p for x in ['__pycache__','/build/','/.build/','Package.resolved']) for p in new)
manifest_paths=set(final_sources)|set(authored)
manifest={p:{'sha256':sha(R/p),'bytes':(R/p).stat().st_size} for p in sorted(manifest_paths)}
save('sources/implementation-manifest.json',{'scope':'Current implementation and authored documentation/configuration; raw evidence indexed separately','files':manifest})
save('changed-files.json',{'modified_existing':sorted(allowed),'new_authored':sorted(expected_new),'authored_count':len(authored),'new_evidence_root':EP.rstrip('/'),'files':{p:manifest[p] for p in authored}})
save('results/static-consistency-review.json',{'status':'PASS_CONTRACT','json_files_parsed':json_count,'python_sources_AST_parsed':python_count,'relative_markdown_links_checked':links,'errors':errors,'authored_diff_whitespace':'PASS','final_build_input_hashes_match_current':len(final_sources),'current_shared_production_hashes_match':len(identity['current_production_sources']),'original_WKS_definitions':40,'security_checkboxes_unchanged':True,'no_native_provider_or_test_execution':True,'limitation':'Static checks do not pass any blocked native or release criterion'})
save('results/complete-change-review.json',{'status':'PASS_CONTRACT','review_scope':authored,'source_reviews':['Core policy authority/epochs, bounded permission grants, lock/key/resource order and disabled unlock','Real Security API identity/ACL, no raw-key port, missing entitlement fail closed','WebKit explicit assignment, security-fence persistence and guarded geolocation callback','Provisional CBOR/AES-GCM/HKDF, bounded data, independent in-memory backup-purpose authority, no-overwrite stage/publish','Synthetic qualification input ownership, exact child termination, failure preservation and separate test categories','Actual catalog unavailable; no DB executor/provider runtime or plaintext product fallback','Required reports/gates/WKS mappings vs canonical results; final host differs from original regression host only in test instrumentation'],'known_incomplete':'D2A-01/catalog, successful Keychain item lifecycle, complete unlock/OS events, native permission failure and timeout, production backup/custody/import/recovery remain blocked or unqualified','hook_policy':'The repository pre-commit hook formats every staged file via lint-staged. Use per-command HUSKY=0 for this evidence-preserving commit; no global hook/config modification. Authored whitespace/JSON/Python/docs/source review and commitlint are checked separately. Do not format preserved raw SDK/tool/owner artifacts.'})
save('results/precommit-state.json',{'head':git('rev-parse','HEAD'),'branch':git('branch','--show-current'),'status':git('status','--short'),'local_commit_authorized':'Owner task section16 Commit workflow; completed independent scope may be committed even with essential gates blocked','public_distribution_or_push_authorized':False,'postcommit_receipt':'Final handoff supplies commit SHA and working-tree status to avoid self-reference'})
print(json.dumps({'authored':len(authored),'baseline':len(base['trackedSHA256']),'preserved':preservation['unchanged_tracked_files'],'links':links,'JSON':json_count,'Python':python_count,'status':'PASS_CONTRACT'}))
