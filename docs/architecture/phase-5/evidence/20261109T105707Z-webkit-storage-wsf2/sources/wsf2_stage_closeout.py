#!/usr/bin/env python3
"""Stage exact reviewed WS-F2 files and finalize hashes; never commit or push."""
import ast,hashlib,json,re,subprocess
from pathlib import Path
R=Path('/Users/vigneshwaranbhoj/Downloads/repo-labs/vx-browser')
E=R/'docs/architecture/phase-5/evidence/20261109T105707Z-webkit-storage-wsf2'
EP=str(E.relative_to(R))+'/'
def git(*args):return subprocess.check_output(['git',*args],cwd=R,text=True).strip()
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
def save(n,d):(E/n).write_text(json.dumps(d,indent=2,ensure_ascii=False)+'\n')
base=json.loads((E/'baseline.json').read_text());change=json.loads((E/'changed-files.json').read_text())
authored=sorted(change['files'])
assert git('rev-parse','HEAD')==base['head'] and git('branch','--show-current')=='timeline'
assert not git('diff','--cached','--name-only'),'Index must initially be empty'
assert all(sha(R/p)==v['sha256'] for p,v in change['files'].items())
subprocess.run(['git','add','--',*authored,EP],cwd=R,check=True)
staged=git('diff','--cached','--name-only').splitlines()
assert set(p for p in staged if not p.startswith(EP))==set(authored)
assert set(staged)==set(authored)|{str(p.relative_to(R)) for p in E.rglob('*') if p.is_file()}
check=subprocess.run(['git','diff','--cached','--check'],cwd=R,capture_output=True,text=True)
(E/'results/staged-whitespace.stdout').write_text(check.stdout)
(E/'results/staged-whitespace.stderr').write_text(check.stderr)
diagnostics=[]
for line in check.stdout.splitlines():
 m=re.match(r'(.+?):(\d+): (.+)',line)
 if m:diagnostics.append({'path':m[1],'line':int(m[2]),'diagnostic':m[3]})
assert check.returncode in (0,2) and not check.stderr
assert check.returncode==0 or diagnostics
assert all(x['path'].startswith(EP) for x in diagnostics),diagnostics
check_authored=subprocess.run(['git','diff','--cached','--check','--',*authored],cwd=R,capture_output=True,text=True)
assert check_authored.returncode==0,check_authored.stdout+check_authored.stderr
final_paths=set(authored)|{str(p.relative_to(R)) for p in E.rglob('*') if p.is_file()}
final_paths.update(EP+n for n in ['results/staged-review.json','artifact-index.json','SHA256SUMS'])
save('results/staged-review.json',{'status':'PASS_CONTRACT','reviewed_authorized_authored_files':len(authored),'staged_snapshot_before_final_hashes':staged,'expected_final_paths':sorted(final_paths),'authored_whitespace':'PASS','global_whitespace_exit':check.returncode,'preserved_raw_whitespace_diagnostics':diagnostics,'raw_whitespace_scope':'All diagnostics restricted to this new evidence root; exact raw owner/SDK/tool outputs preserved. No historical or authored-source whitespace exemption.','unexpected_paths':[],'index_finalization':'Append this review, artifact-index and SHA256SUMS; restage exact evidence root; verify final staged content equals working bytes and exact expected set before commit','no_commit_or_push_executed_by_this_script':True})
# Validate the finalized data without executing any app/test/provider.
json_count=0
for p in E.rglob('*.json'):json.loads(p.read_text());json_count+=1
for p in (E/'sources').glob('*.py'):ast.parse(p.read_text(),filename=str(p))
# Index covers authored source/docs/config plus evidence, excluding itself/checksum.
index_files=sorted(set(authored)|{str(p.relative_to(R)) for p in E.rglob('*') if p.is_file() and p.name not in ['artifact-index.json','SHA256SUMS']})
save('artifact-index.json',{'hash':'SHA-256','baseline':base['head'],'milestone':'WS-F2 INCOMPLETE — Required implementation or safety gates remain unmet.','scope':'Reviewed authored implementation/docs/config and all new evidence except this index/final checksum. Original historical evidence covered by preservation audit.','files':{p:{'sha256':sha(R/p),'bytes':(R/p).stat().st_size} for p in index_files},'final_commit':'Handoff supplies local commit SHA, branch and final worktree state','no_release_or_engine_approval':True})
evidence_files=sorted(p for p in E.rglob('*') if p.is_file() and p.name!='SHA256SUMS')
(E/'SHA256SUMS').write_text(''.join(sha(p)+'  '+str(p.relative_to(E))+'\n' for p in evidence_files))
subprocess.run(['git','add','--',EP],cwd=R,check=True)
actual=set(git('diff','--cached','--name-only').splitlines())
assert actual==final_paths,(actual-final_paths,final_paths-actual)
assert not git('diff','--name-only'),'Unstaged tracked changes'
assert not git('ls-files','--others','--exclude-standard'),'Untracked files'
for p in actual:
 blob=subprocess.check_output(['git','show',':'+p],cwd=R)
 assert hashlib.sha256(blob).hexdigest()==sha(R/p),p
for line in (E/'SHA256SUMS').read_text().splitlines():
 h,n=line.split('  ',1);assert sha(E/n)==h,n
for p,v in json.loads((E/'artifact-index.json').read_text())['files'].items():assert sha(R/p)==v['sha256'],p
print(json.dumps({'status':'PASS_CONTRACT','staged_files':len(actual),'authored':len(authored),'evidence_checksum_files':len(evidence_files),'indexed_files':len(index_files),'JSON_parsed_before_index':json_count,'raw_whitespace_diagnostics':len(diagnostics),'raw_whitespace_paths':sorted({x['path'] for x in diagnostics}),'checksum_file_sha256':sha(E/'SHA256SUMS'),'index_sha256':sha(E/'artifact-index.json')}))
