"""Compare authenticated public source bytes to complete pinned Git tree; execute nothing."""
import datetime,gzip,hashlib,io,json,pathlib,posixpath,stat,urllib.request,urllib.error,zipfile
HERE=pathlib.Path(__file__).resolve().parent
PIN='355d4db92d3404e71faa8088d071a71d767807f4'
TREE='b3aa6f0a71413a40df4c968d357bbbbee61b42cb'
sig=json.loads((HERE/'results/signature-verification.json').read_text())
key=json.loads((HERE/'results/key-structure-review.json').read_text())
if sig['cryptographic_signature_status']!='PASS' or key['status']!='PASS':raise SystemExit('Cryptographic prerequisite not satisfied; no extraction')
env=json.loads((HERE/'results/verifier-environment.json').read_text())
acq=json.loads((HERE/'results/vendor-acquisition.json').read_text())
archive_record=next(x for x in acq['artifacts'] if x['filename']=='sqlcipher-4.20.0.zip')
archive=HERE/archive_record['entity_artifact']
if hashlib.sha256(archive.read_bytes()).hexdigest()!=archive_record['entity_sha256']:raise SystemExit('Archive changed after acquisition/verification')
def put(name,obj):
 with (HERE/name).open('x') as f:json.dump(obj,f,indent=2);f.write('\n')
def fetch(name,url):
 meta={'url':url,'time':datetime.datetime.now(datetime.timezone.utc).isoformat(),'method':'GET','authentication':'none','TLS':'default certificate validation'}
 req=urllib.request.Request(url,headers={'User-Agent':'Vezham-M1-authenticated-source-comparison','Accept':'application/vnd.github+json','Accept-Encoding':'identity','X-GitHub-Api-Version':'2022-11-28'})
 try:
  try:response=urllib.request.urlopen(req,timeout=30)
  except urllib.error.HTTPError as ex:response=ex
  with response:raw=response.read(4*1024*1024+1);meta.update(status=response.status,final_url=response.url,content_encoding=response.headers.get('Content-Encoding'))
  if len(raw)>4*1024*1024:raise ValueError('Git metadata exceeded bound')
  with (HERE/'sources'/(name+'.raw')).open('xb') as f:f.write(raw)
  meta.update(raw_sha256=hashlib.sha256(raw).hexdigest(),raw_bytes=len(raw))
  if raw.startswith(b'\x1f\x8b'):
   with gzip.GzipFile(fileobj=io.BytesIO(raw)) as f:decoded=f.read(4*1024*1024+1)
   if len(decoded)>4*1024*1024:raise ValueError('Decoded metadata exceeded bound')
  else:decoded=raw
  with (HERE/'sources'/(name+'.decoded.json')).open('xb') as f:f.write(decoded)
  if meta['status']!=200:raise ValueError('Git metadata HTTP '+str(meta['status']))
  data=json.loads(decoded)
 except Exception as ex:
  meta['error']=type(ex).__name__+': '+str(ex);put('sources/'+name+'.json',meta);raise
 put('sources/'+name+'.json',meta);return data
commit=fetch('comparison-pinned-commit','https://api.github.com/repos/sqlcipher/sqlcipher/git/commits/'+PIN)
tree=fetch('comparison-pinned-tree','https://api.github.com/repos/sqlcipher/sqlcipher/git/trees/'+TREE+'?recursive=1')
if commit['sha']!=PIN or commit['tree']['sha']!=TREE or tree['sha']!=TREE or tree.get('truncated'):raise SystemExit('Incomplete or wrong pinned Git source metadata')
entries=tree['tree'];by_path={x['path']:x for x in entries}
if len(by_path)!=len(entries):raise SystemExit('Duplicate Git tree paths')
# Recompute each directory Git object, including modes, names and child IDs.
groups={}
for item in entries:
 parent,name=posixpath.split(item['path']);groups.setdefault(parent,[]).append((name,item))
verified_trees=[]
for path in sorted(groups,key=lambda x:(x.count('/'),x),reverse=True):
 children=groups[path]
 def order(pair):return pair[0].encode()+(b'/' if pair[1]['type']=='tree' else b'')
 raw=b''
 for name,item in sorted(children,key=order):
  mode=item['mode'].lstrip('0')
  raw+=mode.encode()+b' '+name.encode()+b'\0'+bytes.fromhex(item['sha'])
 actual=hashlib.sha1(b'tree '+str(len(raw)).encode()+b'\0'+raw).hexdigest()
 expected=TREE if path=='' else by_path[path]['sha']
 if actual!=expected:raise SystemExit('Pinned tree object reconstruction mismatch: '+path)
 verified_trees.append({'path':path,'sha1':actual})
gitfiles={x['path']:x for x in entries if x['type']=='blob'}
other_git=[x for x in entries if x['type'] not in ['blob','tree']]
if other_git:raise SystemExit('Unsupported submodule/special Git object requires specification')
out=pathlib.Path(env['workspace'])/'authenticated-source';out.mkdir(mode=0o700,exist_ok=False)
items=[];seen=set();folded=set();total=0
with zipfile.ZipFile(archive) as z:
 infos=z.infolist()
 if len(infos)>10000:raise SystemExit('Archive file-count bound')
 file_infos=[i for i in infos if not i.is_dir()]
 names=[pathlib.PurePosixPath(i.filename) for i in file_infos]
 roots={n.parts[0] for n in names}
 root=next(iter(roots)) if len(roots)==1 and all(len(n.parts)>1 for n in names) else ''
 for info in sorted(infos,key=lambda x:x.filename):
  name=info.filename
  n=pathlib.PurePosixPath(name)
  if '\\' in name or n.is_absolute() or '..' in n.parts or not n.parts or '\0' in name:raise SystemExit('Unsafe archive path')
  if name in seen:raise SystemExit('Duplicate archive member')
  seen.add(name)
  if info.is_dir():continue
  relative=pathlib.PurePosixPath(*n.parts[1:]) if root else n
  path=relative.as_posix()
  if path.casefold() in folded:raise SystemExit('Case-colliding archive paths')
  folded.add(path.casefold())
  mode=info.external_attr>>16;kind=stat.S_IFMT(mode)
  if kind not in [0,stat.S_IFREG]:raise SystemExit('Special archive entry; no extraction')
  total+=info.file_size
  if total>512*1024*1024 or info.file_size>64*1024*1024:raise SystemExit('Uncompressed archive size bound')
  raw=z.read(info)
  dest=out/path;dest.parent.mkdir(mode=0o700,parents=True,exist_ok=True)
  with dest.open('xb') as f:f.write(raw)
  dest.chmod(0o600)
  blob=hashlib.sha1(b'blob '+str(len(raw)).encode()+b'\0'+raw).hexdigest()
  item={'path':path,'bytes':len(raw),'sha256':hashlib.sha256(raw).hexdigest(),'git_blob_sha1':blob,
        'zip_unix_mode':oct(mode),'zip_executable':bool(mode&0o111),'zip_create_system':info.create_system}
  items.append(item)
archivefiles={x['path']:x for x in items}
common=sorted(set(archivefiles)&set(gitfiles))
matches=[];diffs=[];mode_diffs=[]
for path in common:
 observed=archivefiles[path];expected=gitfiles[path]
 row={'path':path,'archive_sha256':observed['sha256'],'archive_git_blob_sha1':observed['git_blob_sha1'],'expected_git_blob_sha1':expected['sha'],'expected_git_mode':expected['mode'],'archive_bytes':observed['bytes'],'zip_unix_mode':observed['zip_unix_mode']}
 (matches if observed['git_blob_sha1']==expected['sha'] else diffs).append(row)
 if expected['mode']=='120000' or observed['zip_executable']!=(expected['mode']=='100755'):
  mode_diffs.append(row)
archive_only=[archivefiles[p] for p in sorted(set(archivefiles)-set(gitfiles))]
git_only=[gitfiles[p] for p in sorted(set(gitfiles)-set(archivefiles))]
version=(out/'VERSION').read_text() if (out/'VERSION').is_file() else None
exact=not archive_only and not git_only and not diffs
summary={'time':datetime.datetime.now(datetime.timezone.utc).isoformat(),'pin':PIN,'pinned_tree':TREE,
 'reconstructed_git_tree_objects':len(verified_trees),'archive_sha256':archive_record['entity_sha256'],
 'authenticated_before_extraction':True,'archive_common_root_removed':root,'extraction_directory':str(out),
 'archive_files':len(items),'git_files':len(gitfiles),'exact_byte_matches':len(matches),
 'archive_only_files':len(archive_only),'git_only_files':len(git_only),'content_differences':len(diffs),
 'mode_differences':len(mode_diffs),'total_uncompressed_bytes':total,'VERSION_contents':version,
 'source_top_level_entries':sorted({pathlib.PurePosixPath(x['path']).parts[0] for x in items}),
 'all_source_bytes_equivalent':exact,'all_file_modes_equivalent':not mode_diffs,
 'comparison_status':'PASS' if exact and not mode_diffs else 'INCONCLUSIVE',
 'classification':'Exact source files/bytes/modes' if exact and not mode_diffs else 'Differences require review; no equivalence inferred',
 'provider_or_archive_contents_executed':False,'extracted_files_nonexecutable_mode':'0600',
 'git_source_relationship':'Fresh exact commit/tree API plus complete recursive tree reconstructed to pinned root; every archive file compared against its pinned Git blob identity'}
put('results/archive-file-manifest.json',items)
put('results/pinned-tree-object-verification.json',verified_trees)
put('results/archive-to-commit-comparison.json',{'summary':summary,'exact_matches':matches,'archive_only':archive_only,'git_only':git_only,'content_differences':diffs,'mode_differences':mode_diffs})
print(json.dumps(summary,indent=2))
print('ARCHIVE_ONLY_PATHS',[x['path'] for x in archive_only]);print('GIT_ONLY_PATHS',[x['path'] for x in git_only]);print('CONTENT_DIFFERENCE_PATHS',[x['path'] for x in diffs])

