"""Document/source preservation audit; never loads or executes SQLCipher."""
import ast
import collections
import datetime
import hashlib
import json
import pathlib
import re
import subprocess

HERE = pathlib.Path(__file__).resolve().parent
ROOT = HERE.parents[4]
REL = HERE.relative_to(ROOT).as_posix()
BASE = 'docs/architecture/phase-5/reports/M1/'
ALLOWED = {BASE + name for name in (
    'README.md', 'm1-provider-and-fixture-qualification.md',
    'm1-validation-readiness-remediation.md', 'm1-source-catalog.md')}
REPORT = BASE + 'm1-provider-trust-and-runtime-qualification.md'
baseline = json.loads((HERE / 'baseline.json').read_text())
commands = []

def command(args):
    result = subprocess.run(args, cwd=ROOT, capture_output=True, text=True)
    commands.append(dict(argv=args, returncode=result.returncode,
                         stdout=result.stdout, stderr=result.stderr))
    return result

def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()

def write(name, value):
    (HERE / name).write_text(json.dumps(value, indent=2) + '\n')

checks = []
def check(name, ok, details=None):
    checks.append(dict(check=name, passed=bool(ok), details=details))

branch = command(['git', 'branch', '--show-current']).stdout.strip()
head = command(['git', 'rev-parse', 'HEAD']).stdout.strip()
parent = command(['git', 'rev-parse', 'HEAD^']).stdout.strip()
check('branch unchanged', branch == baseline['branch'])
check('HEAD unchanged', head == baseline['head'])
check('parent unchanged', parent == baseline['parent'])
check('index unchanged/empty staged diff', command(['git', 'diff', '--cached', '--quiet']).returncode == 0)
changed = []
missing = []
for row in baseline['tracked_files']:
    file = ROOT / row['path']
    if not file.is_file():
        missing.append(row['path'])
    elif sha(file) != row['sha256']:
        changed.append(row['path'])
check('no tracked file deleted', not missing, missing)
check('only four allowed tracked references changed', set(changed) == ALLOWED, sorted(changed))
for prefix, label in [
    ('docs/architecture/phase-5/evidence/', 'all previous Phase 5 evidence bytes unchanged'),
    ('docs/decisions/', 'all ADR bytes unchanged'),
    ('docs/architecture/phase-3/', 'Phase 3 closeout bytes unchanged'),
    ('prototype/', 'prototype bytes unchanged')]:
    relevant = [x for x in baseline['tracked_files'] if x['path'].startswith(prefix)]
    check(label, all((ROOT/x['path']).is_file() and sha(ROOT/x['path']) == x['sha256'] for x in relevant),
          {'tracked_files_checked': len(relevant)})
check('owner/spec/matrix/dependencies/product files unchanged', not (set(changed) - ALLOWED))
append_results = []
for path in sorted(ALLOWED):
    old = command(['git', 'show', 'HEAD:' + path]).stdout
    append_results.append({'path': path, 'append_only': (ROOT/path).read_text().startswith(old)})
check('four canonical references append-only', all(x['append_only'] for x in append_results), append_results)
untracked = [x for x in command(['git', 'ls-files', '--others', '--exclude-standard', '-z']).stdout.split('\0') if x]
unexpected = [x for x in untracked if x != REPORT and not x.startswith(REL + '/')]
check('new files limited to new report and current evidence', not unexpected, unexpected)
check('tracked diff whitespace', command(['git', 'diff', '--check']).returncode == 0)
# Reserve this finalizer's own outputs before checking document destinations.
# An interrupted run leaves an explicit in-progress marker, never a pass claim.
for output in ('preservation-audit.json', 'changed-files.json', 'artifact-index.json'):
    if not (HERE/output).exists():
        write(output, {'finalization': 'IN PROGRESS; not a completed audit'})
broken = []
for path in sorted(ALLOWED | {REPORT}):
    for target in re.findall(r'\]\(([^)]+)\)', (ROOT/path).read_text()):
        if target.startswith(('http:', 'https:', '#', 'mailto:')):
            continue
        local = target.split('#')[0].strip('<>')
        if local and not ((ROOT/path).parent / local).exists():
            broken.append({'path': path, 'target': target})
check('maintained local document links resolve', not broken, broken)
for file in sorted(HERE.glob('*.py')):
    ast.parse(file.read_text(), filename=file.name)
check('evidence Python parses; syntax inspection only', True)
gate = json.loads((HERE/'results/gate-results.json').read_text())
counts = dict(collections.Counter(x['status'] for x in gate['trust_criteria']))
check('trust ledger has nine criteria / six PASS / three BLOCKED', counts == {'PASS': 6, 'BLOCKED': 3}, counts)
check('runtime stop condition represented consistently',
      gate['workstream_A_status'] == 'BLOCKED' and gate['runtime_tests_executed'] == 0
      and all(x['execution'] == 'NOT EXECUTED' for x in gate['runtime_workstreams']))
integrity = json.loads((HERE/'results/retained-input-integrity.json').read_text())
check('retained archive and all source manifest entries match', integrity['integrity_status'] == 'PASS',
      {'archive_files': integrity['archive_file_matches'], 'extracted_files': integrity['extracted_file_matches']})
prior_archives = json.loads((HERE/'results/local-prerequisites.json').read_text())['prior_archives_current']
current_archives = [{'path': x['path'], 'hash_unchanged': sha(pathlib.Path(x['path'])) == x['sha256']} for x in prior_archives]
check('both static archives unchanged after assessment', all(x['hash_unchanged'] for x in current_archives), current_archives)
source_statuses = []
for path in sorted((HERE/'sources').glob('*.json')):
    value = json.loads(path.read_text())
    if isinstance(value, dict) and 'url' in value:
        source_statuses.append({'artifact': str(path.relative_to(HERE)), 'url': value['url'], 'status': value.get('status')})
check('recorded HTTPS source acquisitions completed', all(x['status'] == 200 for x in source_statuses), source_statuses)
state = command(['git', 'status', '--short', '--branch']).stdout
write('preservation-audit.json', {
    'time': datetime.datetime.now(datetime.timezone.utc).isoformat(),
    'kind': 'Documentation/source preservation checks, not product/runtime tests',
    'branch': branch, 'HEAD': head, 'parent': parent,
    'tracked_files_checked': len(baseline['tracked_files']),
    'checks': checks, 'passed': sum(x['passed'] for x in checks),
    'failed': sum(not x['passed'] for x in checks),
    'all_passed': all(x['passed'] for x in checks),
    'ending_git_status': state,
    'original_browser_stores': 'Not inspected, opened or mutated by this gate; no state inference',
    'runtime_tests_executed': 0,
    'initial_audit': 'results/preservation-audit-initial.json: one link-check failure before three self-generated output files existed; no source/runtime test failure; finalizer reserves its outputs before checking links',
    'commands': commands,
})

inventory = []
for path in sorted(ALLOWED | {REPORT}):
    inventory.append({'path': path, 'change': 'Modified / appended reference' if path in ALLOWED else 'Created / gate report',
                      'sha256': sha(ROOT/path)})
for path in sorted(HERE.rglob('*')):
    if path.is_file() and path.name not in {'artifact-index.json', 'changed-files.json'}:
        inventory.append({'path': path.relative_to(ROOT).as_posix(), 'change': 'Created / new evidence', 'sha256': sha(path)})
write('changed-files.json', {
    'tracked_modified': sorted(ALLOWED), 'new_report': REPORT,
    'new_evidence_directory': REL, 'files': inventory,
    'inventory_exclusions': ['changed-files.json and artifact-index.json exclude their own/cross hashes to avoid circularity'],
})
artifacts = []
for path in sorted(HERE.rglob('*')):
    if path.is_file() and path.name != 'artifact-index.json':
        artifacts.append({'path': path.relative_to(HERE).as_posix(), 'bytes': path.stat().st_size, 'sha256': sha(path)})
write('artifact-index.json', {
    'purpose': 'Current provider trust gate source/command/evidence index; no generated runtime evidence',
    'report': '../../reports/M1/m1-provider-trust-and-runtime-qualification.md',
    'gate': 'results/gate-results.json', 'preservation': 'preservation-audit.json',
    'reproduction_commands': [
        ['python3', REL+'/inspect_provider_authenticity.py'],
        ['python3', REL+'/verify_retained_provider_inputs.py'],
        ['python3', REL+'/finalize_gate_evidence.py']],
    'execution_notes': 'These scripts were executed for public metadata/integrity and document preservation only. Do not rerun into existing evidence; a future run must use a new evidence directory. No runtime harness was built or run.',
    'read_only_inspection_issue': 'One rg command referenced absent prior harness qualify_source.py and returned 2; later inventory found acquire_provider_source.py. No provider execution/mutation resulted.',
    'environment_command_record': 'results/current-environment-and-state.json (includes SDK-query FSEvents warning despite successful exit; no build)',
    'commands_and_outputs': 'Source acquisition command descriptions/status/URLs reside in sources/*.json; final read-only Git argv/outputs are in preservation-audit.json. Local integrity and parser implementations are retained verbatim.',
    'artifacts': artifacts,
    'self_hash_excluded': True,
})
print(json.dumps({'preservation_checks_passed': sum(x['passed'] for x in checks),
                  'preservation_checks_failed': sum(not x['passed'] for x in checks),
                  'failures': [x for x in checks if not x['passed']],
                  'trust_criteria': counts, 'runtime_tests_executed': 0,
                  'artifact_count': len(artifacts), 'status': state}, indent=2))
raise SystemExit(0 if all(x['passed'] for x in checks) else 1)
