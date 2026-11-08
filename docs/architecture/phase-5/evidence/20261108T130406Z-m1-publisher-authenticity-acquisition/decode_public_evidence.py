"""Decode retained HTTP bodies and extract links, without cryptographic verification."""
import gzip,io,json,pathlib,re,html.parser,urllib.parse
HERE=pathlib.Path(__file__).resolve().parent
LIMIT=4*1024*1024
class Links(html.parser.HTMLParser):
 def __init__(self):super().__init__();self.links=[]
 def handle_starttag(self,tag,attrs):
  d=dict(attrs)
  if tag=='a' and 'href' in d:self.links.append(d['href'])
out=[];links=[]
summary=json.loads((HERE/'results/acquisition-summary.json').read_text())
for name,meta in summary.items():
 raw=(HERE/meta['raw_artifact']).read_bytes()
 compressed=raw.startswith(b'\x1f\x8b')
 if compressed:
  with gzip.GzipFile(fileobj=io.BytesIO(raw)) as f:decoded=f.read(LIMIT+1)
  if len(decoded)>LIMIT:raise ValueError('Decoded evidence exceeds size bound: '+name)
 else:decoded=raw
 target='sources/'+name+'.decoded.txt'
 with (HERE/target).open('xb') as f:f.write(decoded)
 text=decoded.decode('utf-8','replace')
 out.append({'name':name,'raw_artifact':meta['raw_artifact'],'decoded_artifact':target,'gzip_decoded':compressed,'status':meta.get('status')})
 if name.startswith('vendor-'):
  parser=Links();parser.feed(text)
  for href in parser.links+re.findall(r'\]\(([^)]+)\)',text):
   url=urllib.parse.urljoin(meta['url'],href)
   if re.search(r'(?:sign|\\.sig|\\.asc|\\.gpg|pgp|verify|community|github|release|attest)',url,re.I):
    links.append({'source':name,'url':url})
with (HERE/'results/decoded-body-records.json').open('x') as f:json.dump(out,f,indent=2);f.write('\n')
with (HERE/'results/decoded-publisher-links.json').open('x') as f:json.dump(links,f,indent=2);f.write('\n')
print(json.dumps({'verification_links':[x for x in links if x['source']=='vendor-verification-instructions'],
 'attestation_response':(HERE/'sources/archive-attestations.decoded.txt').read_text()[:500],
 'verification_page_excerpt':(HERE/'sources/vendor-verification-instructions.decoded.txt').read_text()[-2200:]},indent=2))

