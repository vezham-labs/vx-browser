"""Acquire public official evidence only; never install tools or execute provider code."""
import concurrent.futures, datetime, hashlib, html.parser, json, pathlib, re, urllib.request, urllib.error, urllib.parse

HERE = pathlib.Path(__file__).resolve().parent
PIN = '355d4db92d3404e71faa8088d071a71d767807f4'
TAG = '52252487a5cada9b430e8d4b20025790c5a6ba20'
DIGEST = 'fc5394c916beeabb1f43e2ac97d0827f36e8917f6675a00cca54537c32cb36a2'
LIMIT = 4 * 1024 * 1024

def save(path, raw):
    with (HERE/path).open('xb') as f: f.write(raw)

def fetch(name, url, extension='txt', api=False):
    meta = {'time': datetime.datetime.now(datetime.timezone.utc).isoformat(),
            'url': url, 'method': 'GET', 'default_TLS_certificate_validation': True,
            'authentication': 'none', 'timeout_seconds': 20, 'maximum_response_bytes': LIMIT}
    headers = {'User-Agent':'Vezham-M1-public-authenticity-evidence',
               'Accept':'application/vnd.github+json' if api else '*/*'}
    if api: headers['X-GitHub-Api-Version'] = '2022-11-28'
    try:
        response = urllib.request.urlopen(urllib.request.Request(url, headers=headers), timeout=20)
    except urllib.error.HTTPError as err:
        response = err
    except Exception as err:
        meta.update(status=None,error=type(err).__name__+': '+str(err))
        save('sources/'+name+'.json', (json.dumps(meta,indent=2)+'\n').encode())
        return meta, b''
    with response:
        raw = response.read(LIMIT+1)
        meta.update(status=response.status, final_url=response.url,
                    content_type=response.headers.get('Content-Type'),
                    etag=response.headers.get('ETag'), last_modified=response.headers.get('Last-Modified'),
                    pagination_link=response.headers.get('Link'))
    if len(raw)>LIMIT:
        meta['error']='Response exceeded bounded acquisition size; no complete evidence captured'
        raw=b''
    meta.update(bytes=len(raw),sha256=hashlib.sha256(raw).hexdigest(),
                raw_artifact='sources/'+name+'.'+extension)
    save(meta['raw_artifact'],raw)
    save('sources/'+name+'.json', (json.dumps(meta,indent=2)+'\n').encode())
    return meta,raw

jobs = [
 ('vendor-verification-instructions','https://www.zetetic.net/sqlcipher/verify/','txt',False),
 ('vendor-community','https://www.zetetic.net/sqlcipher/community/','txt',False),
 ('vendor-security','https://www.zetetic.net/security/','txt',False),
 ('vendor-release-420','https://www.zetetic.net/blog/2026/10/27/sqlcipher-4.20.0-release/','txt',False),
 ('vendor-sqlcipher-documentation','https://www.zetetic.net/sqlcipher/documentation/','txt',False),
 ('tag-reference','https://api.github.com/repos/sqlcipher/sqlcipher/git/ref/tags/v4.20.0','body.json',True),
 ('tag-object','https://api.github.com/repos/sqlcipher/sqlcipher/git/tags/'+TAG,'body.json',True),
 ('pinned-commit','https://api.github.com/repos/sqlcipher/sqlcipher/git/commits/'+PIN,'body.json',True),
 ('release-420','https://api.github.com/repos/sqlcipher/sqlcipher/releases/tags/v4.20.0','body.json',True),
 ('publisher-gpg','https://github.com/sjlombardo.gpg','asc',False),
 ('publisher-key-api','https://api.github.com/users/sjlombardo/gpg_keys','body.json',True),
 ('archive-attestations','https://api.github.com/repos/sqlcipher/sqlcipher/attestations/sha256:'+DIGEST,'body.json',True),
 ('attestation-api-documentation','https://docs.github.com/en/rest/repos/attestations','txt',False),
]
results={}
with concurrent.futures.ThreadPoolExecutor(max_workers=4) as pool:
    futures={pool.submit(fetch,*job):job[0] for job in jobs}
    for future in concurrent.futures.as_completed(futures):
        results[futures[future]]=future.result()

class Links(html.parser.HTMLParser):
    def __init__(self): super().__init__(); self.links=[]
    def handle_starttag(self,tag,attrs):
        if tag=='a':
            d=dict(attrs)
            if 'href' in d:self.links.append(d['href'])

links=[]
for name in ['vendor-verification-instructions','vendor-community','vendor-security','vendor-release-420','vendor-sqlcipher-documentation']:
    meta,raw=results[name]; text=raw.decode('utf-8','replace')
    parser=Links(); parser.feed(text)
    urls=parser.links+re.findall(r'\]\(([^)]+)\)',text)
    for value in urls:
        url=urllib.parse.urljoin(meta['url'],value)
        if re.search(r'(?:sign|\.sig|\.asc|\.gpg|pgp|verify|community|github|release|attest)',url,re.I):
            links.append({'source':name,'url':url})
save('results/publisher-published-links.json',(json.dumps(links,indent=2)+'\n').encode())
save('results/acquisition-summary.json',(json.dumps({name:x[0] for name,x in results.items()},indent=2)+'\n').encode())
print(json.dumps({'sources':[{ 'name':name,'status':meta.get('status'),'bytes':meta.get('bytes'),'error':meta.get('error')} for name,(meta,raw) in sorted(results.items())],
                  'verification_page_links':[x for x in links if x['source']=='vendor-verification-instructions']},indent=2))

