#!/usr/bin/env python3
"""Synthetic UNENCRYPTED detector/scaffolding fixtures only, not EXP-03 execution."""
from pathlib import Path
import hashlib,json,os,sqlite3,stat
E=Path(__file__).resolve().parent.parent
W=Path('/private/tmp/vx-m1-provider-fixtures-20261108T113403Z/database-controls')
if W.exists():raise SystemExit('refuse to overwrite existing fixture directory')
W.mkdir(mode=0o700)
MARKER=b'VX_PUBLIC_PLAINTEXT_DETECTOR_CONTROL_20261108'
artifacts=[]
def artifact(p,kind,scope):
 payload=p.read_bytes();artifacts.append({'path':str(p),'kind':kind,'scope':scope,'bytes':len(payload),'sha256':hashlib.sha256(payload).hexdigest(),'unencrypted':True,'contains_public_detector_marker':MARKER in payload,'no_key_material':True})
def connection(p):
 c=sqlite3.connect(p);p.chmod(0o600);c.execute('PRAGMA synchronous=FULL');c.execute('PRAGMA wal_autocheckpoint=0');return c
for scope in ['catalog','profile-A','profile-B']:
 d=W/scope;d.mkdir(mode=0o700);p=d/'public-control.sqlite';c=connection(p)
 c.execute('PRAGMA journal_mode=WAL');c.execute('CREATE TABLE fixture(scope TEXT NOT NULL, marker BLOB NOT NULL)')
 c.execute('INSERT INTO fixture VALUES(?,?)',(scope,MARKER));c.commit();c.execute('PRAGMA wal_checkpoint(TRUNCATE)')
 c.execute('INSERT INTO fixture VALUES(?,?)',(scope,MARKER+b'_WAL'));c.commit()
 for suffix,kind in [('', 'main'),('-wal','WAL'),('-shm','SHM')]:
  src=Path(str(p)+suffix)
  if src.exists():
   dst=d/('captured-'+(suffix[1:] if suffix else 'main')+'.fixture');dst.write_bytes(src.read_bytes());dst.chmod(0o600);artifact(dst,kind,scope)
 # Close cleanly; copied WAL/main files are detector artifacts, not promised coherent backups.
 c.close()
p=W/'rollback-control.sqlite';c=connection(p);c.execute('PRAGMA journal_mode=DELETE');c.execute('CREATE TABLE fixture(marker BLOB)');c.execute('INSERT INTO fixture VALUES(?)',(MARKER,));c.commit()
c.execute('BEGIN IMMEDIATE');c.execute('UPDATE fixture SET marker=?',(MARKER+b'_UNCOMMITTED',))
j=Path(str(p)+'-journal')
if j.exists():
 dst=W/'captured-rollback-journal.fixture';dst.write_bytes(j.read_bytes());dst.chmod(0o600);artifact(dst,'rollback-journal','control')
c.rollback();c.close()
# Byte-level mutation/truncation constructors are prepared on disposable plaintext COPY only.
source=W/'profile-A/captured-main.fixture';payload=bytearray(source.read_bytes());payload[len(payload)//2]^=1
mut=W/'modified-plaintext-copy.fixture';mut.write_bytes(payload);mut.chmod(0o600);artifact(mut,'mutation-constructor-control','profile-A')
trunc=W/'truncated-plaintext-copy.fixture';trunc.write_bytes(source.read_bytes()[:-17]);trunc.chmod(0o600);artifact(trunc,'truncation-constructor-control','profile-A')
report={'scope':'fixture preparation and plaintext detector positive control ONLY; not encrypted database qualification','sqlite_module_version':sqlite3.sqlite_version,'fixture_directory':str(W),'artifacts':artifacts,'positive_control_marker_detected_in_main':any(x['kind']=='main' and x['contains_public_detector_marker'] for x in artifacts),'positive_control_marker_detected_in_wal':any(x['kind']=='WAL' and x['contains_public_detector_marker'] for x in artifacts),'encrypted_fixtures_created':False,'key_material_written':False,'runtime_temp_memory_claim':False,'EXP03_executed':False,'rotation_or_interrupt_experiment':False,'limitations':['Captured files are not qualified recovery snapshots.','No encrypted/tag-corruption/wrong-key fixture executed.','SHM bytes are not claimed encrypted or marker-free by assumption.','No statement-journal/temp-spill/disk-full/kill experiment.']}
(E/'results/database-control-fixtures.json').write_text(json.dumps(report,indent=2)+'\n');print(json.dumps({k:v for k,v in report.items() if k!='artifacts'}))
