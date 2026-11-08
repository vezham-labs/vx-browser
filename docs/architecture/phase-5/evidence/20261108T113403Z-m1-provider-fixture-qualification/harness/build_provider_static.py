#!/usr/bin/env python3
"""Build only pinned validation static archives; no install, app signing or DB campaign."""
from pathlib import Path
import datetime,hashlib,json,os,subprocess
E=Path(__file__).resolve().parent.parent
D=json.loads((E/'results/provider-source-record.json').read_text())
S=Path(D['source_directory']);W=S.parent
TMP=W/'owned-tmp';TMP.mkdir(exist_ok=True);TMP.chmod(0o700)
def run(label,args,cwd,env,timeout=180):
 start=datetime.datetime.now(datetime.timezone.utc).isoformat()
 try:
  p=subprocess.run(args,cwd=cwd,env=env,text=True,capture_output=True,timeout=timeout)
  d={'started_at':start,'ended_at':datetime.datetime.now(datetime.timezone.utc).isoformat(),'command':args,'cwd':str(cwd),'returncode':p.returncode,'stdout':p.stdout,'stderr':p.stderr}
 except (OSError,subprocess.TimeoutExpired) as ex:d={'started_at':start,'command':args,'cwd':str(cwd),'returncode':None,'error':str(ex)}
 (E/'results'/(label+'.json')).write_text(json.dumps(d,indent=2)+'\n');print(label,d['returncode'],flush=True);return d
sdk=subprocess.check_output(['xcrun','--sdk','macosx','--show-sdk-path'],text=True).strip()
cc=subprocess.check_output(['xcrun','--find','clang'],text=True).strip()
flags='-O2 -target arm64-apple-macosx26.0 -isysroot '+sdk+' -DSQLITE_HAS_CODEC -DSQLCIPHER_CRYPTO_CC -DSQLITE_EXTRA_INIT=sqlcipher_extra_init -DSQLITE_EXTRA_SHUTDOWN=sqlcipher_extra_shutdown -DSQLITE_OMIT_LOAD_EXTENSION -ffile-prefix-map='+str(W)+'=/validation -fdebug-prefix-map='+str(W)+'=/validation'
env={**os.environ,'CC':cc,'CFLAGS':flags,'LDFLAGS':'-framework Security -framework CoreFoundation','autosetup_tclsh':'/usr/bin/tclsh','MACOSX_DEPLOYMENT_TARGET':'26.0','ZERO_AR_DATE':'1','SOURCE_DATE_EPOCH':'1793028838','LC_ALL':'C','TZ':'UTC','TMPDIR':str(TMP),'TMP':str(TMP),'TEMP':str(TMP)}
records=[]
for i in [1,2]:
 b=W/('provider-build-'+str(i));b.mkdir(exist_ok=True)
 cfg=run('provider-configure-'+str(i),[str(S/'configure'),'--disable-shared','--disable-tcl','--disable-readline','--disable-load-extension','--with-tempstore=always'],b,env,90)
 if cfg['returncode']!=0:break
 made=run('provider-make-static-'+str(i),['/usr/bin/make','-j2','libsqlite3.a'],b,env,180)
 if made['returncode']!=0:break
 p=b/'libsqlite3.a'
 run('provider-archive-symbols-'+str(i),['/usr/bin/nm','-g',str(p)],b,env)
 run('provider-archive-architecture-'+str(i),['/usr/bin/lipo','-info',str(p)],b,env)
 records.append({'build':i,'archive':str(p),'sha256':hashlib.sha256(p.read_bytes()).hexdigest(),'bytes':p.stat().st_size,'amalgamation_sha256':hashlib.sha256((b/'sqlite3.c').read_bytes()).hexdigest(),'header_sha256':hashlib.sha256((b/'sqlite3.h').read_bytes()).hexdigest(),'configure_settings':(b/'config.defines.txt').read_text() if (b/'config.defines.txt').exists() else None})
result={'source_commit':D['commit'],'compiler':cc,'sdk':sdk,'target':'arm64-apple-macosx26.0','CFLAGS':flags,'environment_subset':{k:env[k] for k in ['LDFLAGS','MACOSX_DEPLOYMENT_TARGET','ZERO_AR_DATE','SOURCE_DATE_EPOCH','autosetup_tclsh']},'builds':records,'two_archive_hashes_equal':len(records)==2 and records[0]['sha256']==records[1]['sha256'],'signed_or_installed':False,'provider_runtime_or_database_qualification_performed':False,'qualification_status':'PREPARED STATIC BUILD ONLY' if records else 'BLOCKED'}
(E/'results/provider-build-record.json').write_text(json.dumps(result,indent=2)+'\n');print(json.dumps({k:v for k,v in result.items() if k!='builds'}),flush=True)
