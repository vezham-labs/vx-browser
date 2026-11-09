"""Native qualification against exact registered synthetic app inputs. No secrets in evidence."""
import json
from pathlib import Path
import platform
import queue
import subprocess
import threading
import time
import uuid
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from wsf1 import ROOT, digest

def execute(run, record_path, mode):
    record = json.loads(record_path.read_text())
    binary = Path(record['bundle']) / 'Contents/MacOS/VezhamBrowser'
    if record['status'] != 'PASS_CONTRACT' or digest(binary) != record['binarySHA256']:
        raise SystemExit('Verified exact build required')
    attempts=[];requests=[]
    def host(label, payload, kill=False):
        run.save(label+'-input.json',payload)
        errors=(run.out/(label+'.stderr')).open('wb')
        p=subprocess.Popen([str(binary),'--wsf2-qualification'],stdin=subprocess.PIPE,stdout=subprocess.PIPE,stderr=errors)
        p.stdin.write(json.dumps(payload).encode());p.stdin.close()
        q=queue.Queue()
        def pump():
            for line in p.stdout:q.put(line)
            q.put(None)
        reader=threading.Thread(target=pump,daemon=True);reader.start()
        lines=[];events=[];killed=False;timeout=False;deadline=time.monotonic()+100
        while True:
            if time.monotonic()>=deadline:p.kill();timeout=True;break
            try:line=q.get(timeout=1)
            except queue.Empty:continue
            if line is None:break
            lines.append(line)
            try:event=json.loads(line)
            except ValueError:continue
            events.append(event)
            if kill and 'observations' in event:p.kill();killed=True
        try:p.wait(timeout=5)
        except subprocess.TimeoutExpired:p.kill();p.wait()
        reader.join(timeout=2);errors.close()
        (run.out/(label+'.stdout')).write_bytes(b''.join(lines))
        finals=[x for x in events if 'cases' in x];final=finals[-1] if finals else {}
        checkpoints=[x['checkpoint'] for x in events if x.get('checkpoint')]
        if checkpoints and not final.get('checkpoint'):final['checkpoint']=checkpoints[-1]
        ok=(killed and p.returncode==-9) if kill else p.returncode==0 and bool(finals) and all(c['status']!='FAIL' for c in final.get('cases',[]))
        info={'label':label,'pid':p.pid,'argv':[str(binary),'--wsf2-qualification'],'binarySHA256':record['binarySHA256'],'returncode':p.returncode,'intentionalKill':kill,'cutpointObserved':killed,'timeout':timeout,'status':'PASS_NATIVE' if ok and not timeout else 'FAIL','result':final}
        run.save(label+'-result.json',info);attempts.append(info)
        print(json.dumps({'label':label,'status':info['status'],'cases':len(final.get('cases',[]))}),flush=True)
        if not ok or timeout:raise RuntimeError('Stopped at '+label+'; no unchanged retry or unsafe cleanup')
        return final
    server=None
    namespace=str(uuid.uuid4());profile=str(uuid.uuid4());store=str(uuid.uuid4());key=str(uuid.uuid4())
    base={'namespace':namespace,'profile':profile,'store':store,'keyID':key,'origin':None,'cacheID':None,'checkpoint':None,'cutpoint':None}
    run.save('fixtures.json',{'base':base,'secretMaterialInEvidence':False,'scope':'Synthetic keys only; public identifiers are not secrets'})
    try:
        if mode=='security-native':
            created=host('keychain-create',dict(base,action='keychain-create'))
            exists=any(c['id']=='F2-KEY-CREATE' and c['status']=='PASS_NATIVE' for c in created['cases'])
            host('keychain-restart',dict(base,action='keychain-restart',expectKey=exists))
            host('backup',dict(base,action='backup'))
        else:
            counters={}
            class Handler(BaseHTTPRequestHandler):
                def do_GET(self):
                    path=self.path.split('?',1)[0]
                    if path.startswith('/cache-probe/'):
                        fixture=path.rsplit('/',1)[-1]
                        try:uuid.UUID(fixture)
                        except ValueError:self.send_error(404);return
                        counters[path]=counters.get(path,0)+1
                        value='cache-'+str(counters[path]);etag='"'+fixture+'-'+value+'"'
                        payload=value.encode();self.send_response(200)
                        self.send_header('Cache-Control','public, max-age=86400, immutable')
                        self.send_header('ETag',etag);self.send_header('Content-Type','text/plain')
                    elif path=='/slow':
                        time.sleep(0.5);payload=b'<!doctype html><title>controlled slow fixture</title>';self.send_response(200);self.send_header('Content-Type','text/html')
                    elif path=='/fixture':
                        payload=(ROOT/'apps/browser-macos/Tools/fixtures/storage.html').read_bytes()
                        self.send_response(200);self.send_header('Cache-Control','no-store');self.send_header('Content-Type','text/html')
                    else:self.send_error(404);return
                    requests.append({'path':path,'requestOrdinal':len(requests)+1,'cacheCount':counters.get(path),'ifNoneMatch':self.headers.get('If-None-Match'),'cacheControl':self.headers.get('Cache-Control')})
                    self.send_header('Content-Length',str(len(payload)));self.end_headers()
                    try:self.wfile.write(payload)
                    except (BrokenPipeError,ConnectionResetError):pass
                def log_message(self,*_):pass
            server=ThreadingHTTPServer(('127.0.0.1',0),Handler);threading.Thread(target=server.serve_forever,daemon=True).start()
            origin='http://127.0.0.1:'+str(server.server_port);cache_id=str(uuid.uuid4())
            a=dict(base,action='cache-seed',origin=origin,cacheID=cache_id)
            first=host('cache-A-seed',a)
            b=dict(a,namespace=str(uuid.uuid4()),profile=str(uuid.uuid4()),store=str(uuid.uuid4()))
            second=host('cache-B-seed',b)
            a.update(checkpoint=first.get('checkpoint'),action='cache-read')
            reopened=host('cache-A-restart',a);a['checkpoint']=reopened.get('checkpoint')
            reconstructed=host('cache-A-reconstruct',dict(a,action='cache-reconstruct'));a['checkpoint']=reconstructed.get('checkpoint')
            killed=host('cache-A-abrupt',dict(a,cutpoint='cache-active'),kill=True)
            a['checkpoint']=killed.get('checkpoint')
            after=host('cache-A-after-abrupt',a);a['checkpoint']=after.get('checkpoint')
            selected=host('cache-A-selected-clear',dict(a,action='cache-selected-clear'));a['checkpoint']=selected.get('checkpoint')
            full=host('cache-A-full-clear',dict(a,action='cache-full-clear'));a['checkpoint']=full.get('checkpoint')
            host('cache-A-remove',dict(a,action='cache-remove'))
            host('cache-B-remove',dict(b,action='cache-remove',checkpoint=second.get('checkpoint')))
            # Separate fixture for actual lock barriers; no access to removed IDs.
            lock=dict(base,action='lock',namespace=str(uuid.uuid4()),profile=str(uuid.uuid4()),store=str(uuid.uuid4()),origin=origin,cacheID=str(uuid.uuid4()))
            host('lock',lock)
            moving=dict(lock,action='lock-navigation',profile=str(uuid.uuid4()),store=str(uuid.uuid4()))
            host('lock-navigation',moving)
            interrupted=dict(lock,profile=str(uuid.uuid4()),store=str(uuid.uuid4()),cutpoint='lock-fence')
            interrupted_result=host('lock-interrupted',interrupted,kill=True)
            host('lock-restart',dict(interrupted,action='lock-restart',cutpoint=None,checkpoint=interrupted_result.get('checkpoint')))
            permission=dict(lock,action='permission',profile=str(uuid.uuid4()),store=str(uuid.uuid4()))
            granted=host('permission',permission)
            host('permission-cleanup',dict(permission,action='cache-remove',checkpoint=granted.get('checkpoint')))
    except RuntimeError as error:run.save('blocker.json',{'reason':str(error),'unsafeCleanup':False})
    finally:
        if server:server.shutdown();server.server_close()
        run.save('server-requests.json',requests);run.save('attempts.json',attempts)
        cases=[dict(c,attempt=a['label']) for a in attempts for c in a['result'].get('cases',[])]
        run.save('case-results.json',cases)
        summary={'status':'FAIL' if any(a['status']=='FAIL' for a in attempts) else 'PASS_NATIVE','host':platform.mac_ver()[0],'mode':mode,'nativePassed':sum(c['status']=='PASS_NATIVE' for c in cases),'contractPassed':sum(c['status']=='PASS_CONTRACT' for c in cases),'blocked':sum(c['status']=='BLOCKED' for c in cases),'inconclusive':sum(c['status']=='INCONCLUSIVE' for c in cases),'failed':sum(c['status']=='FAIL' for c in cases),'appProcesses':len(attempts),'buildRecord':str(record_path),'qualification':'Bounded cases only; essential catalog/unlock/Keychain/backup gates may remain blocked'}
        run.save('result.json',summary);print(json.dumps({'attempt':str(run.out),**summary}),flush=True)
        if summary['status']=='FAIL':raise SystemExit(1)
