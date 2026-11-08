#!/usr/bin/env python3
"""Reads only the exact retained disposable identity; writes new evidence only."""
from pathlib import Path
import datetime,hashlib,json,os,plistlib,subprocess
E=Path(__file__).resolve().parent
R=next(p for p in E.parents if (p/'.git').exists())
OLD=R/'docs/architecture/phase-5/evidence/20261108T094414Z-m1-consolidated-closeout'
O=E/'results'
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
def command(name,args):
    try:
        p=subprocess.run(args,capture_output=True,text=True,timeout=30)
        d={'time':datetime.datetime.now(datetime.timezone.utc).isoformat(),'command':args,'returncode':p.returncode,'stdout':p.stdout,'stderr':p.stderr}
    except (OSError,subprocess.TimeoutExpired) as ex:d={'command':args,'error':str(ex),'returncode':None}
    (O/(name+'.json')).write_text(json.dumps(d,indent=2)+'\n');return d
f=json.loads((OLD/'fixtures.json').read_text())
container=Path.home()/'Library/Containers/internal.vx.M1Validation.run20261108T094414Z'
root=container/'Data/Library/WebKit/WebsiteDataStore'
state={'time':datetime.datetime.now(datetime.timezone.utc).isoformat(),'bundle_id':'internal.vx.M1Validation.run20261108T094414Z','recorded_fixture_source':str((OLD/'fixtures.json').relative_to(R)),'root':str(root),'destructive_operations':False,'stores':[]}
for name in ['storeA','storeB']:
    id=f[name];p=root/id
    d={'name':name,'identifier':id,'expected_path':str(p),'present':p.exists(),'is_symlink':p.is_symlink(),'classification':'State unknown','files':[]}
    if p.is_symlink():d['reason']='Unexpected symlink; traversal forbidden.'
    elif p.exists():
        d['reason']='Directory present in exact disposable identity; logical integrity and API registry/completion not established.'
        for item in sorted(p.rglob('*')):
            if item.is_file() and not item.is_symlink():
                st=item.stat();d['files'].append({'relative_path':str(item.relative_to(p)),'bytes':st.st_size,'mode':oct(st.st_mode & 0o777),'uid':st.st_uid,'mtime_ns':st.st_mtime_ns,'sha256':sha(item)})
    else:d['reason']='Expected directory absent; absence alone is not confirmed API removal.'
    state['stores'].append(d)
meta=container/'.com.apple.containermanagerd.metadata.plist'
try:
    data=plistlib.loads(meta.read_bytes());state['container_identity_metadata']={k:v for k,v in data.items() if k in ['MCMMetadataIdentifier','MCMMetadataUUID'] and isinstance(v,str)}
except (OSError,ValueError) as ex:state['container_identity_metadata_error']=str(ex)
(O/'original-store-state.json').write_text(json.dumps(state,indent=2)+'\n')
crash=Path.home()/'Library/Logs/DiagnosticReports/VXM1Validation-2026-11-08-152729.ips'
d=json.loads('\n'.join(crash.read_text().splitlines()[1:]));imgs=d['usedImages'];i=d['faultingThread']
extract={k:d.get(k) for k in ['procName','pid','captureTime','procLaunch','exception','termination','faultingThread']}
extract.update({'source_path':str(crash),'source_sha256':sha(crash),'frames':[{'image':imgs[x['imageIndex']].get('name'),'symbol':x.get('symbol'),'imageOffset':x.get('imageOffset'),'symbolLocation':x.get('symbolLocation')} for x in d['threads'][i]['frames']],'app_image':[{k:x.get(k) for k in ['name','uuid','arch']} for x in imgs if x.get('name')=='VXM1Validation'],'privacy':'selected diagnostic fields; no raw memory or unrelated crash reports'})
(O/'cleanup-crash-extract.json').write_text(json.dumps(extract,indent=2)+'\n')
ps=command('process-snapshot',['ps','-axo','pid,ppid,comm'])
# Retain only names relevant to this disposable app or engine processes, not unrelated apps.
ps['stdout']='\n'.join(l for l in ps.get('stdout','').splitlines() if 'VXM1Validation' in l or 'com.apple.WebKit' in l)
(O/'process-snapshot.json').write_text(json.dumps(ps,indent=2)+'\n')
command('owned-open-handles',['lsof','-nP','+D',str(root)])
binary=Path('/private/tmp/vx-m1-native-20261108T094414Z/VXM1Validation.app/Contents/MacOS/VXM1Validation')
uuid=command('retained-binary-uuid',['xcrun','dwarfdump','--uuid',str(binary)])
(O/'retained-binary-hash.json').write_text(json.dumps({'sha256':sha(binary),'matches_original_cleanup_provenance':sha(binary)==json.loads((OLD/'results/cleanup-only-result.json').read_text())['binary_sha256'],'crash_image_uuid':extract['app_image'],'uuid_command_output':uuid.get('stdout')},indent=2)+'\n')
sdk=Path('/Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk')
apis={}
for rel,terms in [('System/Library/Frameworks/CryptoKit.framework/Modules/CryptoKit.swiftmodule/arm64e-apple-macos.swiftinterface',['struct HKDF','struct SymmetricKey','enum GCM']),('System/Library/Frameworks/Security.framework/Headers/SecAccessControl.h',['kSecAccessControlUserPresence']),('System/Library/Frameworks/Security.framework/Headers/SecItem.h',['kSecUseDataProtectionKeychain','kSecAttrAccessibleWhenUnlockedThisDeviceOnly','kSecAttrSynchronizable'])]:
    p=sdk/rel;apis[rel]={'present':p.exists(),'sha256':sha(p) if p.exists() else None,'declarations':[{'line':n,'text':s.strip()} for n,s in enumerate(p.read_text().splitlines(),1) if any(t in s for t in terms)] if p.exists() else []}
(O/'candidate-availability.json').write_text(json.dumps({'apple_sdk_declarations':apis,'sqlcipher_paths':{p:Path(p).exists() for p in ['/opt/homebrew/opt/sqlcipher','/usr/local/opt/sqlcipher']},'qualified_provider':False,'runtime_keychain_or_crypto_test_performed':False},indent=2)+'\n')
print(json.dumps({'states':[{k:v for k,v in x.items() if k!='files'} for x in state['stores']],'store_file_counts':[len(x['files']) for x in state['stores']],'crash_frame':extract['frames'][2],'new_cleanup_or_store_operations':False}))
