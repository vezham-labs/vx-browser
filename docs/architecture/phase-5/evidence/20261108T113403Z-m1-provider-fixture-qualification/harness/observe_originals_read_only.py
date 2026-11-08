#!/usr/bin/env python3
"""Read exact original synthetic paths only; never calls WebKit or alters a store."""
from pathlib import Path
import datetime,hashlib,json,sys
E=Path(__file__).resolve().parent.parent
stage=sys.argv[1]
assert stage in ['before','after']
root=Path.home()/'Library/Containers/internal.vx.M1Validation.run20261108T094414Z/Data/Library/WebKit/WebsiteDataStore'
stores=[]
for name,id in [('A','abb4ca2d-33dc-4d25-9c16-d135202c03e3'),('B','9ec735a8-b9eb-416c-994b-4b299c5ee5f5')]:
 p=root/id;d={'store':name,'identifier':id,'expected_path':str(p),'present':p.exists(),'symlink':p.is_symlink(),'logical_state':'UNKNOWN','files':[]}
 if p.exists() and not p.is_symlink():
  for f in sorted(p.rglob('*')):
   if f.is_file() and not f.is_symlink():
    data=f.read_bytes();st=f.stat();d['files'].append({'relative':str(f.relative_to(p)),'sha256':hashlib.sha256(data).hexdigest(),'bytes':len(data),'mtime_ns':st.st_mtime_ns})
 stores.append(d)
result={'time':datetime.datetime.now(datetime.timezone.utc).isoformat(),'stage':stage,'stores':stores,'registry_enumeration':False,'store_creation_or_removal':False}
(E/'results'/('original-store-'+stage+'.json')).write_text(json.dumps(result,indent=2)+'\n')
print(json.dumps({'stage':stage,'stores':[{'store':d['store'],'present':d['present'],'file_count':len(d['files']),'logical_state':d['logical_state']} for d in stores]}))
