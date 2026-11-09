import json, subprocess, hashlib, re, ast, collections
from pathlib import Path
R=Path('/Users/vigneshwaranbhoj/Downloads/repo-labs/vx-browser')
E=R/'docs/architecture/phase-5/evidence/20261108T234332Z-webkit-storage-wsf1'
M=R/'docs/architecture/phase-5/reports/M1'
OLD=R/'docs/architecture/phase-5/evidence/20261108T221109Z-webkit-storage-wsf0'
N=E/'native-063248009165'; B=E/'build-062812696387'; T=E/'models-063737711735'; F=E/'attempt-001707035860'
def read(p): return json.loads(p.read_text())
def save(p,x): p.write_text(json.dumps(x,indent=2)+'\n')
def sha(p): return hashlib.sha256(p.read_bytes()).hexdigest()
for label,argv in [('final-signature',['codesign','-d','--verbose=4',read(B/'result.json')['bundle']]),('final-symbols',['nm','-u',read(B/'result.json')['bundle']+'/Contents/MacOS/VezhamBrowser']),('crash-binary-uuid',['dwarfdump','--uuid','/private/tmp/vx-wsf1-en247zq_/DerivedData/Build/Products/Debug/VezhamBrowser.app/Contents/MacOS/VezhamBrowser'])]:
 p=subprocess.run(argv,capture_output=True,text=True);save(E/'results'/f'{label}.json',{'argv':argv,'returncode':p.returncode,'stdout':p.stdout,'stderr':p.stderr})
limitations={5:'Same-profile localStorage sharing observed; full browsing-context/sessionStorage controls remain.',6:'Single controlled first-party origin and selected classes; partitions/HTTP-only/SameSite incomplete.',10:'Popups refused; positive inherited-configuration route unqualified.',17:'Complete engine/OS/key lock barrier unqualified.',19:'No independently attributed content-process termination.',20:'No independently attributed network-process fault.',22:'LocalStorage clear only; record/date/all-class matrix incomplete.',23:'Modified-since/record-selected deletion not executed.',25:'No forced real in-use removal error; fake rejection only.',28:'Before-call and after-callback deaths tested; issued-before-callback/platform callback-drop timeout not qualified.',29:'Missing established resource remains fake; no unsafe recreation probe.',31:'No website-data export/restore execution.',32:'No per-class export capability qualification.',33:'No opaque malformed-blob/partial-restore execution.',34:'No independent-Mac/version migration.',35:'Own logs/fail-closed delegates only; full permission/TCC/restore-grant matrix unqualified.',38:'No complete runtime at-rest/protection inventory.',39:'Native publication-journal failure tested; full opaque restore saga incomplete.',40:'Metadata-only publication policy; no complete archive implementation.'}
rows=[]
for old in read(OLD/'wks-dispositions.json')['rows']:
 i=int(old['id'][4:]);status='PASS_FAKE_ONLY' if i in [2,4,18,27] else 'PASS_CONTRACT' if i==36 else 'BLOCKED'
 rows.append({'id':old['id'],'title':old['title'],'original_definition':old['original_definition'],'historical_wsf0_disposition':old['WSF0_disposition'],'historical_fake_test_ids':old['test_ids'],'wsf1_whole_case_disposition':status,'macos26_qualification':'BLOCKED','evidence':str(N.relative_to(R))+'/case-results.json','limitation':'Static selected-public-API/compiled-minimum audit only; no runtime qualification.' if i==36 else 'Bounded model branch only, never native qualification.' if status=='PASS_FAKE_ONLY' else 'Actual26.0/latest26.x absent. '+limitations.get(i,'Discovery contributes only its exact fixture/class/lifecycle subset.')})
save(E/'wks-dispositions.json',{'kind':'Overlay only; original40 definitions/outcomes unchanged','rows':rows,'summary':dict(collections.Counter(x['wsf1_whole_case_disposition'] for x in rows)),'no_ac_exp_pqr_closure':True})
vectors=[
('Descriptor missing/corrupt/unsupported',['F1-MOD-002','F1-GUARD-003'],None,'Contract rejection before effects'),
('Store resolution failure',['F0-CON-003'],None,'Fake provider unavailable'),
('Duplicate creation',['F0-CAT-003','F0-CON-007'],'F1-NAT-IDEMPOTENT-*','Receipt replay; no second factory'),
('Assignment failure',['F0-CON-004','F1-GUARD-002'],None,'Contract/fake wrong assignment rejects before constructor'),
('Construction failure',['F0-CON-005'],None,'Fake constructor failure; forced native exception not executed'),
('Publication interrupted',['F1-MOD-005'],'cut-04-publication','Host death after publication, before journal finalization'),
('Missing native resource',['F0-REC-002'],None,'Fake missing established resource; no native established-missing fixture'),
('Conflicting catalog/native state',['F0-REC-006','F0-REC-010'],'cut-00-creation-intent-reconcile','Fake conflicts plus native unfinished/missing mapping'),
('Unknown outcome',['F0-DEL-007','F0-REC-005'],'cut-09-remove-callback-reconcile','Completion lost to Core by host death'),
('Private termination during use',['F0-PRI-008'],'03b-private-interrupted;03c-private-restart','Actual child termination/relaunch, no private restoration'),
('Clear API failure',['F0-DEL-009'],None,'Fake only; public native clear has no error parameter'),
('Clear partial/uncertain',['F0-DEL-009'],'cut-06-clear-callback-reconcile','Fake partial/error; native interrupted finalization'),
('Clear termination before finalization',['F0-REC-004'],'cut-05-clear-request;cut-06-clear-callback','Native before-call/after-callback, not issued-before-callback'),
('Removal outstanding view reference',['F0-LIF-002','F0-DEL-005'],None,'Fake held owner; no forced real in-use API error'),
('Removal API failure',['F0-DEL-008'],None,'Fake error; historical errors not new qualification'),
('Callback not observed',['F0-DEL-007','F0-REC-005'],'cut-09-remove-callback','Caller completion lost after host death; platform callback-drop timeout unexecuted'),
('Removal termination before finalization',['F0-REC-004'],'cut-08-remove-request;cut-09-remove-callback','Pending tombstone stays fenced'),
('Wrong-store attempt',['F0-CON-004','F0-INT-005','F1-GUARD-002'],None,'Contract/fake reject before API effect'),
('Switch during outstanding work',['F0-LIF-011','F0-LIF-012'],None,'Fake source-generation changes; suspended native switch not executed'),
('Duplicate lifecycle operation',['F0-LIF-004','F0-CON-007'],'F1-NAT-ACTIVATE-REPLAY-*','Busy while pending; terminal replay has no native effect'),
('Concurrent close/clear',['F1-FAKE-001'],None,'Both deterministic orderings reject opposing work with Busy and zero effects'),
('Repeated reconciliation',['F0-REC-001'],'cut-*-reconcile/F1-NAT-RECOVERY-REPEATED-*','New process, interrupted scope fenced, no creating factory')]
fm=[]
for i,(title,ids,route,detail) in enumerate(vectors,1):
 fm.append({'id':f'F1-FI-{i:02d}','area':title,'initial_state':'Fresh descriptor/provisioning for creation; otherwise owned active/quiescent/retired scope defined by referenced test','injection':detail,'expected_transition':'Invalid request rejects without effect; admitted uncertain work becomes quarantined, never false success','fence':'No acquisition/navigation/publication or stale completion after fence; independent valid scopes stay separate','observable_result':'Exact typed result, callback/observation, or owned process signal in referenced artifact','recovery':'Pending/conflicting/unknown state never recreates or silently reactivates; repeated reconciliation remains noncreating','supporting_tests':ids,'native_route':route or 'NOT_EXECUTED','coverage':'contract/fake' if route is None else 'contract/fake plus native discovery','evidence':str((N if route else T if ids[0].startswith('F1-') else F).relative_to(R)),'limitation':'No macOS26 qualification. '+detail})
save(E/'failure-matrix.json',{'required_categories':22,'rows':fm,'scope':'Support coverage, not22 native passes'})
history=[]
for p in sorted(E.glob('*/result.json')):
 d=read(p);history.append({'path':str(p.relative_to(R)),'status':d.get('status',d.get('nativeQualification')),'phase':d.get('phase'),'count':d.get('count',d.get('passed_test_count',d.get('discoveryPassedObservations'))),'returncode':d.get('returncode'),'failedNativeObservations':d.get('discoveryFailedObservations')})
save(E/'results/attempt-history.json',history)
save(E/'results/canonical-attempts.json',{'native':str(N.relative_to(R)),'native_build':str(B.relative_to(R)),'diagnostic_revision':'diagnostic-build-001154431303','contract_and_additional_fake':str(T.relative_to(R)),'retained_f0':str(F.relative_to(R)),'no_aggregation_across_revisions':True})
save(E/'results/non-execution-and-boundaries.json',{'direct_SQLCipher_provider_PQR_execution':False,'Vezham_owned_database_open_creation':False,'direct_Vezham_Keychain_API':False,'engine_internal_database_credential_activity':'WebKit-managed; not claimed absent','real_user_profiles_or_data':False,'native_macos26':False,'Developer_ID_notarization_release':False,'private_API_default_store_remedy':False,'historical_prototype_or_original_store_removal':False,'website_backup_export_import':False,'public_distribution_push':False})
native_cases=read(N/'case-results.json');attempts=read(N/'attempts.json')
save(E/'results/qualification-summary.json',{'host':'macOS27.2/26B123 arm64; Swift6.4.2 SDK27.2 WebKit22625.2.8.11.9','source_native_binary':read(B/'result.json')['binarySHA256'],'observations':len(native_cases),'native_discovery_statuses':dict(collections.Counter(x['status'] for x in native_cases)),'distinct_case_labels':len(set(x['id'] for x in native_cases)),'app_launches':len(attempts),'intentional_terminations':sum(x['expectedKill'] for x in attempts),'retained_fake':read(F/'result.json')['passed_test_count'],'additional_fake':read(T/'result.json')['additionalFakeCount'],'contracts':read(T/'result.json')['contractCount'],'macos26_qualification':'BLOCKED','release_authorized':False})
assert len(rows)==40 and len(fm)==22
print('Created40-case overlay,22 failure categories, canonical history and qualification summary')
