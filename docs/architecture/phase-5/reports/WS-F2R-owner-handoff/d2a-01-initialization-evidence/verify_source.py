#!/usr/bin/env python3
"""Reproduce bounded D2A-01 source facts. No provider imports/loads, DB opens or builds.
Reads only existing tracked source/evidence and whitelisted text members of a ZIP.
An optional output file is created exclusively; existing output is never overwritten.
"""
import argparse
import hashlib
import json
from pathlib import Path
import subprocess
import zipfile

PIN='355d4db92d3404e71faa8088d071a71d767807f4'
TAG='52252487a5cada9b430e8d4b20025790c5a6ba20'
TREE='b3aa6f0a71413a40df4c968d357bbbbee61b42cb'
ARCHIVE_SHA='a1417a5a672a2342de6ae44e08ccd68487fa3d0a43212331f4226a0d00b51b9c'
VENDOR='docs/architecture/phase-5/evidence/20261108T142421Z-m1-vendor-archive-verification'
FIXTURE='docs/architecture/phase-5/evidence/20261108T113403Z-m1-provider-fixture-qualification'
FILES=['src/main.c','src/btree.c','src/pager.c','src/os.c','src/os_unix.c','src/attach.c','src/sqlcipher.c','src/sqlcipher.h','src/crypto_cc.c','src/sqlite.h.in','src/pragma.c','src/vdbe.c','src/prepare.c','src/loadext.c','src/memdb.c','src/backup.c','src/vdbesort.c','manifest.uuid','VERSION']

def digest(data):return hashlib.sha256(data).hexdigest()
def inspect(repo):
    evidence=repo/VENDOR
    archive=evidence/'sources/sqlcipher-4.20.0.zip'
    assert digest(archive.read_bytes())==ARCHIVE_SHA,'Source archive hash changed'
    tree=json.loads((evidence/'sources/comparison-pinned-tree.decoded.json').read_text())
    commit=json.loads((evidence/'sources/comparison-pinned-commit.decoded.json').read_text())
    tag=json.loads((repo/FIXTURE/'sources/annotated-tag.json').read_text())['data']
    ref=json.loads((repo/FIXTURE/'sources/tag-ref.json').read_text())['data']
    assert tree['sha']==TREE and not tree['truncated']
    assert commit['sha']==PIN and commit['tree']['sha']==TREE
    assert tag['sha']==TAG and tag['object']['sha']==PIN and ref['object']['sha']==TAG
    blobs={x['path']:x for x in tree['tree'] if x['type']=='blob'}
    sources={};manifest={}
    with zipfile.ZipFile(archive) as z:
        for name in FILES:
            data=z.read('sqlcipher-4.20.0/'+name)
            blob=hashlib.sha1(('blob '+str(len(data))+'\0').encode()+data).hexdigest()
            assert blob==blobs[name]['sha'],name
            sources[name]=data.decode('utf8')
            manifest[name]={'sha256':digest(data),'git_blob_sha1':blob,'bytes':len(data)}
    checks=[]
    def body(name,start,end):
        text=sources[name];return text[text.index(start):text.index(end,text.index(start)+len(start))]
    def check(identifier,condition,description):
        assert condition,identifier
        checks.append({'id':identifier,'status':'PASS_STATIC_SOURCE_CHECK','claim':description})
    main=sources['src/main.c'];btree=sources['src/btree.c'];pager=sources['src/pager.c'];codec=sources['src/sqlcipher.c'];os_c=sources['src/os.c']
    opening=body('src/main.c','static int openDatabase(','int sqlite3_open(')
    check('STATIC-01','return openDatabase(filename, ppDb, (unsigned int)flags, zVfs);' in main,'Public open_v2 delegates to openDatabase')
    check('STATIC-02',opening.index('rc = sqlite3BtreeOpen(')<opening.index('sqlite3AutoLoadExtensions(db);')<opening.index('*ppDb = db;')<opening.index('sqlite3CodecQueryParameters(db, 0, zOpen, 0)'), 'Btree open precedes auto extensions, public handle publication and URI key handling')
    check('STATIC-03','unsigned char zDbHeader[100];' in btree,'Btree initial header buffer is 100 bytes')
    bt_open=body('src/btree.c','int sqlite3BtreeOpen(','int sqlite3BtreeClose(')
    fresh_start=bt_open.index('rc = sqlite3PagerOpen(')
    fresh=bt_open[fresh_start:]
    check('STATIC-04',fresh.index('rc = sqlite3PagerOpen(')<fresh.index('rc = sqlite3PagerReadFileheader(')<fresh.index('p->pBt = pBt;')<fresh.index('*ppBtree = p;')<fresh.index('SQLITE_FCNTL_PDB'),'Cold/new-Btree branch: header request precedes fully published Btree and PDB connection hint; an already shared Btree is a different path')
    header=body('src/pager.c','int sqlite3PagerReadFileheader(','void sqlite3PagerPagecount(')
    check('STATIC-05','if( isOpen(pPager->fd) )' in header and 'rc = sqlite3OsRead(pPager->fd, pDest, N, 0);' in header,'Open main-file pager issues offset-zero header read request')
    check('STATIC-06','if( rc==SQLITE_IOERR_SHORT_READ )' in header and 'rc = SQLITE_OK;' in header,'Genuine short-read handling is special; fabricated short-read is not a compliant workaround')
    check('STATIC-07','return id->pMethods->xRead(id, pBuf, amt, offset);' in os_c,'OS read wrapper dispatches the file xRead method')
    check('STATIC-08','rc = sqlite3OsOpen(pVfs, pPager->zFilename, pPager->fd, vfsFlags, &fout);' in pager,'Pager construction opens the named main file through VFS')
    key=body('src/sqlcipher.c','int sqlite3_key(sqlite3 *db,','int sqlite3_rekey(')
    check('STATIC-09','return sqlite3_key_v2(db, "main", pKey, nKey);' in key and 'return sqlcipherCodecAttach(db, db_index, pKey, nKey);' in key,'Public key APIs require db and delegate to codec attachment; negative lengths use strlen')
    attach=body('src/sqlcipher.c','int sqlcipherCodecAttach(','void sqlite3_activate_see(')
    check('STATIC-10','(pDb = &db->aDb[nDb]) && pDb->pBt' in attach,'Codec attachment requires an already present target Btree')
    check('STATIC-11',attach.index('rc = sqlcipher_codec_ctx_init(')<attach.index('sqlcipherPagerSetCodec(pPager, sqlite3Codec,')<attach.index('codec_set_btree_to_codec_pagesize(db, pDb, ctx);'),'Attachment initializes codec, installs it and coordinates page size; return alone is not authentication')
    init=body('src/sqlcipher.c','static int sqlcipher_codec_ctx_init(codec_ctx **iCtx,','static void sqlcipher_codec_ctx_free(')
    check('STATIC-12','sqlcipher_codec_ctx_set_pass(ctx, zKey, nKey, 0)' in init and 'sqlcipher_codec_ctx_init_kdf_salt(' not in init,'Inspected context initialization sets pass bytes; stale salt comment is not an executed salt-read call')
    check('STATIC-13','sqlcipher_codec_key_derive(ctx)' in body('src/sqlcipher.c','static void* sqlite3Codec(','int sqlcipherCodecAttach('),'Codec use invokes deferred key derivation')
    check('STATIC-14','sqlcipher_codec_ctx_init_kdf_salt(ctx)' in body('src/sqlcipher.c','static int sqlcipher_cipher_ctx_key_derive(','static int sqlcipher_codec_key_derive(') and 'sqlite3OsRead(fd, ctx->kdf_salt, ctx->kdf_salt_sz, 0)' in codec,'Deferred derivation can issue a separate header/salt read; key-applied and key-derived differ')
    pragma=sources['src/pragma.c']
    check('STATIC-15',pragma.index('rc = sqlite3_file_control(db, zDb, SQLITE_FCNTL_PRAGMA,')<pragma.index('if(sqlcipher_codec_pragma(db,')<pragma.index('if( sqlite3ReadSchema(pParse) )'),'PRAGMA analysis first reaches VFS, then codec processing, and generic schema-dependent paths')
    check('STATIC-16',sources['src/attach.c'].index('rc = sqlite3BtreeOpen(pVfs, zPath,')<sources['src/attach.c'].index('rc = sqlcipherCodecAttach(db, db->nDb-1,'),'ATTACH opens target Btree before attaching its codec')
    check('STATIC-17','rc = sqlite3BtreeBeginTrans(pDb->pBt, 0, 0);' in sources['src/prepare.c'] and 'rc = sqlite3OsRead(pPager->fd, pPg->pData, pPager->pageSize, iOffset);' in pager,'Schema preparation can start a read transaction; pager page reads need instrumentation before step')
    check('STATIC-18','got = osPread(id->h, pBuf, cnt, offset);' in sources['src/os_unix.c'] and 'memcpy(pBuf, &((u8 *)(pFile->pMapRegion))[offset], amt);' in sources['src/os_unix.c'],'Unix reads may use pread or existing mappings; syscall counts alone omit mapped reads')
    check('STATIC-19','rc = SQLITE_EXTRA_INIT(0);' in main and 'int rc = sqlite3_initialize();' in os_c,'Global initialization and VFS lookup/registration can invoke initialization before a connection exists')
    check('STATIC-20','return SQLITE_MISUSE;' in attach and '*ppBtree = 0;' in bt_open,'Failed/denied Btree construction does not produce an attachable target by merely returning a sick public handle')
    witnesses=[
        ('SRC-01','src/main.c','sqlite3_initialize / openDatabase / public open wrappers',349,377),
        ('SRC-02','src/main.c','sqlite3CodecQueryParameters',3381,3417),
        ('SRC-03','src/main.c','openDatabase Btree open; deferred schema comment',3662,3735),
        ('SRC-04','src/main.c','openDatabase handle publication / URI key / return; open_v2',3762,3816),
        ('SRC-05','src/btree.c','sqlite3BtreeOpen header buffer',2562,2589),
        ('SRC-06','src/btree.c','sqlite3BtreeOpen pager/header/page-size order',2692,2740),
        ('SRC-07','src/btree.c','Btree publication, error cleanup, PDB hint',2823,2847),
        ('SRC-08','src/pager.c','sqlite3PagerReadFileheader',4063,4081),
        ('SRC-09','src/pager.c','sqlite3PagerOpen main-file xOpen',5126,5155),
        ('SRC-10','src/os.c','sqlite3OsRead / xRead',88,91),
        ('SRC-11','src/os.c','sqlite3OsFetch / xFetch',191,207),
        ('SRC-12','src/os_unix.c','seekAndRead / unixRead',3463,3577),
        ('SRC-13','src/sqlcipher.c','sqlcipherCodecAttach',3657,3784),
        ('SRC-14','src/sqlcipher.c','sqlite3_key / sqlite3_key_v2',3810,3822),
        ('SRC-15','src/sqlcipher.c','codec context construction',1553,1677),
        ('SRC-16','src/sqlcipher.c','salt init / getter',1487,1528),
        ('SRC-17','src/sqlcipher.c','key derivation / raw-key branches',1856,1918),
        ('SRC-18','src/sqlcipher.c','codec use / salt offset / authenticated read result',3496,3575),
        ('SRC-19','src/sqlcipher.c','cipher compatibility4 suite',3291,3306),
        ('SRC-20','src/pragma.c','PRAGMA VFS / codec / schema dispatch',480,539),
        ('SRC-21','src/prepare.c','schema init read transaction',267,285),
        ('SRC-22','src/pager.c','readDbPage',3188,3240),
        ('SRC-23','src/attach.c','ATTACH Btree then codec',211,287),
        ('SRC-24','src/sqlite.h.in','VFS xOpen signature',1509,1533),
        ('SRC-25','src/sqlcipher.c','page-size coordination helper',2782,2804),
        ('SRC-26','src/pager.c','page-size reconfiguration',3932,3991),
        ('SRC-27','src/sqlcipher.c','salt getter PRAGMA',3142,3152),
        ('SRC-28','src/sqlcipher.c','Apple / atexit finalization hooks',412,450),
    ]
    refs=[]
    for identifier,name,symbol,start,end in witnesses:
        lines=sources[name].splitlines(keepends=True);assert 1<=start<=end<=len(lines)
        span=''.join(lines[start-1:end]).encode()
        refs.append({'id':identifier,'file':name,'symbol':symbol,'lines':[start,end],'span_sha256':digest(span),'source_file_sha256':manifest[name]['sha256'],'upstream_url':'https://github.com/sqlcipher/sqlcipher/blob/'+PIN+'/'+name+'#L'+str(start)})
    local={}
    for path in ['qualification/webkit-storage-f0/Sources/BrowserPersistence/ProtectedCatalog.swift','apps/browser-macos/StorageRuntime/Sources/BrowserNativeStorage/NativeStorageSession.swift','apps/browser-macos/Sources/Host/ApplicationDelegate.swift','qualification/sqlcipher-phase1/worker.c','qualification/sqlcipher-phase1/link_identity.c','docs/architecture/phase-5/reports/M1/m1-sqlcipher-open01-resolution.md','docs/architecture/phase-5/reports/M1/m1-sqlcipher-open02-write-fence-specification.md','docs/architecture/phase-5/reports/M1/m1-sqlcipher-open03-vfs-confinement-specification.md','docs/architecture/phase-5/reports/M1/m1-sqlcipher-provider-adapter-phase2-design.md','docs/architecture/phase-5/reports/M1/m1-sqlcipher-phase2a-readiness-matrix.md']:
        local[path]=digest((repo/path).read_bytes())
    protected=(repo/'qualification/webkit-storage-f0/Sources/BrowserPersistence/ProtectedCatalog.swift').read_text()
    check('STATIC-21','D2A01KeyBeforeRead' in protected and 'CatalogObservation { .unavailable }' in protected,'Current production catalog is unavailable, not a working SQLCipher adapter')
    worker=(repo/'qualification/sqlcipher-phase1/worker.c').read_text()
    check('STATIC-22',worker.index('vx_wipe(w->key_frame,')<worker.index('VX_PROTOCOL_READY, VX_OK'),'Phase1 wipes fake key frame before protocol ready; this is not target key application')
    return {'classification':'NOT_FEASIBLE_WITH_CURRENT_SQLCIPHER_PATH','scope':'Source-derived negative result for cold existing-file open on the pinned public API, ordinary/private-cache path and truthful non-substituting VFS; not a statement about all possible future providers/APIs','runtime_provider_or_database_experiments':'NOT_EXECUTED','observed_runtime_read_sequence':None,'method':'ZIP source bytes + Git blob/pin metadata checks and bounded textual order witnesses, manually reviewed for the actual control flow; no compiler/control-flow proof or runtime trace claimed','pin':PIN,'tag_object':TAG,'tree':TREE,'archive_path':str(archive.relative_to(repo)),'archive_sha256':ARCHIVE_SHA,'vendor_signature':'Prior verification record reused; not newly cryptographically verified','git_tag_signature':'Not reclassified; prior unknown-key limitation remains','source_files':manifest,'source_references':refs,'static_checks':checks,'static_checks_passed':len(checks),'integration_source_sha256':local,'restrictions':{'source_or_production_changes':False,'DB_content_open_read_hash_copy':False,'provider_loaded_or_initialized':False,'keychain_or_webkit_runtime':False,'exception_approved':False,'D2A01':'Proposed / Not Decided'},'limits':['Source checks reproduce inspected witnesses, not native runtime encryption/IO/authentication','No physical-device zero-read or exact device-read-length inference','The current source establishes a violating request; it does not prove that only that one request would occur under any proposed future VFS','No documented supported early target-key binding API was established; future vendor-supported architectures remain unqualified']}

def main():
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--repo',required=True,type=Path)
    parser.add_argument('--output',type=Path)
    args=parser.parse_args();result=inspect(args.repo.resolve());text=json.dumps(result,indent=2,ensure_ascii=False)+'\n'
    if args.output:
        with args.output.open('x') as out:out.write(text)
    else:print(text,end='')
if __name__=='__main__':main()
