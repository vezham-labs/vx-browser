"""Use maintained GnuPG only; no custom cryptographic verification."""
import datetime,json,pathlib,re,subprocess
HERE=pathlib.Path(__file__).resolve().parent
ENV=json.loads((HERE/'results/verifier-environment.json').read_text())
ACQ=json.loads((HERE/'results/vendor-acquisition.json').read_text())
PRIMARY='D83F5F9EB811D6E6B4A0D9C5D1FA3A2A97ED25C2'
records={x['filename']:x for x in ACQ['artifacts']}
if any(x.get('status')!=200 or x.get('error') for x in records.values()):
 raise SystemExit('Acquisition prerequisite blocked')
key=str(HERE/records['support_zetetic_net_public_key.gpg']['entity_artifact'])
archive=str(HERE/records['sqlcipher-4.20.0.zip']['entity_artifact'])
signature=str(HERE/records['sqlcipher-4.20.0.zip.sig']['entity_artifact'])
gpg=ENV['gpg_binary'];home=ENV['GNUPGHOME']
available=ENV['commands'][1]['stdout'].splitlines()
required=['--no-options','--homedir','--batch','--no-tty','--no-auto-key-retrieve','--no-autostart','--status-fd','--with-colons','--with-fingerprint','--with-subkey-fingerprint','--require-cross-certification']
if any(x not in available for x in required):raise SystemExit('Required supported GnuPG option missing')
prefix=[gpg,'--no-options','--homedir',home,'--batch','--no-tty','--no-auto-key-retrieve','--no-autostart','--status-fd','1']
commands=[]
def run(label,args):
 argv=prefix+args
 result=subprocess.run(argv,stdin=subprocess.DEVNULL,capture_output=True,timeout=60)
 for suffix,raw in [('stdout.txt',result.stdout),('stderr.txt',result.stderr)]:
  with (HERE/'results'/(label+'.'+suffix)).open('xb') as f:f.write(raw)
 rec={'label':label,'time':datetime.datetime.now(datetime.timezone.utc).isoformat(),'argv':argv,'returncode':result.returncode,'stdout':'results/'+label+'.stdout.txt','stderr':'results/'+label+'.stderr.txt'}
 commands.append(rec)
 return result
show=run('gpg-01-show-key',['--with-colons','--with-fingerprint','--with-subkey-fingerprint','--show-keys',key])
lines=show.stdout.decode('utf-8','replace').splitlines()
pubs=[];pending=False
for line in lines:
 fields=line.split(':')
 if fields[0]=='pub':pending=True
 elif pending and fields[0]=='fpr':
  pubs.append(fields[9]);pending=False
if show.returncode!=0 or pubs!=[PRIMARY]:
 with (HERE/'results/gpg-commands.json').open('x') as f:json.dump(commands,f,indent=2)
 raise SystemExit('Vendor full primary fingerprint mismatch / key inspection failure')
packets=run('gpg-02-key-packets',['--list-packets',key])
imp=run('gpg-03-import-public-key',['--import',key])
if imp.returncode!=0:
 with (HERE/'results/gpg-commands.json').open('x') as f:json.dump(commands,f,indent=2)
 raise SystemExit('Public-key import failed')
checks=run('gpg-04-check-key-signatures',['--with-colons','--with-fingerprint','--with-subkey-fingerprint','--list-options','show-unusable-subkeys,show-sig-expire,show-sig-subpackets','--check-sigs',PRIMARY])
verify=run('gpg-05-verify-vendor-archive',['--require-cross-certification','--verify',signature,archive])
statuses=[]
for line in verify.stdout.decode('utf-8','replace').splitlines():
 if line.startswith('[GNUPG:] '):statuses.append(line[len('[GNUPG:] '):])
valid=[s.split()[1:] for s in statuses if s.startswith('VALIDSIG ')]
badcodes={'BADSIG','ERRSIG','NO_PUBKEY','REVKEYSIG','EXPSIG','EXPKEYSIG','KEYEXPIRED','SIGEXPIRED','FAILURE','ERROR'}
bad=[s for s in statuses if s.split()[0] in badcodes]
actual=[v[0] for v in valid]
bound=[v[-1] for v in valid if re.fullmatch('[0-9A-F]{40}',v[-1])]
crypto_ok=verify.returncode==0 and len(valid)==1 and not bad and (actual==[PRIMARY] or bound==[PRIMARY])
summary={'time':datetime.datetime.now(datetime.timezone.utc).isoformat(),'primary_fingerprint':pubs[0],
 'cryptographic_signature_status':'PASS' if crypto_ok else 'FAIL',
 'signature_command_returncode':verify.returncode,'actual_signing_fingerprints':actual,
 'VALIDSIG_primary_fingerprints':bound,'verification_status_lines':statuses,'disqualifying_status_lines':bad,
 'public_key_check_command_returncode':checks.returncode,'packet_inspection_returncode':packets.returncode,
 'key_self_signature_subkey_revocation_review':'See complete gpg-04 and gpg-02 output; review before source comparison',
 'publisher_identity_limit':'Vendor HTTPS fingerprint/key publication is external identity evidence, not Web-of-Trust ownertrust',
 'archive_extracted':False,'provider_executed':False,'personal_keyring_used':False}
with (HERE/'results/gpg-commands.json').open('x') as f:json.dump(commands,f,indent=2);f.write('\n')
with (HERE/'results/signature-verification.json').open('x') as f:json.dump(summary,f,indent=2);f.write('\n')
print(json.dumps(summary,indent=2))
print('SIGNATURE_STDERR',verify.stderr.decode('utf-8','replace'))
raise SystemExit(0 if crypto_ok else 1)

