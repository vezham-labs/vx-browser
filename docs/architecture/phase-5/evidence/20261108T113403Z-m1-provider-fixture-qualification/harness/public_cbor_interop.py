#!/usr/bin/env python3
"""Independent public structural vector only; no key material or crypto implementation."""
from pathlib import Path
import json
E=Path(__file__).resolve().parent.parent
r=json.loads((E/'results/recovery-fixture-observations.json').read_text())
d=bytes.fromhex(r['public_structure_cbor_hex'])
def read(data,pos=0):
 if pos>=len(data):raise ValueError('truncated')
 b=data[pos];pos+=1;major,ai=b>>5,b&31
 if ai<24:n=ai
 elif ai in (24,25,26,27):
  count=1<<(ai-24)
  if len(data)-pos<count:raise ValueError('truncated integer')
  n=int.from_bytes(data[pos:pos+count],'big');pos+=count
 else:raise ValueError('unsupported')
 if major==0:return n,pos
 if major in (2,3):
  if len(data)-pos<n:raise ValueError('truncated bytes')
  s=data[pos:pos+n];return (s if major==2 else s.decode('utf-8')),pos+n
 if major==4:
  a=[]
  for _ in range(n):x,pos=read(data,pos);a.append(x)
  return a,pos
 if major==5:
  m={}
  for _ in range(n):
   k,pos=read(data,pos);v,pos=read(data,pos)
   if k in m:raise ValueError('duplicate')
   m[k]=v
  return m,pos
 raise ValueError('unsupported')
x,end=read(d)
expected={0:'VX-M1-STRUCTURE-ONLY',1:1,2:bytes([1,2,3]),3:[23,24,256]}
known_hex='a4007456582d4d312d5354525543545552452d4f4e4c59010102430102030383171818190100'
record={'scope':'public structural codec vector only','matches_independently_decoded_structure':x==expected and end==len(d),'matches_expected_canonical_hex':d.hex()==known_hex,'public_fixture_hex':known_hex,'full_VXKE_VXRF_or_crypto_interoperability_qualified':False,'secret_or_key_material':False}
(E/'results/public-cbor-interop.json').write_text(json.dumps(record,indent=2)+'\n');print(json.dumps(record))
