# M1 Keychain and Independent Recovery Specification

Version 1.0 — Proposed technical contract,2026-11-08. Existing SPEC-05 and key/lifecycle portions of SPEC-06/07/12/14/15; REQ-07/08/14/19 plus catalog/protection REQ-05/06/22; AC05/06/07/08/12/14/15. Implements OD-R08/09/18/19 and existing policy without changing any owner disposition. No product implementation/release authority.

## 1. Key hierarchy and trust limits

Use distinct independently generated32-byte secrets per persistent profile: profile DEK input for the qualified database suite; normal-access wrapping KEK; independent recovery secret R. R is not derived from DEK, KEK, a password, account identity or cloud service. A printable secret is not a plaintext copy of the database key. Catalog uses its own DEK/KEK/recovery scope, never one profile's keys.

Generate through platform CSPRNG with explicit failure checking. CryptoKit/Security declarations are present in the installed SDK; no key generation or runtime qualification was performed here. No production key material or personal Keychain is used. Derived keys use HKDF-SHA256 with purpose separation, scope UUID, generation/version and fresh salt. Envelope encryption is the AES-GCM contract in [encryption specification](m1-persistent-profile-encryption-specification.md).

| Material | Custody / purpose | Persistence and exposure |
|---|---|---|
| Profile DEK input | Qualified encrypted SQLite open; old versions for declared retained backups | Only in authenticated encrypted normal/recovery slots when at rest; bounded live native lease when unlocked |
| Normal KEK | OS Keychain-protected unwrap authority | Access-controlled app-owned Keychain item; never UI/SQL/log value |
| Recovery R | Independent user custody | Printable kit/user-held offline secret; not automatically retained in app/Keychain/server |
| K-normal-wrap | HKDF(KEK, salt, normal/scope/generation context) | Ephemeral; wraps DEK key ring |
| K-recovery-wrap | HKDF(R, salt, recovery/scope/generation context) | Ephemeral; independently wraps same DEK key ring |
| Snapshot/blob/archive keys | Fresh random key per archive/snapshot or purpose-specific derivation with unique context | Authenticated wrapped slots; never shared across profiles |
| Catalog keys | Independent catalog scope | Same normal/recovery structure; full-browser backup recovery uses catalog recovery authority |
| Runtime lease/context | Opaque generation-bound authorization, not a key | Memory only; invalidated on lock/quit/restart; never restored as authority |

A full-browser backup uses a new archive key, not a collection of plaintext profile keys in an outer manifest. Its authenticated recovery slot is protected by the catalog recovery authority; selected profile keys/capsules are inside encrypted archive content. A profile backup uses that profile's recovery authority. Each scope's loss impact must be explained. Source Keychain references/access groups are never portable credentials.

Keychain access does not protect against code already controlling the unlocked trusted process. Secret copies in Swift/Data/crypto providers may outlive a nominal variable; require reviewed buffer/handle ownership, no secret String conversions, provider close and bounded zeroization best effort. Do not promise forensic RAM erasure or Secure Enclave storage for bulk symmetric keys.

## 2. Key envelope v1 — exact proposed serialization

Logical bootstrap path: catalog/catalog-key-envelope.v1 or profiles/UUID/key-envelope.v1. The file is outside the encrypted DB because the key is needed before open. No labels, URLs or raw keys in its outer structure. Deterministic CBOR uses unsigned integer map keys, definite lengths and shortest encodings; reject duplicates/unknown critical keys/types/noncanonical encoding before effects. UUIDs are16-byte values; all counters are unsigned and nonzero; major1/minor0; unsupported major/minor/suite rejects without effects. This is a format contract, not a selected CBOR library.

**Container map:**0=ASCII magic VXKE (byte string);1=major;2=minor;3=scope kind (0 catalog,1 profile);4=scope UUID;5=active key-ring generation (uint64);6=current DEK version (uint32);7=normal slot map;8=recovery slot map;9=container-write generation (uint64). Container fields are structural hints, not independent authentication authority. Fields3–6 must equal the authenticated chosen-slot header/payload and native expected scope. Field9 is advisory until checked against the authenticated catalog/rotation intent; never use it alone as rollback protection.

**Each independently authenticated slot map:**

| Integer key | Field / exact type |
|---|---|
| 0 | kind: unsigned0 normal or1 recovery |
| 1 | scope kind: unsigned0 catalog or1 profile |
| 2 | scope UUID:16-byte string |
| 3 | key-ring generation:uint64 |
| 4 | current DEK version:uint32 |
| 5 | wrapping generation:uint64 |
| 6 | key identifier:16-byte UUID naming normal KEK or recovery authority |
| 7 | HKDF salt:32-byte string |
| 8 | AES-GCM nonce:12-byte string |
| 9 | ciphertext length:uint32,≤1MiB |
| 10 | ciphertext:byte string exactly field9 length |
| 11 | authentication tag:16-byte string |

AAD is deterministic CBOR array [1,0,1,map-of-slot-fields0-through9] in that order (major,minor,suite,header). Ciphertext/tag are excluded, avoiding circular encoding. HKDF-SHA256 input is the32-byte normal KEK or R, salt field7, info the deterministic CBOR array [text VX-M1-WRAP-1,map-of-slot-fields0-through6]; output32 bytes. The slot's security-relevant context is thereby authenticated without binding one slot to mutable bytes in the other slot. A normal-KEK-only rewrap does not require recovering R or invalidating an unchanged independent recovery capsule.

**Encrypted payload map:**0=scope UUID (16 bytes);1=key-ring generation(uint64);2=current DEK version(uint32);3=key-entry array of≤64 entries. Each entry map has0=DEK version(uint32),1=32-byte DEK input,2=database suite identifier(unsigned1 for the exact SQLCipher candidate contract),3=creation generation(uint64). Versions unique; current version present. Scope/ring/current values must agree with authenticated slot header and expected native context. Payload and parser depth≤8; whole envelope≤1MiB; no trailing bytes or silent key eviction. A larger/new format needs explicit version review.

Normal and recovery slots for a current envelope cover the same DEK ring, but use independent wrapping authorities/generations. Ciphertext is never published before tag validation. A KEK-only rotation changes only normal wrapping generation/slot plus catalog/intent receipt. A DEK-ring change requires a new matching recovery capsule and verified custody before old recovery is retired. A replayed old valid slot is not detected by AEAD alone: use authenticated catalog/deletion/rotation knowledge; unknown restore lineage follows explicit recovery handling.

Expected profile UUID comes from the authenticated catalog/native registry, never a message/envelope claim. Catalog account identity is anchored in native installation registry/app-owned Keychain metadata, not selected solely from an untrusted file. That metadata contains no DEK/KEK or sensitive labels and creates no alternate unlock path.

Bootstrap order: native-owned scope/allowed location → expected exact Keychain item → authenticate normal slot → verify expected DB identity/version → publish only after all required resources are ready. Missing/wrong item never creates a new key over an existing DB. If catalog cannot open, offer independent recovery; never activate arbitrary orphan directories.

## 3. Keychain item and native authentication contract

Use macOS data-protection Keychain GenericPassword items with service internal.vx.browser.keys.v1 and account containing only scope kind/UUID/key-generation identifier. Set kSecUseDataProtectionKeychain=true, synchronizable=false and the app's default access group; do not request unrelated/shared groups. Construct SecAccessControl with WhenUnlockedThisDeviceOnly and userPresence, then provide it as kSecAttrAccessControl; do not also supply a conflicting accessible attribute. The secret item value is the32-byte KEK. Keychain attributes are not confidential browsing storage.

Use fresh LAContext/native access for unlocking a locked scope; invalidate authentication context on lock/quit/OS transition and never reuse a stale context as a grant. No application-specific browser password is required by this design. Native OS authentication may occur on first key acquisition and after lock; it is not a promise of zero OS prompts. No second unprotected KEK/DEK item or ordinary-access shortcut may bypass the protected slot.

SDK declarations support these API choices, but actual access-group/code-identity/ACL/LAContext behavior on macOS 26 and this app identity must be qualified. Failure/cancel/unavailable interaction leaves the profile locked; do not weaken ACL, regenerate keys or fall back to plaintext. No signing/Keychain mutations/native authentication were performed during remediation.

Sources: [Apple Keychain accessibility](https://developer.apple.com/documentation/security/restricting-keychain-item-accessibility), [userPresence](https://developer.apple.com/documentation/security/secaccesscontrolcreateflags/userpresence), [actual SDK inventory](../../evidence/20261108T103813Z-m1-validation-remediation/results/candidate-availability.json). No assumption that biometrics are available; supported OS-native fallback behavior is a qualification criterion.

## 4. Independent recovery material and custody

### Printable kit

Print format: visible VX Browser Recovery Kit v1, scope type/UUID, envelope/recovery generation, warning that possession authorizes decryption, Base32-encoded256-bit R, checksum and the encrypted recovery capsule with format/length labels. Use RFC4648 uppercase Base32 without padding,52 significant characters for R in13 groups of4; whitespace/hyphens are presentation separators, lowercase may normalize to uppercase, nonalphabet/incorrect trailing bits reject. Do not silently substitute ambiguous digits. The checksum is the first40 bits of SHA256 over version/scope/generation/R, encoded as8 Base32 characters: transcription detection only, not authentication.

The printed capsule contains the complete recovery slot/header needed to recover its declared DEK versions. It is ciphertext, not the DEK. Multi-page printed ciphertext must carry page/order/length/checksum metadata and full authenticated reconstruction; a missing page fails. A QR is optional presentation of the same exact data, not a different authority or required third-party service.

R is random high entropy, not a memorable human password; HKDF is not a password-hardening function. This v1 does not invent an unqualified password KDF or weak password fallback. Any later password-protected alternative needs separate specified suite/qualification.

Printing can create local OS/printer spool artifacts; explain this custody limitation. Never send the kit through telemetry, a cloud print service, Vezham servers, clipboard convenience, logs or crash diagnostics. No print operation is executed by this task.

### Exportable encrypted recovery file

VXRF container is deterministic CBOR map0=ASCII magic VXRF(byte string),1=major1,2=minor0,3=the complete independently authenticated recovery slot map from §2. The slot carries suite1 semantics and encrypted DEK-version payload; outer format values must match the selected decoder and cannot override authenticated slot context. Maximum1MiB and64 versions. File contains no R or plaintext DEK. Unlock uses independently held R from the kit or an equivalent separately saved secret. The encrypted file alone is intentionally insufficient; losing both its unlock secret and normal Keychain authority can make it unusable. Paper kit includes the encrypted capsule, so paper+profile data is an independent path without requiring the separate file or source Mac.

The file and printable kit use the same recovery authority for this scope; they are two custody representations, not two unrelated encryption identities. A compatible profile/full backup must carry the appropriate encrypted recovery slot so R plus that backup can recover offline. Do not imply a kit can decrypt an archive whose required key-version capsule was never included.

Export is explicit and native-authorized; no silent overwrite. Verify the bytes read back from the selected saved file, parse/decrypt with R, check scope/key-version identity and recover a synthetic verification record before recording export verification. Verify full kit reconstruction similarly; user acknowledgement alone does not prove correct secret capture. Persist only an encrypted verification receipt/version/custody acknowledgement, never the secret or a secret hash for diagnostics.

Generate R locally; temporarily hold it only for verified export/print flow and then retire live copies. Store the recovery file/kit separately from the Mac and backups under user control. Never automatically retain an unprotected copy on Vezham servers. If custody is not verified, clearly show recovery setup incomplete rather than silently claiming recoverability.

### Offline recovery sequence

1. Select explicit owned destination and input profile/archive/capsule; bound-parse versions without modifying originals.
2. Obtain R through native protected UI; reconstruct and validate checksum/encoding locally; derive recovery wrapping key and authenticate capsule.
3. Validate scope/key/database suite and requested retained versions; decrypt only into protected owned staging; verify expected authenticated database records.
4. Apply known deletion records; if coverage unknown, require scope/archive-bound confirmation without claiming global freshness.
5. On a new Mac, generate fresh normal KEK and create the protected destination Keychain item; rewrap recovered DEKs for that device. Never import old native access tokens.
6. Validate destination identity/integrity/reopen, then checkpoint/promote without overwriting existing data. Preserve all inputs until success; conflicts require explicit authorization.
7. Retire temporary keys and disclose exact restored/excluded scope. No mandatory Vezham account/server/network.

If normal Keychain is unavailable but R/capsule/data are valid, independent restore remains possible on an authorized supported environment. If a profile is already unlocked, recovery export/rotation still requires fresh native authentication and explicit intent; existing browsing access is not export consent.

## 5. Profile lock and key lifecycle

| State/transition | Required behavior |
|---|---|
| Startup/Locked | No profile DEK/KEK lease or live DB connection; persistent lock marker/catalog/checkpoint does not restore authority |
| Unlocking | Fresh OS-authenticated Keychain or explicit independent-recovery operation; one scope/generation; deny concurrent stale completions |
| Unlocked | Bounded native key/DB leases; Core policy and platform side effects revalidate current profile epoch |
| Manual/OS lock/sleep/macOS session switch/inactivity | Immediately fence ingress and retire access generation; invalidate LAContext and pending approvals; move to Locking |
| Locking | Stop new native actions; cancel/reconcile in-flight work; suspend/retire WebKit views through qualified public lifecycle; finish known commits without publishing sensitive results; close statements/connections/provider key handles and retire native secret leases; discard sensitive Core/UI result caches and plaintext profile projections after any required encrypted checkpoint, leaving only authorized opaque locked placeholders |
| Locked completion | Only after actual data/key/view access barrier established; UI hiding or media pause is insufficient; other profiles remain usable |
| Barrier failure | AccessBlocked/CleanupRequired; no false locked/cleaned acknowledgement. Preserve metadata needed to diagnose without plaintext content |
| Reacquisition | New authentication context/key leases/view generations; no reuse of old subscription results or pending permissions |
| Quit/restart/crash | Fresh run/authority IDs; OP-04 normal/restart restore vs crash prompt; private discarded; locked entries remain locked; no automatic form/POST/grant replay |

Define deadlines from measured supported-platform behavior before execution; no arbitrary sleep is proof of resource release. The WebKit access-stop mechanism is still a feasibility gate: this document requires it, but does not assert that destroying or suspending a WKWebView immediately stops every engine task. EXP-05 must establish it. WebKit's own at-rest data is not protected by this key barrier's SQLite mechanism.

In-flight storage: cancellation before commit is not rollback after commit; worker resolves revision/receipt, retires cursor/connection/keys before lock success. No sensitive event reaches retired UI/subscription generations. Late completions are reconciled internally, not replayed as new actions.

Downloads: no new file grants or reauthorization while locked; pause/cancel where supported and retain only reviewed protected reconciliation state. If engine resume cannot be safely bounded, report unsupported/interrupted. Do not silently continue operations using a retained profile key. Finalizing an already-authorized external write needs exact native authority/reconciliation; lack of a safe barrier blocks lock success. No private history is persisted to solve restart cleanup.

Multiple profiles have independent DEKs/KEKs/R/epochs and leases. Locking A never grants B authority or destroys B's views/files. Global OS events trigger applicable locks, but a failure in one scope cannot expose another.

## 6. Rotation and recovery-version lifecycle

- KEK rotation: fresh normal KEK and slot generation; authenticate existing DEK ring, write/verify new slot, checkpoint Keychain/envelope transition, preserve old protected slot until new normal access is verified and unchanged recovery-capsule coverage/prior verification receipt is confirmed. Fresh R is required only when the DEK ring/recovery authority changes, not merely to rewrap the same ring with a new normal KEK.
- Recovery-secret rotation: explicit fresh authentication, generate new R, capsule and verified kit/file. Old printed secrets/capsules cannot be revoked from disconnected media; explain their historical decryption authority. No claim of remote invalidation.
- DEK rotation: quiesce affected data, create encrypted copy using fresh DEK input, verify database/capsule/recovery, persist rotation intent and generation, then promote. Keep old encrypted DB/key versions until verified success and declared manual-backup dependencies are handled. Never discard the sole old key on crash.
- Interrupted rotation: native startup reads authenticated intent and exact resource identities; verify whichever branch is complete, retain both on ambiguity, deny normal writes until reconciled. No silent destructive reset/downgrade.
- Versioned old recovery kits may recover only their declared key ring. New backups must include matching capsules; a current kit need not unlock an old archive encrypted under an unrelated retired recovery authority. Preserve/disclose migration coverage explicitly.
- Deleting keys/data is an explicit authorized product operation with per-scope completion/partial outcomes, not an action performed by this remediation.

## 7. Loss and failure matrix

| Scenario | Required outcome |
|---|---|
| Keychain unavailable/cancelled | Remain locked; preserve ciphertext; offer independent offline recovery where inputs exist |
| Keychain item deleted | Do not regenerate a replacement over the old DB; recover with R+capsule/data, then create fresh destination KEK |
| Recovery R lost, normal access works | Existing profile still accessible; explicit verified recovery-secret rotation possible; old exported copies may still require old R |
| Recovery file lost, paper kit intact | Printed capsule+R can recover declared key versions with profile data; verify actual coverage |
| Paper lost, file and separately saved R exist | File+R can recover declared scope; file alone cannot |
| Recovery material corrupted | Reject checksum/parser/tag failure; preserve all inputs; no best-effort key guessing |
| Wrong R/profile/capsule | AEAD/identity fails; no plaintext publication or destination replacement |
| Database corrupted | Recovery keys do not repair missing/corrupt pages; preserve and use a verified compatible backup if available |
| Recovery manifest corrupted | Reject unauthenticated metadata; no key-version/profile guess |
| Incompatible major/suite/version | Refuse without mutation; require a separately validated migration/export path |
| Interrupted KEK/DEK/R rotation | Reconcile authenticated old/new generations and retained ciphertext; ambiguity stays blocked |
| Partial restore | Preserve original/archive/destination and checkpoint; never advertise success or delete sole inputs |
| Existing destination conflict | No silent overwrite/merge/remap of identity; require explicit authorized conflict resolution |
| Already unlocked export/recovery request | Fresh OS authentication and explicit operation consent, not ambient browsing authority |
| Both normal Keychain authority and all valid independent R/capsule recovery paths unavailable | Profile can be permanently unrecoverable; never promise server rescue or quietly replace it |

## 8. Qualification boundary

Formatting, keys, ACL direction, lock state semantics and failure contracts are specified; no implementation or evidence of enforcement exists. The SDK supports the selected API surface, not a tested Keychain configuration for the app. Database provider binding, interoperable CBOR/AEAD/recovery fixtures, secure key-buffer lifecycle, authenticated rotation checkpoints, actual view/key barrier and independent Mac remain blocking qualifications. [Readiness assessment](m1-validation-readiness-remediation.md) owns EXP-03/04/05/07 classifications. No experiments are made Ready merely by this document.
