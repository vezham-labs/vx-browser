"""Follow only publisher-published artifact links; one bounded metadata retry after HTTP 504."""
import concurrent.futures,datetime,gzip,hashlib,io,json,pathlib,urllib.request,urllib.error
HERE=pathlib.Path(__file__).resolve().parent
LIMIT=4*1024*1024
JOBS=[
 ('vendor-package-key','https://www.zetetic.net/security/support_zetetic_net_public_key.gpg','asc'),
 ('vendor-source-420-detached-signature','https://www.zetetic.net/downloads/sqlcipher/verify/4.20.0/sqlcipher-4.20.0.zip.sig','sig'),
 ('pinned-commit-followup','https://api.github.com/repos/sqlcipher/sqlcipher/git/commits/355d4db92d3404e71faa8088d071a71d767807f4','body'),
 ('release-420-followup','https://api.github.com/repos/sqlcipher/sqlcipher/releases/tags/v4.20.0','body')]
def fetch(job):
 name,url,ext=job
 meta={'url':url,'time':datetime.datetime.now(datetime.timezone.utc).isoformat(),'method':'GET','authentication':'none','TLS':'default certificate validation','timeout_seconds':20,'maximum_response_bytes':LIMIT}
 headers={'User-Agent':'Vezham-M1-public-authenticity-evidence','Accept-Encoding':'identity'}
 if 'api.github.com' in url:headers.update({'Accept':'application/vnd.github+json','X-GitHub-Api-Version':'2022-11-28'})
 try:
  try:response=urllib.request.urlopen(urllib.request.Request(url,headers=headers),timeout=20)
  except urllib.error.HTTPError as err:response=err
  with response:
   raw=response.read(LIMIT+1);meta.update(status=response.status,final_url=response.url,content_type=response.headers.get('Content-Type'),content_encoding=response.headers.get('Content-Encoding'),pagination_link=response.headers.get('Link'))
  if len(raw)>LIMIT:raise ValueError('Response exceeds bound')
  meta.update(raw_artifact='sources/'+name+'.'+ext,sha256=hashlib.sha256(raw).hexdigest(),bytes=len(raw))
  with (HERE/meta['raw_artifact']).open('xb') as f:f.write(raw)
  if raw.startswith(b'\x1f\x8b'):
   with gzip.GzipFile(fileobj=io.BytesIO(raw)) as f:raw=f.read(LIMIT+1)
   if len(raw)>LIMIT:raise ValueError('Decoded response exceeds bound')
  meta.update(decoded_artifact='sources/'+name+'.decoded',decoded_sha256=hashlib.sha256(raw).hexdigest())
  with (HERE/meta['decoded_artifact']).open('xb') as f:f.write(raw)
 except Exception as err:meta['error']=type(err).__name__+': '+str(err)
 with (HERE/('sources/'+name+'.json')).open('x') as f:json.dump(meta,f,indent=2);f.write('\n')
 return {'name':name,**meta}
with concurrent.futures.ThreadPoolExecutor(max_workers=4) as pool:out=list(pool.map(fetch,JOBS))
with (HERE/'results/followup-acquisitions.json').open('x') as f:json.dump(out,f,indent=2);f.write('\n')
print(json.dumps([{k:v for k,v in x.items() if k in ['name','status','bytes','error']} for x in out],indent=2))

