#!/usr/bin/env python3
"""Read-only public upstream investigation. No provider execution or invented signature verifier."""
from pathlib import Path
import base64,datetime,hashlib,json,re,urllib.request,urllib.error
E=Path(__file__).resolve().parent
ROOT=next(p for p in E.parents if (p/'.git').exists())
OLD=ROOT/'docs/architecture/phase-5/evidence/20261108T113403Z-m1-provider-fixture-qualification'
PIN='355d4db92d3404e71faa8088d071a71d767807f4'
def fetch(name,url,json_data=False):
 d={'time':datetime.datetime.now(datetime.timezone.utc).isoformat(),'url':url,'command_description':'urllib.request HTTPS GET, default certificate validation, 25s timeout, 4MiB bound'}
 try:
  with urllib.request.urlopen(urllib.request.Request(url,headers={'User-Agent':'VX-M1-trust-gate','Accept':'application/vnd.github+json' if json_data else '*/*'}),timeout=25) as r:
   b=r.read(4*1024*1024+1);d.update(status=r.status,final_url=r.url,content_type=r.headers.get('Content-Type'))
  if len(b)>4*1024*1024:raise ValueError('bounded response exceeded')
  d['sha256']=hashlib.sha256(b).hexdigest();d['bytes']=len(b)
  if json_data:d['data']=json.loads(b)
  else:
   suffix='.asc' if '-----BEGIN PGP' in b.decode(errors='ignore') else '.txt'
   payload=E/'sources'/(name+suffix);payload.write_bytes(b);d['payload']=str(payload.relative_to(E))
 except urllib.error.HTTPError as ex:d.update(status=ex.code,error=str(ex));b=b''
 except Exception as ex:d['error']=str(ex);b=b''
 (E/'sources'/(name+'.json')).write_text(json.dumps(d,indent=2)+'\n');return d,b
ref,_=fetch('current-tag-ref','https://api.github.com/repos/sqlcipher/sqlcipher/git/ref/tags/v4.20.0',True)
obj=ref.get('data',{}).get('object',{})
tag,_=fetch('current-tag-object',obj.get('url','https://api.github.com/repos/sqlcipher/sqlcipher/git/tags/52252487a5cada9b430e8d4b20025790c5a6ba20'),True)
commit,_=fetch('current-pinned-commit','https://api.github.com/repos/sqlcipher/sqlcipher/commits/'+PIN,True)
release,_=fetch('current-release','https://api.github.com/repos/sqlcipher/sqlcipher/releases/tags/v4.20.0',True)
fetch('github-publisher-public-keys','https://github.com/sjlombardo.gpg')
fetch('github-publisher-key-api','https://api.github.com/users/sjlombardo/gpg_keys',True)
security,_=fetch('vendor-security-page','https://www.zetetic.net/security/')
support,key=fetch('vendor-security-support-key','https://www.zetetic.net/security/support_zetetic_net_public_key.gpg')
fetch('vendor-release-announcement','https://www.zetetic.net/blog/2026/10/27/sqlcipher-4.20.0-release/')
fetch('vendor-prior-security-advisory','https://www.zetetic.net/blog/2026/09/08/sqlcipher-4.19.0-release/')
fetch('upstream-published-advisories','https://api.github.com/repos/sqlcipher/sqlcipher/security-advisories',True)
fetch('upstream-current-issues','https://api.github.com/repos/sqlcipher/sqlcipher/issues?state=open&per_page=100',True)
# Packet decoding extracts UNVERIFIED key/signature metadata only. No RSA verification,
# key self-signature/expiry/revocation validation or trust inference is implemented.
def unarmor(text):
 lines=text.decode().splitlines();start=False;body=[]
 for l in lines:
  if l.startswith('-----BEGIN '):continue
  if l.startswith('-----END '):break
  if not start:
   if not l.strip():start=True
   elif ':' not in l and re.fullmatch('[A-Za-z0-9+/]+={0,2}',l):start=True;body.append(l)
  elif l and not l.startswith('='):body.append(l)
 return base64.b64decode(''.join(body),validate=True)
def packets(data):
 p=0
 while p<len(data):
  b=data[p];p+=1
  if not b&128:raise ValueError('invalid packet')
  if b&64:
   tag=b&63;n=data[p];p+=1
   if n<192:length=n
   elif n<224:length=((n-192)<<8)+data[p]+192;p+=1
   elif n==255:length=int.from_bytes(data[p:p+4],'big');p+=4
   else:raise ValueError('partial packet unsupported')
  else:
   tag=(b>>2)&15;lt=b&3
   if lt==3:raise ValueError('indeterminate length unsupported')
   n=1<<lt;length=int.from_bytes(data[p:p+n],'big');p+=n
  if length>len(data)-p:raise ValueError('truncated packet')
  yield tag,data[p:p+length];p+=length
metadata={'metadata_only_not_signature_verification':True,'support_key_fingerprints':[],'tag_issuer_fingerprints':[]}
try:
 for typ,body in packets(unarmor(key)):
  if typ in (6,14) and body and body[0]==4:
   metadata['support_key_fingerprints'].append({'packet':'primary' if typ==6 else 'subkey','fingerprint':hashlib.sha1(b'\x99'+len(body).to_bytes(2,'big')+body).hexdigest().upper()})
 signature=tag.get('data',{}).get('verification',{}).get('signature')
 if signature:
  for typ,body in packets(unarmor(signature.encode())):
   if typ!=2 or body[0]!=4:continue
   metadata['signature_public_key_algorithm']=body[2];metadata['signature_hash_algorithm']=body[3]
   n=int.from_bytes(body[4:6],'big');part=body[6:6+n];p=0
   while p<len(part):
    length=part[p];p+=1
    if length>=192:raise ValueError('long hashed subpacket requires dedicated parser')
    sub=part[p:p+length];p+=length
    if sub and sub[0]&127==33 and len(sub)>2:metadata['tag_issuer_fingerprints'].append(sub[2:].hex().upper())
except Exception as ex:metadata['metadata_parse_error']=str(ex)
issuers=set(metadata['tag_issuer_fingerprints'])
metadata['vendor_support_key_contains_tag_issuer']=any(x['fingerprint'] in issuers for x in metadata['support_key_fingerprints'])
(E/'results/public-key-metadata.json').write_text(json.dumps(metadata,indent=2)+'\n')
summary={'pinned_commit':PIN,'tag_still_resolves_to_pin':tag.get('data',{}).get('object',{}).get('sha')==PIN,'current_tag_verification':tag.get('data',{}).get('verification',{}),'current_commit_verification':commit.get('data',{}).get('commit',{}).get('verification',{}),'release_assets':release.get('data',{}).get('assets'),'vendor_support_fingerprints':metadata['support_key_fingerprints'],'tag_issuer_fingerprints':metadata['tag_issuer_fingerprints'],'support_key_matches':metadata['vendor_support_key_contains_tag_issuer'],'independent_publisher_authenticity_established':False,'runtime_gate':'BLOCKED','runtime_execution':False}
(E/'results/authenticity-investigation.json').write_text(json.dumps(summary,indent=2)+'\n')
print(json.dumps({k:v for k,v in summary.items() if k not in ['current_tag_verification','current_commit_verification']},indent=2))
