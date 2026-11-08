"""Read-only recheck of retained public provider inputs; no provider execution."""
import hashlib
import json
import pathlib
import tarfile

HERE = pathlib.Path(__file__).resolve().parent
ROOT = HERE.parents[4]
PREVIOUS = HERE.parent / '20261108T113403Z-m1-provider-fixture-qualification'
WORK = pathlib.Path('/private/tmp/vx-m1-provider-fixtures-20261108T113403Z')
record = json.loads((PREVIOUS / 'results/provider-source-record.json').read_text())
manifest = json.loads((PREVIOUS / 'sources/source-file-manifest.json').read_text())
archive = WORK / 'sqlcipher-source.tar.gz'
checks = {
    'scope': 'Public source/archive/build integrity only; not publisher authentication or runtime qualification',
    'archive_path': str(archive),
    'archive_sha256': hashlib.sha256(archive.read_bytes()).hexdigest(),
    'expected_archive_sha256': record['archive_sha256'],
    'manifest_entries': len(manifest),
    'archive_file_matches': 0,
    'extracted_file_matches': 0,
    'mismatches': [],
    'provider_executed': False,
}
checks['archive_matches'] = checks['archive_sha256'] == checks['expected_archive_sha256']
source = pathlib.Path(record['source_directory'])
with tarfile.open(archive, 'r:gz') as tar:
    members = {x.name.partition('/')[2]: x for x in tar.getmembers() if x.isfile()}
    checks['archive_file_count'] = len(members)
    for row in manifest:
        name = row['path']
        entry = members.get(name)
        if entry is None:
            checks['mismatches'].append({'path': name, 'kind': 'missing-archive-entry'})
            continue
        with tar.extractfile(entry) as fh:
            raw = fh.read()
        sha = hashlib.sha256(raw).hexdigest()
        blob = hashlib.sha1(b'blob ' + str(len(raw)).encode() + b'\0' + raw).hexdigest()
        if sha == row['sha256'] and blob == row['git_blob_sha1']:
            checks['archive_file_matches'] += 1
        else:
            checks['mismatches'].append({'path': name, 'kind': 'archive-content'})
        file = source / name
        if file.is_file() and hashlib.sha256(file.read_bytes()).hexdigest() == row['sha256']:
            checks['extracted_file_matches'] += 1
        else:
            checks['mismatches'].append({'path': name, 'kind': 'extracted-content'})
checks['integrity_status'] = 'PASS' if (
    checks['archive_matches'] and not checks['mismatches']
    and checks['archive_file_count'] == checks['manifest_entries']
) else 'FAIL'
(HERE / 'results/retained-input-integrity.json').write_text(json.dumps(checks, indent=2) + '\n')
print(json.dumps(checks, indent=2))
