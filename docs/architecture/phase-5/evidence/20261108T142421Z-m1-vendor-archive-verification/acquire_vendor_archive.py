"""Acquire official vendor bytes; no extraction, builds or provider execution."""
import concurrent.futures,datetime,gzip,hashlib,io,json,pathlib,urllib.request,urllib.error,urllib.parse,html.parser
HERE=pathlib.Path(__file__).resolve().parent
LIMIT=128*1024*1024
class Redirects(urllib.request.HTTPRedirectHandler):
 def __init__(self):self.steps=[]
 def redirect_request(self,req,fp,code,msg,headers,newurl):
  if urllib.parse.urlsplit(newurl).scheme!='https':raise ValueError('HTTPS downgrade refused')
  self.steps.append({'from':req.full_url,'to':newurl,'status':code})
  return super().redirect_request(req,fp,code,msg,headers,newurl)
def acquire(name,url,filename,maxbytes=LIMIT):
 redirect=Redirects();opener=urllib.request.build_opener(redirect)
 meta={'time':datetime.datetime.now(datetime.timezone.utc).isoformat(),'requested_url':url,'method':'GET','TLS':'default certificate validation','authentication':'none','filename':filename,'maximum_bytes':maxbytes}
 req=urllib.request.Request(url,headers={'User-Agent':'Vezham-M1-vendor-archive-verification','Accept-Encoding':'identity','Accept':'*/*'})
 try:
  try:response=opener.open(req,timeout=30)
  except urllib.error.HTTPError as ex:response=ex
  rawpath=HERE/'sources'/filename
  with response,rawpath.open('xb') as f:
   meta.update(status=response.status,final_url=response.url,content_encoding=response.headers.get('Content-Encoding'),content_type=response.headers.get('Content-Type'),etag=response.headers.get('ETag'),last_modified=response.headers.get('Last-Modified'))
   size=0;hasher=hashlib.sha256()
   while True:
    chunk=response.read(1024*1024)
    if not chunk:break
    size+=len(chunk)
    if size>maxbytes:raise ValueError('Response exceeded bound')
    f.write(chunk);hasher.update(chunk)
  meta.update(bytes=size,sha256=hasher.hexdigest(),raw_artifact='sources/'+filename,redirects=redirect.steps)
  raw=rawpath.read_bytes()
  if meta.get('content_encoding')=='gzip' or (filename.endswith('.html') and raw.startswith(b'\x1f\x8b')):
   with gzip.GzipFile(fileobj=io.BytesIO(raw)) as f:decoded=f.read(maxbytes+1)
   if len(decoded)>maxbytes:raise ValueError('Decoded entity exceeds bound')
   entity=rawpath.with_name(rawpath.name+'.decoded')
   with entity.open('xb') as f:f.write(decoded)
   meta.update(entity_artifact=str(entity.relative_to(HERE)),entity_sha256=hashlib.sha256(decoded).hexdigest(),entity_bytes=len(decoded))
  else:meta.update(entity_artifact=meta['raw_artifact'],entity_sha256=meta['sha256'],entity_bytes=size)
 except Exception as ex:meta['error']=type(ex).__name__+': '+str(ex)
 with (HERE/'sources'/ (name+'.json')).open('x') as f:json.dump(meta,f,indent=2);f.write('\n')
 return meta
page=acquire('vendor-verification-page','https://www.zetetic.net/sqlcipher/verify/','vendor-verification-page.html',4*1024*1024)
if page.get('status')!=200 or 'error' in page:raise SystemExit('Official source page acquisition BLOCKED')
class Links(html.parser.HTMLParser):
 def __init__(self):super().__init__();self.links=[]
 def handle_starttag(self,tag,attrs):
  d=dict(attrs)
  if tag=='a' and 'href' in d:self.links.append(urllib.parse.urljoin(page['final_url'],d['href']))
parser=Links();parser.feed((HERE/page['entity_artifact']).read_text())
jobs=[
 ('vendor-source-zip','https://www.zetetic.net/downloads/sqlcipher/verify/4.20.0/sqlcipher-4.20.0.zip','sqlcipher-4.20.0.zip'),
 ('vendor-detached-signature','https://www.zetetic.net/downloads/sqlcipher/verify/4.20.0/sqlcipher-4.20.0.zip.sig','sqlcipher-4.20.0.zip.sig'),
 ('vendor-public-key','https://www.zetetic.net/security/support_zetetic_net_public_key.gpg','support_zetetic_net_public_key.gpg')]
for _,url,_ in jobs:
 if url not in parser.links:raise SystemExit('Expected exact vendor artifact link not published; BLOCKED: '+url)
with concurrent.futures.ThreadPoolExecutor(max_workers=3) as pool:records=list(pool.map(lambda job:acquire(*job),jobs))
with (HERE/'results/vendor-acquisition.json').open('x') as f:json.dump({'page':page,'artifacts':records,'source_link_validation':'all exact artifact URLs present in current official page','archive_extracted':False},f,indent=2);f.write('\n')
print(json.dumps(records,indent=2))
raise SystemExit(0 if all(x.get('status')==200 and not x.get('error') for x in records) else 1)

