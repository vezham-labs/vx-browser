import subprocess,struct,sys,pathlib
for s in sys.argv[1:]:
 f=pathlib.Path(s); bmp=f.with_suffix('.bmp')
 subprocess.run(['sips','-s','format','bmp',s,'--out',str(bmp)],check=True,stdout=subprocess.DEVNULL)
 data=bmp.read_bytes(); off=struct.unpack_from('<I',data,10)[0]; width,height=struct.unpack_from('<ii',data,18);size=struct.unpack_from('<H',data,28)[0]//8;stride=((width*size+3)//4)*4
 pts=[]
 for y in range(abs(height)):
  row=data[off+y*stride:off+(y+1)*stride]
  pos=row.find(bytes([232,197,130]))
  if pos>=0: pts.append(y)
 print(f.name,'fixture rows',len(pts))
 bmp.unlink()
