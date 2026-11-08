#!/usr/bin/env python3
"""Official metadata + immutable source retrieval; never downloads a prebuilt binary."""
from pathlib import Path,PurePosixPath
import datetime,hashlib,io,json,re,tarfile,urllib.request
E=Path(__file__).resolve().parent.parent
S=E/'sources'
W=Path('/private/tmp/vx-m1-provider-fixtures-20261108T113403Z')
W.mkdir(exist_ok=True)
H={'User-Agent':'VX-M1-source-qualification','Accept':'application/vnd.github+json'}
def get(name,url):
 with urllib.request.urlopen(urllib.request.Request(url,headers=H),timeout=30) as r:
  data=r.read(64*1024*1024+1);status=r.status
 if len(data)>64*1024*1024:raise RuntimeError('bounded retrieval size exceeded')
 d=json.loads(data);(S/(name+'.json')).write_text(json.dumps({'time':datetime.datetime.now(datetime.timezone.utc).isoformat(),'url':url,'status':status,'data':d},indent=2)+'\n');return d
ref=json.loads((S/'tag-ref.json').read_text())['data'];obj=ref['object']
tag=get('annotated-tag',obj['url']) if obj['type']=='tag' else None
commit=(tag['object']['sha'] if tag else obj['sha'])
if not re.fullmatch('[0-9a-f]{40}',commit):raise RuntimeError('invalid immutable commit')
meta=get('commit','https://api.github.com/repos/sqlcipher/sqlcipher/commits/'+commit)
if meta['sha']!=commit:raise RuntimeError('commit metadata mismatch')
tree=get('tree','https://api.github.com/repos/sqlcipher/sqlcipher/git/trees/'+meta['commit']['tree']['sha']+'?recursive=1')
if tree.get('truncated'):raise RuntimeError('cannot verify truncated tree')
url='https://codeload.github.com/sqlcipher/sqlcipher/tar.gz/'+commit
with urllib.request.urlopen(urllib.request.Request(url,headers=H),timeout=45) as response:archive=response.read(64*1024*1024+1)
if len(archive)>64*1024*1024:raise RuntimeError('archive exceeds bounded source size')
tar_path=W/'sqlcipher-source.tar.gz';tar_path.write_bytes(archive)
root=W/('sqlcipher-'+commit)
if root.exists():raise RuntimeError('refuse overwrite existing source directory')
expected={x['path']:x for x in tree['tree'] if x['type']=='blob'};verified=[]
with tarfile.open(fileobj=io.BytesIO(archive),mode='r:gz') as tf:
 members=tf.getmembers();prefix=members[0].name.split('/')[0]
 for member in members:
  parts=PurePosixPath(member.name).parts
  if not parts or parts[0]!=prefix or '..' in parts:raise RuntimeError('unsafe source archive path')
  rel='/'.join(parts[1:])
  if not rel or member.isdir():continue
  if member.issym():payload=member.linkname.encode()
  elif member.isfile():payload=tf.extractfile(member).read()
  else:raise RuntimeError('unexpected non-source tar member')
  x=expected.get(rel)
  if x is None:raise RuntimeError('archive member absent from immutable tree: '+rel)
  blob=hashlib.sha1(b'blob '+str(len(payload)).encode()+b'\0'+payload).hexdigest()
  if blob!=x['sha']:raise RuntimeError('immutable blob mismatch: '+rel)
  if member.issym():raise RuntimeError('source symlink requires explicit build review: '+rel)
  verified.append({'path':rel,'git_blob_sha1':blob,'sha256':hashlib.sha256(payload).hexdigest(),'bytes':len(payload),'mode':x['mode']})
  target=root/rel;target.parent.mkdir(parents=True,exist_ok=True);target.write_bytes(payload);target.chmod(0o755 if x['mode']=='100755' else 0o644)
if {x['path'] for x in verified}!=set(expected):raise RuntimeError('source tree inventory incomplete')
version=(root/'VERSION').read_text().strip()
if version!='3.54.1':raise RuntimeError('unexpected SQLite version: '+version)
record={'upstream':'https://github.com/sqlcipher/sqlcipher','tag':'v4.20.0','tag_object':obj['sha'],'commit':commit,'tree':meta['commit']['tree']['sha'],'release_immutable':False,'commit_verification':meta['commit'].get('verification'),'tag_verification':tag.get('verification') if tag else None,'archive_url':url,'archive_sha256':hashlib.sha256(archive).hexdigest(),'archive_bytes':len(archive),'archive_vendor_checksum':None,'all_archive_blob_ids_match_immutable_upstream_tree':True,'verified_file_count':len(verified),'source_directory':str(root),'sqlite_version':version,'qualified_provider':False,'downloaded_prebuilt_binary':False}
(E/'results/provider-source-record.json').write_text(json.dumps(record,indent=2)+'\n');(S/'source-file-manifest.json').write_text(json.dumps(verified,indent=2)+'\n');print(json.dumps(record,indent=2))
