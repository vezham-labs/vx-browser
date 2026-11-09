from pathlib import Path
import json,hashlib,collections,re,subprocess,ast
R=Path('/Users/vigneshwaranbhoj/Downloads/repo-labs/vx-browser');E=R/'docs/architecture/phase-5/evidence/20261109T105707Z-webkit-storage-wsf2';M=R/'docs/architecture/phase-5/reports/M1';REL='../../evidence/'+E.name+'/'
def read(p):return json.loads(p.read_text())
def save(p,d):p.write_text(json.dumps(d,indent=2)+'\n')
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
B=E/'f2-build-113900589907';RB=E/'f2-build-113022470426';N=E/'f2-webkit-native-114029856396';K=E/'f2-security-native-113238831637';T=E/'f2-contracts-113307401411';F=E/'attempt-112058889226';W=E/'native-113327653483'
canonical={'final_test_host_build':str(B.relative_to(R)),'production_regression_build':str(RB.relative_to(R)),'wsf2_webkit':str(N.relative_to(R)),'wsf2_keychain_backup':str(K.relative_to(R)),'contract_fake':str(T.relative_to(R)),'retained_f0':str(F.relative_to(R)),'retained_f1_native':str(W.relative_to(R)),'scope':'Each suite retains its own source/build identity. Never aggregate earlier attempts or transfer test-host results across binaries.'}
save(E/'results/canonical-attempts.json',canonical)
production={p:h for p,h in read(B/'sources.json').items() if '/Tests/' not in p and '/Sources/Qualification/' not in p}
reconciled=[]
for folder in [RB,K,T,F,W]:
 manifest=folder/'sources.json'
 if not manifest.exists():manifest=folder/'source-hashes.json'
 if manifest.exists():
  obj=read(manifest);obj={x['path']:x['sha256'] for x in obj} if isinstance(obj,list) else obj
  common=[p for p in production if p in obj]
  mismatch=[p for p in common if obj[p]!=production[p]]
  assert not mismatch,(folder,mismatch)
  reconciled.append({'attempt':str(folder.relative_to(R)),'common_production_source_count':len(common),'mismatches':mismatch,'limitation':'Byte identity of shared production inputs, not binary identity or qualification of excluded test-host code'})
assert all(sha(R/p)==h for p,h in production.items())
save(E/'results/implementation-identity-reconciliation.json',{'current_production_sources':production,'reconciled':reconciled,'final_host_source_changes':'Only SecurityQualificationHost instrumentation/oracles after RB; original WebKit/Core/Ports/key/backup/lock implementation unchanged','no_test_result_aggregation':True})
# Detailed per-case inventory with mode, platform and evidence; failed processes remain separate.
allcases=[]
for folder,kind in [(N,'native integration/restart'),(K,'native Keychain/CryptoKit/file integration'),(W,'retained native WebKit/restart')]:
 for c in read(folder/'case-results.json'):
  allcases.append({**c,'test_type':'contract/admission' if c['status']=='PASS_CONTRACT' else kind,'platform':'macOS27.2/26B123 arm64','evidence':str((folder/'case-results.json').relative_to(R))})
for name in read(T/'result.json')['tests']:
 allcases.append({'id':name.split(' ')[0],'description':name,'status':'PASS_FAKE_ONLY' if '-FAKE-' in name else 'PASS_CONTRACT','test_type':'deterministic fake' if '-FAKE-' in name else 'contract/model','platform':'macOS27.2/26B123 arm64','evidence':str((T/'result.json').relative_to(R))})
save(E/'case-inventory.json',{'scope':'Canonical suite records only; repeated per-process IDs remain correlated, not unique independent cases','cases':allcases})
history=[]
for file in sorted(E.glob('*/result.json')):
 d=read(file);history.append({'path':str(file.relative_to(R)),'status':d.get('status',d.get('nativeQualification')),'count':d.get('count',d.get('passed_test_count',d.get('discoveryPassedObservations'))),'failed':d.get('failed',d.get('discoveryFailedObservations')),'blocked':d.get('blocked'),'returncode':d.get('returncode')})
save(E/'results/attempt-history.json',history)
cache=read(N/'attempts.json');cache_values={x['label']:x['result'].get('observations',{}) for x in cache if x['label'].startswith('cache-')};requests=read(N/'server-requests.json')
save(E/'results/cache-analysis.json',{'evidence':str(N.relative_to(R)),'response_observations':cache_values,'server_requests':requests,'within_live_profile_reuse_observed':cache_values['cache-A-seed']['first']==cache_values['cache-A-seed']['second'],'cross_profile_responses_separate':cache_values['cache-A-seed']['first']!=cache_values['cache-B-seed']['first'],'restart_retrieval_observed':cache_values['cache-A-seed']['first']!=cache_values['cache-A-restart']['first'],'reconstruction_reuse':cache_values['cache-A-reconstruct'].get('beforeReconstruction')==cache_values['cache-A-reconstruct']['first'],'after_abrupt_new_retrieval':cache_values['cache-A-abrupt']['first']!=cache_values['cache-A-after-abrupt']['first'],'selected_clear_positive_control':cache_values['cache-A-selected-clear']['beforeClear']!=cache_values['cache-A-selected-clear']['first'],'full_clear_positive_control':cache_values['cache-A-full-clear']['beforeClear']!=cache_values['cache-A-full-clear']['first'],'cache_revalidation_observed':any(x.get('ifNoneMatch') for x in requests),'disk_persistence':'INCONCLUSIVE: response/server behavior is observed, no engine-file or durable-disk proof','after_removal':'Public callback/identifier absence, no creating probe or reuse of removed ID'})
# Record exact environment/signature/symbol evidence, never provider execution.
app=read(B/'result.json')['bundle'];binary=app+'/Contents/MacOS/VezhamBrowser'
for label,argv in [('final-signature',['codesign','-d','--verbose=4',app]),('undefined-symbols',['nm','-u',binary])]:
 p=subprocess.run(argv,capture_output=True,text=True);save(E/'results'/(label+'.json'),{'argv':argv,'returncode':p.returncode,'stdout':p.stdout,'stderr':p.stderr})
symbols=read(E/'results/undefined-symbols.json')['stdout'];assert not re.search(r'\b_sqlite3_|\b_sqlcipher',symbols)
save(E/'results/provider-safety-review.json',{'pin':'355d4db92d3404e71faa8088d071a71d767807f4','candidate':'SQLCipher4.20.0 Community/CommonCrypto; all previous verification records preserved','D2A01':'Proposed/Not Decided','blocked_operation':'Existing-file open reaches100-byte encrypted-header request before target connection key binding; no approved compliant public path established','alternatives_record':'docs/architecture/phase-5/reports/M1/m1-sqlcipher-open01-resolution.md','provider_initialization_or_database_open':False,'ciphertext_prekey_hash_copy_read':False,'new_database_creation':False,'provider_pin_vendor_PQR_changed':False,'direct_provider_symbols_in_final_app':False,'new_plaintext_database_or_key_store':False})
save(E/'results/execution-boundaries.json',{'actual_WebKit':True,'actual_Security_Keychain_attempts':True,'actual_SecRandom_CryptoKit_and_synthetic_backup_files':True,'successful_DP_userPresence_Keychain_item_creation':False,'Keychain_statuses':{'create':-34018,'acquire':-25300,'delete':-34018},'SQLCipher_runtime_or_DB_open_create_migration':False,'user_profile_or_personal_keys_used':False,'private_API_or_default_store_workaround':False,'security_ACL_or_signing_relaxation':False,'production_backup_import_or_Key_envelope_recovery_custody':False,'macOS26_runtime':'Deferred / NOT_EXECUTED by current owner task','signing_notarization_release_distribution':False,'push':False})
# Actual fixture provenance and cleanup disposition; no orphan sweep/recreation.
fixtures=[]
for folder in sorted(E.glob('*native-*')):
 if not folder.is_dir():continue
 for p in sorted(folder.glob('*-input.json')):
  d=read(p);fixtures.append({'input':str(p.relative_to(R)),'action':d.get('action'),'profile':d.get('profile'),'store':d.get('store'),'namespace':d.get('namespace'),'profiles':d.get('profiles'),'disposition':'See exact matching result/checkpoints. Failed/interrupted/locked resources preserved; no creating existence probe or broad cleanup.'})
save(E/'results/resource-dispositions.json',{'fixture_inputs':fixtures,'canonical_normal_removals':[str((N/'cache-A-remove-result.json').relative_to(R)),str((N/'cache-B-remove-result.json').relative_to(R)),str((W/'05-remove-result.json').relative_to(R))],'lock_other_profiles':'Other-profile removal outcomes and UUIDs recorded in each lock result','permission_cleanup':'NOT_EXECUTED after native denial criterion failed; retired synthetic mapping/checkpoint retained','failed_and_interrupted_stages':'Preserved, not silently reset/reused/swept','Keychain':'Create never succeeded; synthetic namespaces retained for exact audit, no personal item touched','backup_files':'Exact owned temporary encrypted-fixture directory removed after native checks; no real download or user file deleted','original_historical_stores':'Only preserved noncreating diagnostic; original logical cleanup states unchanged'})
# Preserve all40 original definitions and historical dispositions; new overlay only.
old=read(R/'docs/architecture/phase-5/evidence/20261108T234332Z-webkit-storage-wsf1/wks-dispositions.json')['rows'];rows=[]
for row in old:
 i=int(row['id'][4:]);status='PASS_FAKE_ONLY' if i in [2,4,18,27] else 'PASS_CONTRACT' if i==36 else 'NOT_EXECUTED' if i==37 else 'BLOCKED'
 paths=['apps/browser-macos/StorageRuntime/Sources/BrowserNativeStorage/NativeWebKitStorage.swift']
 routes=[{'evidence':str((W/'case-results.json').relative_to(R)),'scope':'Exact retained WSF1 native contribution, not whole-case pass'}]
 if i in [5,6,7,8,9,21,22,24,26]:routes.append({'evidence':str((N/'case-results.json').relative_to(R)),'scope':'Cache/profile/restart/clear/remove subset only'})
 if i in [17,18,21,28,30,39]:paths+=['qualification/webkit-storage-f0/Sources/BrowserCore/ProfileSecurityCoordinator.swift','qualification/webkit-storage-f0/Sources/BrowserCore/StorageRecoveryPolicy.swift'];routes.append({'evidence':str((N/'case-results.json').relative_to(R)),'scope':'Native view barrier/lock-fence restart only; loaded-key/durable/OS locks unqualified'})
 if i==35:paths+=['qualification/webkit-storage-f0/Sources/BrowserCore/PermissionCoordinator.swift'];routes.append({'evidence':str((N/'permission-result.json').relative_to(R)),'scope':'Native media script-error FAIL and geolocation timeout INCONCLUSIVE; no native denial/support pass'})
 if i in [31,32,33,34,40]:lim='No qualified WebKit export/import/opaque-format or coherent multi-resource archive. Owned synthetic backup does not satisfy this website-data case.'
 elif i==37:lim='Deliberately deferred to requested public-release backlog; absence does not itself fail WS-F2. No26 compatibility claim or public distribution authorization.'
 elif i==35:lim='Policy contracts pass; native denial/positive Ask/Allow/revocation and persistent grants remain unqualified; latest native probe did not satisfy denial oracle.'
 elif i in [17,18]:lim='Native view fences/retirement are bounded; real acquired-key revocation, durable unlock and OS screen-lock/sleep/inactivity matrix incomplete.'
 elif i==36:lim='Static selected API/minimum audit only. Geolocation denial callback is27-only and availability-guarded. Not26 runtime proof.'
 else:lim='Original whole-case assertions/fault/platform/class matrix remains incomplete. See exact supporting routes and original definition; no related feature implies case satisfaction.'
 rows.append({'id':row['id'],'title':row['title'],'original_definition':row['original_definition'],'WSF0_history':row['historical_wsf0_disposition'],'WSF1_history':row['wsf1_whole_case_disposition'],'WSF2_status':status,'implementation_paths':paths,'evidence_routes':routes,'test_types':['native integration/restart','contract/fake'],'remaining_limitations':lim,'owner_ADR_PQR_status_changed':False})
save(E/'wks-dispositions.json',{'scope':'Overlay only; historical definitions/outcomes immutable','rows':rows,'summary':dict(collections.Counter(x['WSF2_status'] for x in rows)),'no_AC_EXP_PQR_closure':True})
gates=[('A','WebKit runtime','BLOCKED','Cache behavior, original full regression, selected/full clear, normal removal and bounded lock resources tested. Full native origin-record/date/in-flight/error matrix incomplete.'),('B','Protected persistence','BLOCKED','D2A-01 blocks actual protected catalog open/transactions/migrations/recovery; schema/gates tested only.'),('C','Keychain','BLOCKED','Real adapter attempts return-34018;0 valid signing identities. No successful item/ACL read/restart/rotation/recovery qualification.'),('D','Profile security','BLOCKED','Native views fenced/retired; protected key/unlock/durable receipts and full OS trigger/transfer/concurrency guarantees incomplete.'),('E','Permissions','BLOCKED','Core policy tests pass; native media denial oracle FAIL/script-error, geolocation INCONCLUSIVE/timeout; positives and persistent grants blocked.'),('F','Backup/restore','BLOCKED','Actual CryptoKit/synthetic-file slice passes; real protected source/import, full categories/custody/migrations/process recovery incomplete.'),('G','Regression/unified recovery','BLOCKED','82 retained fake tests and full WSF1 native regression pass their scopes; cross-component actual persisted/key/backup recovery remains blocked.'),('H','Closeout','PASS_CONTRACT','Required reports, evidence, traceability and preservation prepared; final commit/worktree receipt supplied by handoff after local commit. Not a runtime/security PASS.')]
save(E/'acceptance-gates.json',{'milestone':'WS-F2 INCOMPLETE — Required implementation or safety gates remain unmet.','gates':[{'gate':g,'name':name,'status':status,'basis':basis} for g,name,status,basis in gates],'macos26':'Deliberately deferred; not a WS-F2 implementation failure','public_distribution_authorized':False})
# Complete required reports, using only exact current evidence and per-suite identities.
title='''# WS-F2 actual qualification results

2026-11-09. **WS-F2 INCOMPLETE — Required implementation or safety gates remain unmet.** Primary actual environment: macOS27.2/26B123 arm64, Swift6.4.2/SDK27.2, WebKit22625.2.8.11.9. macOS26.0/latest26.x are deliberately deferred under this task, not passed and not themselves a WS-F2 implementation failure.

| Canonical suite | Actual result | Identity/scope |
|---|---|---|
| Retained full WS-F1 native regression |475 PASS_NATIVE observations,2 HTTP-cache INCONCLUSIVE,0 failures;39 app processes/12 deliberate terminations | `native-113327653483`, production build `f2-build-113022470426` |
| New WebKit/cache/lock/permission |36 PASS_NATIVE observations,4 BLOCKED,1 INCONCLUSIVE,1 FAIL;15 processes | `f2-webkit-native-114029856396`, final test-host build `f2-build-113900589907` |
| Native Keychain/owned backup |16 PASS_NATIVE observations,2 PASS_CONTRACT admission checks,6 BLOCKED,0 failures;3 processes | `f2-security-native-113238831637`, production build `f2-build-113022470426` |
| Contract/model/fake suite |23 PASS_CONTRACT,2 PASS_FAKE_ONLY,0 failures;25 named tests | `f2-contracts-113307401411` |
| Original fake suite |82 PASS_FAKE_ONLY,0 failures/skips/uncompleted | `attempt-112058889226`; original providers/tests preserved |

Counts remain separate. Do not add historical runs, convert observations to unique WKS cases, combine fake/native totals or claim one binary passed every suite. Only qualification-host instrumentation changed after the production regression build; shared product-source hashes are reconciled in the implementation-identity record. The final host executable SHA256 is `d933ae466707edcdd39936cdcdddeceddfc5b17ae2fd746296d6b64ded938c9a`; the production regression build is `17897e1450048796e69b4225ffeda47b2fd6e997dba2bb58ea3948034bf64d47`.

## What the native evidence demonstrates

The retained regression covers explicit persistent/private assignment, tested storage-class isolation/sharing/relaunch, switching, private retirement, localStorage clear, normal remove and11 exact lifecycle cutpoints plus private death. Original HTTP-cache persistence observations remain inconclusive; they are not retroactively upgraded.

New controlled HTTP evidence shows live-profile response reuse, distinct A/B responses, view reconstruction behavior, new network retrieval after clean/abrupt process restart, in-process pre-clear positive controls and fresh response after selected/full clearing. Public callbacks/identifier absence confirm normal removal. These are response/server observations, not disk-file persistence or erasure guarantees.

Actual lock checks cover two views/windows, another profile, blocked old-view navigation, key-cache absence, outstanding navigation, repeated safe convergence, actual lock-fence child death and fresh-process conservative locking without a creating factory. No real key had been acquired; no durable protected lock/unlock receipt or all-OS-trigger guarantee follows.

Keychain missing-item calls reach the OS. Creation/delete return-34018; acquisition returns-25300 after creation failed. Host has0 valid code-signing identities. The required data-protection/userPresence ACL is unchanged. Successful key creation/read/duplicate/rotation/recovery is BLOCKED, not a native pass.

The backup tests perform real AES-GCM/HKDF and synthetic owned-file operations: authenticated roundtrip, fresh encryption, tamper/truncation/trailing/wrong-key/wrong-profile refusal, deletion filtering, unknown-lineage/private/destination controls, no overwrite and incomplete-stage nonpublication. Real catalog source/import and recovery custody remain BLOCKED.

## Actual permission failure and incomplete runs

The final media fixture returned `script-error` before its native delegate was observed, so it failed the expected-denial oracle. Geolocation returned `timeout`, no delegate observed, and remains INCONCLUSIVE. Positive Ask/Allow is BLOCKED. The native host exited normally and retained its retired synthetic checkpoint; the sequence stopped and did not claim successful permission cleanup. No positive device support or verified denial is inferred from script failure.

Earlier permission probing hit the100-second parent timeout and its exact owned process was killed; that FAIL remains. New5-second script completion and phase markers provided a bounded result rather than relabeling the timeout Passed. No unchanged retry loop continues.

Earlier compile failure from unhandled ID construction and a source-changed-during-test runner failure are retained. The first Keychain restart oracle incorrectly required existence after blocked creation; it failed and was corrected to BLOCKED plus missing-item control. An earlier repeated-lock oracle required identical terminal state despite references draining; the corrected postcondition permits RecoveryRequired→Locked only after empty resources/no lease, with the original failure preserved. All attempted builds/runs have separate outputs/hashes.

## Not executed / remaining mandatory qualification

Actual protected SQLCipher catalog create/open/transaction/migration/corruption recovery, successful userPresence Keychain lifecycle, loaded-key lock revocation/authenticated unlock/OS-trigger/transfer matrix, positive native permission/grant revocation, coherent production backups/import/custody/cross-Mac recovery, native in-flight/partial/dropped-callback error routes, website export/backup and release gates remain blocked or unexecuted. No provider/PQR runtime operation or database open/create occurred. Actual26.0/latest26.x remains a deferred release backlog, with public distribution still unauthorized.
'''
title+='\n[Canonical records]('+REL+'results/canonical-attempts.json) · [per-case inventory]('+REL+'case-inventory.json) · [all attempts]('+REL+'results/attempt-history.json) · [cache analysis]('+REL+'results/cache-analysis.json) · [gates]('+REL+'acceptance-gates.json).\n'
(M/'m1-wsf2-qualification-results.md').write_text(title)
trace='# WS-F2 WKS traceability\n\n2026-11-09. All40 original definitions and mappings remain byte-for-byte equivalent in the [overlay]('+REL+'wks-dispositions.json). Historical WS-F0/WS-F1 outcomes are separate immutable columns. No AC/EXP/PQR is closed.\n\nWhole-case overlay: **4 PASS_FAKE_ONLY,1 PASS_CONTRACT,34 BLOCKED,1 NOT_EXECUTED**. WKS-037 is deliberately deferred to the requested release backlog; absence of26 is not treated as WS-F2 implementation failure. New native contributions remain bounded; related implementation does not imply original case satisfaction.\n\n| WKS / title | WS-F0 | WS-F1 | WS-F2 | Remaining limitation |\n|---|---|---|---|---|\n'
for x in rows:trace+='| '+x['id']+' '+x['title']+' | '+x['WSF0_history']+' | '+x['WSF1_history']+' | '+x['WSF2_status']+' | '+x['remaining_limitations']+' |\n'
trace+='\nImplementation paths, test modes, correlated case IDs/results, requirement/owner/ADR/experiment mapping and evidence references are in each machine row. Case-level results are not inferred from a parent suite. Native Keychain/owned-data encryption does not qualify SQLCipher PQR or WebKit backup cases. Persistent grants, real key/OS lock barriers and native positive permission support remain blocked.\n'
(M/'m1-wsf2-wks-traceability.md').write_text(trace)
close='''# WS-F2 storage/security closeout

2026-11-09. **WS-F2 INCOMPLETE — Required implementation or safety gates remain unmet.** Independent runtime/security components were implemented and tested, but the protected catalog, successful Keychain lifecycle, full unlock/permission and production backup/recovery gates are not complete. No overall security, engine or release PASS is issued.

Starting branch `timeline`, clean HEAD `21ad0b0ca91ed0777e873fd8233290e4f12f2e96`, matching the owner baseline. Final implementation commit is the commit containing this report; exact SHA and postcommit working-tree state are supplied in the handoff (`git log -1 --format=%H -- docs/architecture/phase-5/reports/M1/m1-wsf2-closeout.md` avoids a self-referential embedded hash). Local commit only; no push/branch switch/destructive reset.

[WebKit hardening](m1-wsf2-webkit-runtime-hardening.md) · [Protected catalog](m1-wsf2-protected-catalog.md) · [Keychain](m1-wsf2-keychain-integration.md) · [Locking](m1-wsf2-profile-locking.md) · [Permissions](m1-wsf2-permission-policy.md) · [Backup/restore](m1-wsf2-backup-and-restore.md) · [Recovery](m1-wsf2-recovery-and-reconciliation.md) · [Plan](m1-wsf2-qualification-plan.md) · [Actual results](m1-wsf2-qualification-results.md) · [WKS](m1-wsf2-wks-traceability.md) · [Risks](m1-wsf2-risks-and-limitations.md) · [Decision handoff](m1-wsf2-security-decision-proposal.md) · [Release backlog](m1-wsf2-public-release-qualification-backlog.md).

## Implemented components and actual boundaries

The existing AppKit app consumes the same native storage module/Core/Ports. Normal startup now wires the explicit protected-catalog gate, real Keychain broker, Core lock/permission/recovery policy and public AppKit lifecycle hooks; it automatically creates no profile, website store/view or key. Production persistent access stays unavailable. Debug qualification uses synthetic memory metadata and actual WebKit/Security/CryptoKit/files, never user data or a replacement plaintext product database.

| Path | Actual change |
|---|---|
| `qualification/webkit-storage-f0/Sources/BrowserDomain/SecurityModels.swift` | Opaque lease, validated origin/request/ticket, lock/grant/category/deletion values |
| `.../BrowserPorts/SecurityPorts.swift` | Typed engine-independent key/barrier/auth contracts; no native secret/object/connection |
| `.../BrowserCore/PermissionCoordinator.swift` | Ask/Allow/Deny, bounded session grants/tickets, authority/epoch/revocation/private checks; persistent grants refused |
| `.../BrowserCore/ProfileSecurityCoordinator.swift` | Lock/unlock policy/epochs, key retirement, resource barrier, safe initial/repeated/concurrent outcomes |
| `.../BrowserCore/StorageRecoveryPolicy.swift` | Cross-component fail-closed eligibility; no automatic unlock/publication |
| `.../BrowserPersistence/ProtectedCatalog.swift` | Actual catalog-port integration gate plus schema/migration/transaction-publication planning; no DB executor/open under D2A-01 |
| `.../BrowserPersistence/OwnedBackupPolicy.swift` | Bounded persistent snapshot/selection and deletion-aware fresh-destination validation |
| `apps/browser-macos/StorageRuntime/Sources/BrowserNativeStorage/NativeKeychain.swift` | Real Security/LAContext/CSPRNG, exact ACL/item identity, opaque cache/revocation and coarse statuses; successful item access blocked |
| `.../NativeProfileBarrier.swift`, `NativeSecurityLifecycle.swift` | Actual Core/native retirement, public sleep/session/inactivity hooks, awaited app termination; full OS/loaded-key matrix unqualified |
| `.../NativePermissionMediator.swift` | Owned native media request→Core policy→bounded-origin/frame/current-state checks; positive routes disabled pending platform qualification |
| `.../CanonicalCBOR.swift`, `EncryptedOwnedBackup.swift` | Actual strict framing, AES-GCM/HKDF and native no-overwrite/incomplete-stage file slice; synthetic records only |
| `.../NativeStorageSession.swift`, `NativeWebKitStorage.swift` | Connect services, protected bootstrap, security fences/publication rechecks, public27-only geolocation denial guarded for26.0 target |
| `apps/browser-macos/Sources/Host/ApplicationDelegate.swift`, `MainWindowController.swift` | Compose gates/lifecycle, Debug-only F2 host and truthful protected-storage-unavailable window |
| `apps/browser-macos/Sources/Qualification/SecurityQualificationHost.swift` | Real app synthetic Keychain/backup/cache/lock/permission cases, bounded scripts and owned termination |
| `apps/browser-macos/StorageRuntime/Tests/StorageModelTests/SecurityContractTests.swift`, `BackupContractTests.swift` | New Core/catalog/recovery/framing/backup/fake tests; original cases preserved |
| `apps/browser-macos/Tools/wsf2.py`, `wsf2_native.py` | Reproducible bounded build/test/native orchestration/evidence; no provider path |
| `apps/browser-macos/Tools/wsf1.py` | Preserve old target while recognizing new F2 contract/fake labels separately |
| `apps/browser-macos/project.json`, `VezhamBrowser.xcodeproj/project.pbxproj` | Four uncached F2 targets and Debug source integration; no external dependency or entitlement change |
| App/runtime READMEs; M1 indexes | Current scoped usage and report links, historical narratives preserved |

Ellipses retain the preceding package source prefix. Complete exact paths/hashes are in changed-files/implementation manifests. Source pins, vendor verification, ADR/owner/OP policies, original Core lifecycle/fake providers/tests, Phase3 and all historical evidence remain preserved.

## Actual verification and acceptance gates

Primary platform: macOS27.2/26B123 arm64, Swift6.4.2/SDK27.2, WebKit22625.2.8.11.9. The final qualification host compiles at26.0 minimum with App Sandbox/Hardened Runtime retained; ad-hoc signature is not release or Keychain qualification.

Separate outcomes: retained full native regression475 PASS_NATIVE/2 HTTP-cache INCONCLUSIVE; new WebKit/cache/lock36 PASS_NATIVE/4 BLOCKED/1 INCONCLUSIVE/1 FAIL; native Keychain/backup16 PASS_NATIVE/2 PASS_CONTRACT/6 BLOCKED; contract suite23 PASS_CONTRACT+2 PASS_FAKE_ONLY; original fake suite82 PASS_FAKE_ONLY. Each suite has its own binary/source identity; the result report explains test-host-only changes and reconciles shared implementation hashes. No totals are combined across categories/revisions.

| Gate | Disposition and exact remaining work |
|---|---|
'''
for g,name,status,basis in gates:close+='| '+g+' '+name+' | '+status+' — '+basis+' |\n'
close+='''
## Remaining decisions and next milestone

1. Obtain an explicit D2A-01 owner disposition using the existing exact alternatives. No header/read/hash/copy/VFS exception or provider replacement is implied. Then qualify the pinned worker/VFS/authentication path before enabling catalog execution.
2. Provide a valid authorized signing/default-Keychain-group environment; rerun finite synthetic userPresence item cases. Do not weaken ACLs or introduce another key store.
3. Complete protected key/custody/catalog migrations, durable lock/grants and actual backup snapshot/import/recovery. The synthetic archive slice is not a user-ready backup feature.
4. Resolve the native media pre-delegate script failure and geolocation timeout with a finite API-availability/origin/frame probe before claiming support. Keep positive permission capability disabled; do not repeat unchanged prompts.
5. Follow the dedicated release backlog for actual26.0/latest26.x and all final signing/notarization/Gatekeeper/sandbox/updater/performance gates. Their deliberate deferral is not a WS-F2 implementation failure or public-distribution approval.

The missing catalog/provider, Keychain entitlement and full security/product workflows are why WS-F2 is INCOMPLETE. Core/native module boundaries are not security sandboxes. No complete browser readiness, secure erasure, per-profile WebKit encryption/cryptographic lock, full portable website backup, OS-wide private forensic cleanup or unconditional engine acceptance is claimed.

ADR0001 remains Proposed; WKWebView conditional; CEF evaluation-only. Aura, production Tamizhi, mandatory identity/cloud/local service and public distribution remain excluded. No keys/test secrets, provider runtime, browser database or personal data enter evidence. Product-owner review remains required before further implementation/release scope.
'''
(M/'m1-wsf2-closeout.md').write_text(close)
print('Canonical metadata,14 reports/traceability/gates and actual failure/deferred dispositions prepared')
