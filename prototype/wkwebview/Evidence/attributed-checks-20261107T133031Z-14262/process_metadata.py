"""Read-only host diagnostics. Private Darwin ABI; never part of the app.

Layouts/constants checked against Apple's xnu proc_info_private.h and
mach/coalition.h. Refuse unexpected result sizes; no signals or writes here.
This is host-specific diagnostic evidence, not a supported product API.
"""
import ctypes
import json
import os
import pathlib
import struct
import subprocess
import sys

LIBPROC = ctypes.CDLL('/usr/lib/libproc.dylib', use_errno=True)
LIBPROC.proc_pidinfo.argtypes = [ctypes.c_int,ctypes.c_int,ctypes.c_uint64,ctypes.c_void_p,ctypes.c_int]
LIBPROC.proc_pidinfo.restype = ctypes.c_int
LIBPROC.proc_pidpath.argtypes = [ctypes.c_int,ctypes.c_void_p,ctypes.c_uint32]
LIBPROC.proc_pidpath.restype = ctypes.c_int


def info(pid, flavor, size):
    buf=ctypes.create_string_buffer(size)
    ctypes.set_errno(0)
    count=LIBPROC.proc_pidinfo(pid,flavor,0,buf,size)
    return buf.raw if count==size else None, {'bytesReturned':count,'expectedBytes':size,'errno':ctypes.get_errno()}


def metadata(pid):
    raw,coalition_result=info(pid,20,40)
    coalition=struct.unpack_from('<QQ',raw) if raw else None
    uniq,unique_result=info(pid,17,56)
    unique=struct.unpack_from('<QQ',uniq,16) if uniq else None
    path_buffer=ctypes.create_string_buffer(4096)
    count=LIBPROC.proc_pidpath(pid,path_buffer,4096)
    return {'pid':pid,'executablePath':path_buffer.value.decode(errors='replace') if count>0 else None,
            'resourceCoalitionID':coalition[0] if coalition else None,'jetsamCoalitionID':coalition[1] if coalition else None,
            'uniqueID':unique[0] if unique else None,'parentUniqueID':unique[1] if unique else None,
            'coalitionQuery':coalition_result,'uniqueQuery':unique_result}


def processes():
    output=subprocess.run(['/bin/ps','-axo','pid=,ppid=,uid=,rss=,comm='],capture_output=True,text=True,check=True).stdout
    result=[]
    for line in output.splitlines():
        items=line.strip().split(None,4)
        if len(items)!=5:continue
        try: pid,ppid,uid,rss=map(int,items[:4])
        except ValueError:continue
        result.append({'pid':pid,'ppid':ppid,'uid':uid,'rssKiB':rss,'command':items[4]})
    return result


def snapshot(host_pid):
    rows=processes();host=metadata(host_pid)
    selected=[]
    for row in rows:
        if row['pid']==host_pid or 'WebKit' in row['command'] or 'WebContent' in row['command']:
            selected.append({**row,**metadata(row['pid'])})
    return {'host':host,'processes':selected,'readerProcess':metadata(os.getpid()),
            'method':'Read-only proc_pidinfo diagnostic ABI (coalitions and unique ID), executable path, and ps metadata. Not part of prototype/production API.'}


if __name__=='__main__':
    current=json.loads(pathlib.Path('work/process-attribution-current.json').read_text())
    result=snapshot(current['hostPID'])
    target=pathlib.Path(current['evidenceDirectory'])/'coalition-observation.json'
    target.write_text(json.dumps(result,indent=2,sort_keys=True)+'\n')
    print('Host:',result['host'])
    print('Reader resource coalition:',result['readerProcess']['resourceCoalitionID'])
    for row in result['processes']:
        print({k:row[k] for k in ['pid','ppid','resourceCoalitionID','jetsamCoalitionID','uniqueID','rssKiB','executablePath']})
