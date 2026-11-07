from pathlib import Path
import hashlib,json,os,re,subprocess,urllib.parse,datetime,ast
E=Path(__file__).resolve().parent;R=E.parents[4];I=json.loads((E/'documentation-import.json').read_text());S={'repository':str(R),'source':I['sourcePath']};B={**json.loads((E/'repository-baseline.json').read_text()),'sourceSHA256':I['sourceSHA256'],'trackedSHA256':json.loads((E/'tracked-baseline-sha256.json').read_text())};aligned=set(json.loads((E/'documentation-alignment.json').read_text())['alignedFiles'])
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
def git(*args):return subprocess.check_output(['git',*args],cwd=R,text=True).strip()
def ignored(p):return subprocess.run(['git','check-ignore','-q',str(p)],cwd=R).returncode==0
frozen={p:h for p,h in I['importedSHA256'].items() if p not in aligned}
errors=[]
for p,h in B['sourceSHA256'].items():
 t=Path(S['source'])/p
 if not t.is_file() or sha(t)!=h:errors.append('Original source changed: '+p)
for p,h in frozen.items():
 t=R/p
 if not t.is_file() or sha(t)!=h:errors.append('Frozen import changed: '+p)
archives=json.loads((E/'archive-import.json').read_text())
for a in archives:
 for p in [Path(a['sourcePath']),R/a['repositoryPath']]:
  if not p.is_file() or sha(p)!=a['sha256']:errors.append('Archive mismatch: '+str(p))
changed_baseline=[p for p,h in B['trackedSHA256'].items() if not (R/p).is_file() or sha(R/p)!=h]
expected_changed={'.gitignore','README.md','vx/README.md'}
if set(changed_baseline)!=expected_changed:errors.append('Unexpected existing tracked changes: '+str(changed_baseline))
head=git('rev-parse','HEAD');branch=git('branch','--show-current');remotes={n:git('remote','get-url',n) for n in ['origin','upstream']}
if head!=B['head'] or branch!=B['branch']:errors.append('HEAD/branch changed')
if remotes!={'origin':'https://github.com/vezham-labs/vx-browser.git','upstream':'https://github.com/vezham-labs/vx-fe-kit-starter.git'}:errors.append('Remote mismatch')
if git('diff','--cached','--name-only'):errors.append('Unexpected staged files')
if git('diff','--name-status','--diff-filter=DR'):errors.append('Deletion/rename detected')
for p in ['package.json','pnpm-lock.yaml','pnpm-workspace.yaml']:
 if sha(R/p)!=B['trackedSHA256'][p]:errors.append('Dependency pin changed: '+p)
for p in [E/'m0-native-build-runtime-fix.log',R/'prototype/wkwebview/Evidence/recovery-ui-20261107T135156Z-15341/recovery-ui-results.json']:
 if ignored(p):errors.append('Evidence ignored by Git: '+str(p.relative_to(R)))
if any((R/'docs/architecture/phase-5/reports'/f'M{n}').exists() for n in range(1,9)):errors.append('Unexpected M1-M8 report folder')
adr1=(R/'docs/decisions/0001-browser-engine-strategy.md').read_text();adr2=(R/'docs/decisions/0002-browser-distribution-and-platform.md').read_text()
if not re.search(r'\*\*Status:\*\* Proposed',adr1):errors.append('ADR0001 not Proposed')
if not re.search(r'\*\*Status:\*\* Accepted',adr2):errors.append('ADR0002 not Accepted')
# All actual native source files, excluding local generated outputs.
native_files=sorted(p for p in (R/'apps/browser-macos').rglob('*') if p.is_file() and not any(part in ['build','__pycache__','xcuserdata','.DS_Store'] for part in p.relative_to(R/'apps/browser-macos').parts))
for p in native_files:
 if p.suffix=='.py':ast.parse(p.read_text(),filename=str(p))
audit=json.loads((E/'m0-bundle-audit.json').read_text());exe=R/'apps/browser-macos/build/DerivedData/Build/Products/Debug/VezhamBrowser.app/Contents/MacOS/VezhamBrowser'
if sha(exe)!=audit['executableSHA256']:errors.append('Audited executable changed')
if not all(audit['checks'].values()):errors.append('Static bundle audit did not pass')
if json.loads((E/'m0-native-launch-authorized-result.json').read_text())['exitCode']!=0:errors.append('Authorized launch failed')
# Documentation inventory includes all imported and existing workspace Markdown, without deps/build caches.
tracked_docs={p for p in B['trackedSHA256'] if p.endswith('.md')}
doc_paths=tracked_docs|{p for p in I['importedSHA256'] if p.endswith('.md')}
for base in ['vx/handbooks/browser','docs','apps/browser-macos']:
 doc_paths.update(str(p.relative_to(R)) for p in (R/base).rglob('*.md') if not any(x in ['build','node_modules'] for x in p.parts))
doc_paths.add('arc-macos-architecture-report.md')
new_current=set(json.loads((E/'scoped-format-files.json').read_text()))
reserved=set()
current_missing=[];historic_missing=[];current_fragments=[];historical_fragments=[];linkcount=0
# Focused Markdown relative-target check; URLs/code samples are not network-fetched.
def anchors(path):
 t=re.sub(r'```.*?```','',path.read_text(),flags=re.S);out=set();counts={}
 for title in re.findall(r'^#{1,6}\s+(.+?)\s*#*$',t,re.M):
  title=re.sub(r'\[([^]]+)\]\([^)]*\)',r'\1',title).replace('`','');title=re.sub(r'<[^>]*>','',title).lower()
  a=''.join(c for c in title if c.isalnum() or c in ' -_').replace(' ','-');n=counts.get(a,0);counts[a]=n+1;out.add(a if n==0 else f'{a}-{n}')
 return out
for rel in sorted(doc_paths):
 p=R/rel
 if not p.exists():errors.append('Missing documentation '+rel);continue
 current=rel in new_current
 t=re.sub(r'```.*?```','',p.read_text(),flags=re.S)
 for raw in re.findall(r'\[[^\]\n]*\]\(([^)\n]+)\)',t):
  url=raw.strip().split(' "',1)[0].strip('<>')
  if re.match(r'^[a-zA-Z][a-zA-Z0-9+.-]*:',url) or url.startswith('//'):continue
  linkcount+=1;path,_,frag=url.partition('#');path=urllib.parse.unquote(path)
  target=(p.parent/path).resolve() if path else p
  rec={'source':rel,'target':url}
  if not target.exists():
   if target.parent==E and target.name in reserved:continue
   (current_missing if current else historic_missing).append(rec)
  elif frag and target.suffix=='.md' and urllib.parse.unquote(frag) not in anchors(target):
   (current_fragments if current else historical_fragments).append(rec)
print(json.dumps({'preservationErrors':errors,'frozenFiles':len(frozen),'sourceFiles':len(B['sourceSHA256']),'documentsInventoried':len(doc_paths),'relativeLinksChecked':linkcount,'currentMissing':current_missing,'currentFragmentWarnings':current_fragments,'retainedHistoricalMissing':historic_missing,'retainedHistoricalFragmentWarnings':historical_fragments,'nativeFileCount':len(native_files)},indent=2))
