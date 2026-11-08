# M1 Final Traceability Refinement — Case-Level Matrix v1.1 — Proposed

This matrix refines the existing supporting-validation package. It does not replace the five SVC charters, alter EXP-01–EXP-08, or authorize execution.

PERM-001–PERM-011 remain case families. Their **110 `.A`–`.J` variants are listed individually**. PERM-012–PERM-021 retain individual rows. Family headings are not counted as additional executable cases.

## Matrix conventions

The existing artifact and environment definitions remain in force.

- Numeric entries in **REQ**, **AC**, **SPEC** and **OD-R** columns carry their existing prefixes.
- **ADR** numbers mean ADR 0001–0005. Their statuses remain: **1 Proposed, 2 Accepted, 3 Proposed, 4 Proposed, 5 Proposed**.
- Every case requires **RESULT** and **REVIEW**, in addition to the artifact codes listed.
- **PN** = Proposed / Not Run.
- **B** = Blocked; the activity remains proposed and unexecuted.
- **U** = **Unspecified — requires specification**; the activity remains unexecuted.
- **—** means intentionally not applicable, not an invented mapping.
- An AC mapping identifies a specific validation route. It does not mean that one case establishes the whole acceptance criterion.
- `*` beside an OP dependency means it applies to affected real-data or activation paths; synthetic controls do not resolve that policy.

Platform shorthand merely compresses the existing environment conditions:

| Shorthand | Existing condition |
|---|---|
| T26 | Declared macOS 26 target/SDK conformance; not runtime qualification |
| M26 | Supported macOS 26 runtime qualification; newer-host discovery must remain labelled separately |
| I | Interactive logged-in session |
| A | Native authorization interaction |
| C | Controlled connectivity/origins |
| O | Network isolation; no mandatory local server |
| P/N | Persistent/nonpersistent WebKit stores |
| F | Owned filesystem fixtures |
| K | Isolated test Keychain conditions |
| 2M | Independent second Mac |
| X | Safely attributed termination/relaunch |
| MS | Multiple macOS sessions, only for the session-switch subcase |

For permission negatives, an inherited AM/AU environment does **not** require actually granting device access. A policy-only negative result cannot qualify native positive support.

All prerequisites below are requirements for future authorized execution—not decisions supplied by this matrix.

## Consolidated case-level matrix

| Case ID | Case description | REQ | AC | SPEC | OD-R | ADR | Parent | Additional evidence | Environment | Required platform conditions | OP dependency | Prerequisites/dependencies | Status |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| PKG-001 | Four targets and permitted dependency graph | 02 | 02 | 01 | 01,02,03 | 3 | SVC-01 | CFG, GRAPH | D0/C0 | T26; actual manifests | — | Concrete targets and reviewed graph | PN |
| PKG-002 | Exported contracts exclude platform/database objects | 02 | 02 | 01,02 | 01,03 | 1,3 | SVC-01 | GRAPH, TRACE | C0 | T26; interface inspection | — | Actual exported types | PN |
| PKG-003 | Core/host/adapter/SQLite ownership boundaries | 02,03 | 02,14 | 01,02,03 | 02,03,04,10,15 | 1,3,4,5 | SVC-01 | CFG, GRAPH | D0/C0 | T26; adapter placement U | — | Final target placement and bindings | U |
| PKG-004 | Reject prohibited imports and dependency cycles | 02 | 02 | 01 | 03,15 | 3,5 | SVC-01 | FX, GRAPH | C0 | T26; isolated invalid fixtures | — | Final dependency rules | PN |
| PKG-005 | Required/optional bindings, rollback and disposal | 17 | 02,15 | 01,06,14 | 15,16 | 5 | SVC-01 | FX, TRACE, STATE | C0 | T26; fake providers | — | Binding/lifecycle contracts | PN |
| PKG-006 | Suspension, retired owners and late completions | 18 | 14,15 | 06,14,15 | 01,16 | 3,5 | SVC-01 | TRACE, STATE | C0 | T26; controlled scheduling | — | Generation/revision contract | PN |
| PKG-007 | Repository leases, private refusal and receipts | 04,19 | 03,04,15 | 03,06,15 | 04,05,06,16 | 3,4 | SVC-01 | TRACE, STATE, FAULT | DB0 | M26, F; controlled reopen | — | Schema, worker and receipt details | U |
| BRIDGE-001 | Valid owned command uses native authority | 03 | 14 | 02,14 | 02,16 | 1,3,5 | SVC-02 | CFG, TRACE, STATE | I0/C0 | M26, I; registered surface | — | Actual command schema and bridge | U |
| BRIDGE-002 | Reject malformed/version/type/size/depth input | 03,18 | 14,15 | 02,14,15 | 02,16 | 1,5 | SVC-02 | FX, TRACE | I0/C0 | M26, I; isolated vectors | — | Codec, bounds and protocol finalized | U |
| BRIDGE-003 | Reject website/subframe/wrong-origin authority | 03 | 14 | 02,14 | 02,10,16 | 1,5 | SVC-02 | TRACE, UI | I0 | M26, I, C, P/N | — | Fixed origin/sender/hosting contract | U |
| BRIDGE-004 | Reject forged profile/view/AppRun/context | 03,04,18 | 03,14 | 02,06,14 | 02,10,16 | 1,3,5 | SVC-02 | TRACE, STATE | I0/C0 | M26, I; A/B contexts | — | Native registry and generations | PN |
| BRIDGE-005 | Replay, payload mismatch and revision conflict | 18,19 | 15 | 03,14,15 | 16 | 4,5 | SVC-02 | TRACE, STATE | I0/C0 | M26, I, F | — | Request/receipt/revision semantics | PN |
| BRIDGE-006 | Close/quiesce/navigation retires pending effects | 03,17,18 | 14,15 | 06,14,15 | 15,16 | 1,5 | SVC-02 | TRACE, FAULT, STATE | I0/C0 | M26, I; controlled retirement | — | Lifecycle and cleanup contract | PN |
| BRIDGE-007 | Gaps/overflow/revocation require scoped resnapshot | 18 | 14,15 | 14,15 | 16 | 5 | SVC-02 | TRACE, STATE | I0/C0 | M26, I; bounded subscribers | — | Queue and snapshot rules | PN |
| BRIDGE-008 | Coarse errors preserve truthful effect outcome | 19 | 15 | 03,15 | 02,16 | 4,5 | SVC-02 | FAULT, TRACE | I0/C0 | M26, I, F | — | Error and commit-result contract | PN |
| BRIDGE-009 | Bundled origin/CSP/navigation and no server dependency | 01,03 | 01,14 | 02,16 | 02,04 | 1,2 | SVC-02 | CFG, TRACE, UI | I0 | M26, I; server stopped | — | Hosting/CSP/resource contract | U |
| PERM-001.A | Camera: supported affirmative control | 10 | 09 | 09 | 11 | 1 | SVC-03 | CFG, AUTH, TRACE | AM | M26, I, A, C, P; approved camera | — | M1 media binding and fresh access authorization | PN |
| PERM-001.B | Camera: browser denial/cancellation | 10 | 09,15 | 09,15 | 11,16 | 1,5 | SVC-03 | FX, TRACE | AM | M26, I, C; no device grant | — | Broker deny/cancel contract | PN |
| PERM-001.C | Camera: wrong/changed origin or frame | 03,10 | 09,14 | 02,09 | 11 | 1,5 | SVC-03 | FX, TRACE, STATE | AM | M26, I, C; policy negative | — | Trusted origin/request context | PN |
| PERM-001.D | Camera: foreign profile/private scope | 04,10 | 03,09,14 | 06,09 | 06,11 | 1,4 | SVC-03 | FX, TRACE, STATE | AM | M26, I, P/N; policy negative | — | Scope binding | PN |
| PERM-001.E | Camera: temporary consumption/expiry | 10 | 09 | 09,15 | 11 | 1,5 | SVC-03 | FX, TRACE, STATE | AM | M26, I; controlled clock | — | Per-kind lifetime semantics | U |
| PERM-001.F | Camera: profile grant and private exclusion | 10 | 09,14 | 03,09 | 11 | 1,4 | SVC-03 | AUTH, TRACE, STATE | AM | M26, I, A, P/N, F | — | Persistent-grant/native mapping | U |
| PERM-001.G | Camera: revoke then request again | 10 | 09,14 | 09,14,15 | 11,16 | 1,5 | SVC-03 | AUTH, TRACE, STATE | AM | M26, I, A, C | — | Revocation and fresh-request semantics | U |
| PERM-001.H | Camera: lock/navigation/profile generation fence | 10,18 | 09,14 | 07,09,14 | 11,16,18 | 1,5 | SVC-03 | TRACE, STATE | AM/L0 | M26, I; scoped lifecycle | — | Request/access generations; native lock proof separate | PN |
| PERM-001.I | Camera: OS denial despite browser allow | 10 | 09 | 09 | 11 | 1 | SVC-03 | AUTH, TRACE | AM | M26, I, A; actual OS denial | — | Native media broker and denied state | PN |
| PERM-001.J | Camera: scoped reset/delete/cancel | 10,19 | 09,15 | 06,09,15 | 11 | 1,4,5 | SVC-03 | AUTH, TRACE, STATE | AM | M26, I; scoped authorization | — | Per-kind reset/cancel method | U |
| PERM-002.A | Microphone: supported affirmative control | 10 | 09 | 09 | 11 | 1 | SVC-03 | CFG, AUTH, TRACE | AM | M26, I, A, C, P; approved microphone | — | M1 media binding and fresh access authorization | PN |
| PERM-002.B | Microphone: browser denial/cancellation | 10 | 09,15 | 09,15 | 11,16 | 1,5 | SVC-03 | FX, TRACE | AM | M26, I, C; no device grant | — | Broker deny/cancel contract | PN |
| PERM-002.C | Microphone: wrong/changed origin or frame | 03,10 | 09,14 | 02,09 | 11 | 1,5 | SVC-03 | FX, TRACE, STATE | AM | M26, I, C; policy negative | — | Trusted origin/request context | PN |
| PERM-002.D | Microphone: foreign profile/private scope | 04,10 | 03,09,14 | 06,09 | 06,11 | 1,4 | SVC-03 | FX, TRACE, STATE | AM | M26, I, P/N; policy negative | — | Scope binding | PN |
| PERM-002.E | Microphone: temporary consumption/expiry | 10 | 09 | 09,15 | 11 | 1,5 | SVC-03 | FX, TRACE, STATE | AM | M26, I; controlled clock | — | Per-kind lifetime semantics | U |
| PERM-002.F | Microphone: profile grant and private exclusion | 10 | 09,14 | 03,09 | 11 | 1,4 | SVC-03 | AUTH, TRACE, STATE | AM | M26, I, A, P/N, F | — | Persistent-grant/native mapping | U |
| PERM-002.G | Microphone: revoke then request again | 10 | 09,14 | 09,14,15 | 11,16 | 1,5 | SVC-03 | AUTH, TRACE, STATE | AM | M26, I, A, C | — | Revocation and fresh-request semantics | U |
| PERM-002.H | Microphone: lock/navigation/profile generation fence | 10,18 | 09,14 | 07,09,14 | 11,16,18 | 1,5 | SVC-03 | TRACE, STATE | AM/L0 | M26, I; scoped lifecycle | — | Request/access generations; native lock proof separate | PN |
| PERM-002.I | Microphone: OS denial despite browser allow | 10 | 09 | 09 | 11 | 1 | SVC-03 | AUTH, TRACE | AM | M26, I, A; actual OS denial | — | Native media broker and denied state | PN |
| PERM-002.J | Microphone: scoped reset/delete/cancel | 10,19 | 09,15 | 06,09,15 | 11 | 1,4,5 | SVC-03 | AUTH, TRACE, STATE | AM | M26, I; scoped authorization | — | Per-kind reset/cancel method | U |
| PERM-003.A | Combined media: affirmative control | 10 | 09 | 09 | 11 | 1 | SVC-03 | CFG, AUTH, TRACE | AM | M26, I, A, C, P; both devices | — | M1 combined mapping; both OS states accounted for | PN |
| PERM-003.B | Combined media: browser denial/cancellation | 10 | 09,15 | 09,15 | 11,16 | 1,5 | SVC-03 | FX, TRACE | AM | M26, I, C; no device grant | — | Combined deny/cancel contract | PN |
| PERM-003.C | Combined media: wrong/changed origin or frame | 03,10 | 09,14 | 02,09 | 11 | 1,5 | SVC-03 | FX, TRACE, STATE | AM | M26, I, C; policy negative | — | Trusted origin/request context | PN |
| PERM-003.D | Combined media: foreign profile/private scope | 04,10 | 03,09,14 | 06,09 | 06,11 | 1,4 | SVC-03 | FX, TRACE, STATE | AM | M26, I, P/N; policy negative | — | Scope binding | PN |
| PERM-003.E | Combined media: temporary consumption/expiry | 10 | 09 | 09,15 | 11 | 1,5 | SVC-03 | FX, TRACE, STATE | AM | M26, I; controlled clock | — | Combined lifetime semantics | U |
| PERM-003.F | Combined media: profile grant/private exclusion | 10 | 09,14 | 03,09 | 11 | 1,4 | SVC-03 | AUTH, TRACE, STATE | AM | M26, I, A, P/N, F | — | Persistent combined grant/native mapping | U |
| PERM-003.G | Combined media: revoke then request again | 10 | 09,14 | 09,14,15 | 11,16 | 1,5 | SVC-03 | AUTH, TRACE, STATE | AM | M26, I, A, C | — | Combined/per-device revocation semantics | U |
| PERM-003.H | Combined media: lifecycle generation fence | 10,18 | 09,14 | 07,09,14 | 11,16,18 | 1,5 | SVC-03 | TRACE, STATE | AM/L0 | M26, I; scoped lifecycle | — | Request/access generations | PN |
| PERM-003.I | Combined media: OS-denial combinations | 10 | 09 | 09 | 11 | 1 | SVC-03 | AUTH, TRACE | AM | M26, I, A; each device state controlled | — | Separate accounting of both OS authorizations | PN |
| PERM-003.J | Combined media: scoped reset/delete/cancel | 10,19 | 09,15 | 06,09,15 | 11 | 1,4,5 | SVC-03 | AUTH, TRACE, STATE | AM | M26, I; scoped authorization | — | Combined/per-device reset contract | U |
| PERM-004.A | Geolocation: native affirmative control | 10 | 09 | 09 | 11 | 1 | SVC-03 | CFG, AUTH, TRACE | AU | M26, I, C; native/API conditions U | — | Actual platform/API mapping | B |
| PERM-004.B | Geolocation: browser denial/cancellation | 10 | 09,15 | 09,15 | 11,16 | 1,5 | SVC-03 | FX, TRACE | AU | Policy-only; no native-support claim | — | Policy broker and deny/cancel contract | PN |
| PERM-004.C | Geolocation: origin/frame/navigation negative | 03,10 | 09,14 | 02,09 | 11 | 1,5 | SVC-03 | FX, TRACE, STATE | AU | Policy-only; trusted-context fixture | — | Origin/request contract | PN |
| PERM-004.D | Geolocation: foreign-profile/private negative | 04,10 | 03,09,14 | 06,09 | 06,11 | 1,4 | SVC-03 | FX, TRACE, STATE | AU | Policy-only; A/B/private contexts | — | Scope binding | PN |
| PERM-004.E | Geolocation: temporary consumption/expiry | 10 | 09 | 09,15 | 11 | 1,5 | SVC-03 | FX, TRACE, STATE | AU | Controlled clock; native lifecycle U | — | Per-kind lifetime contract | U |
| PERM-004.F | Geolocation: native profile grant/private exclusion | 10 | 09,14 | 03,09 | 11 | 1,4 | SVC-03 | AUTH, TRACE, STATE | AU | Native/API conditions U | — | Actual native and persistent-grant mapping | B |
| PERM-004.G | Geolocation: native grant revocation | 10 | 09,14 | 09,14,15 | 11,16 | 1,5 | SVC-03 | AUTH, TRACE, STATE | AU | Native/API conditions U | — | Native positive baseline and revoke mapping | B |
| PERM-004.H | Geolocation: stale lifecycle-response rejection | 10,18 | 09,14 | 07,09,14 | 11,16,18 | 1,5 | SVC-03 | TRACE, STATE | AU | Policy-only; generation changes | — | Request/access fencing contract | PN |
| PERM-004.I | Geolocation: actual OS-denial precedence | 10 | 09 | 09 | 11 | 1 | SVC-03 | AUTH, TRACE | AU | Native authorization conditions U | — | Actual OS enforcement mapping | B |
| PERM-004.J | Geolocation: scoped reset/delete/cancel | 10,19 | 09,15 | 06,09,15 | 11 | 1,4,5 | SVC-03 | AUTH, TRACE, STATE | AU | Native reset conditions U | — | Per-kind reset/cancel contract | U |
| PERM-005.A | Notifications: native affirmative control | 10 | 09 | 09 | 11 | 1 | SVC-03 | CFG, AUTH, TRACE | AU | M26, I; native/API conditions U | — | Actual platform/API mapping | B |
| PERM-005.B | Notifications: browser denial/cancellation | 10 | 09,15 | 09,15 | 11,16 | 1,5 | SVC-03 | FX, TRACE | AU | Policy-only; no native-support claim | — | Policy broker and deny/cancel contract | PN |
| PERM-005.C | Notifications: origin/frame/navigation negative | 03,10 | 09,14 | 02,09 | 11 | 1,5 | SVC-03 | FX, TRACE, STATE | AU | Policy-only; trusted-context fixture | — | Origin/request contract | PN |
| PERM-005.D | Notifications: foreign-profile/private negative | 04,10 | 03,09,14 | 06,09 | 06,11 | 1,4 | SVC-03 | FX, TRACE, STATE | AU | Policy-only; A/B/private contexts | — | Scope binding | PN |
| PERM-005.E | Notifications: temporary consumption/expiry | 10 | 09 | 09,15 | 11 | 1,5 | SVC-03 | FX, TRACE, STATE | AU | Controlled clock; native lifecycle U | — | Per-kind lifetime contract | U |
| PERM-005.F | Notifications: native profile grant/private exclusion | 10 | 09,14 | 03,09 | 11 | 1,4 | SVC-03 | AUTH, TRACE, STATE | AU | Native/API conditions U | — | Native registration and persistent-grant mapping | B |
| PERM-005.G | Notifications: native grant revocation | 10 | 09,14 | 09,14,15 | 11,16 | 1,5 | SVC-03 | AUTH, TRACE, STATE | AU | Native/API conditions U | — | Native positive baseline and revoke mapping | B |
| PERM-005.H | Notifications: stale lifecycle-response rejection | 10,18 | 09,14 | 07,09,14 | 11,16,18 | 1,5 | SVC-03 | TRACE, STATE | AU | Policy-only; generation changes | — | Request/access fencing contract | PN |
| PERM-005.I | Notifications: actual OS-denial precedence | 10 | 09 | 09 | 11 | 1 | SVC-03 | AUTH, TRACE | AU | Native authorization conditions U | — | Actual OS enforcement mapping | B |
| PERM-005.J | Notifications: scoped reset/delete/cancel | 10,19 | 09,15 | 06,09,15 | 11 | 1,4,5 | SVC-03 | AUTH, TRACE, STATE | AU | Native reset conditions U | — | Registration/reset/cancel contract | U |
| PERM-006.A | Clipboard-read: native affirmative control | 10 | 09 | 09 | 11 | 1 | SVC-03 | CFG, AUTH, TRACE | AU | M26, I; native/API conditions U | — | Actual platform/API mapping | B |
| PERM-006.B | Clipboard-read: browser denial/cancellation | 10 | 09,15 | 09,15 | 11,16 | 1,5 | SVC-03 | FX, TRACE | AU | Policy-only; no real clipboard access | — | Policy broker and deny/cancel contract | PN |
| PERM-006.C | Clipboard-read: origin/frame/navigation negative | 03,10 | 09,14 | 02,09 | 11 | 1,5 | SVC-03 | FX, TRACE, STATE | AU | Policy-only; trusted-context fixture | — | Origin/request contract | PN |
| PERM-006.D | Clipboard-read: foreign-profile/private negative | 04,10 | 03,09,14 | 06,09 | 06,11 | 1,4 | SVC-03 | FX, TRACE, STATE | AU | Policy-only; A/B/private contexts | — | Scope binding | PN |
| PERM-006.E | Clipboard-read: temporary consumption/expiry | 10 | 09 | 09,15 | 11 | 1,5 | SVC-03 | FX, TRACE, STATE | AU | Controlled clock; native lifecycle U | — | Per-kind lifetime/gesture contract | U |
| PERM-006.F | Clipboard-read: native profile grant/private exclusion | 10 | 09,14 | 03,09 | 11 | 1,4 | SVC-03 | AUTH, TRACE, STATE | AU | Native/API conditions U | — | Native and persistent-grant mapping | B |
| PERM-006.G | Clipboard-read: native grant revocation | 10 | 09,14 | 09,14,15 | 11,16 | 1,5 | SVC-03 | AUTH, TRACE, STATE | AU | Native/API conditions U | — | Native positive baseline and revoke mapping | B |
| PERM-006.H | Clipboard-read: stale lifecycle-response rejection | 10,18 | 09,14 | 07,09,14 | 11,16,18 | 1,5 | SVC-03 | TRACE, STATE | AU | Policy-only; generation changes | — | Request/access fencing contract | PN |
| PERM-006.I | Clipboard-read: actual OS-denial precedence | 10 | 09 | 09 | 11 | 1 | SVC-03 | AUTH, TRACE | AU | Native authorization conditions U | — | Actual platform enforcement model | B |
| PERM-006.J | Clipboard-read: scoped reset/delete/cancel | 10,19 | 09,15 | 06,09,15 | 11 | 1,4,5 | SVC-03 | AUTH, TRACE, STATE | AU | Native reset conditions U | — | Per-kind reset/cancel contract | U |
| PERM-007.A | Clipboard-write: native affirmative control | 10 | 09 | 09 | 11 | 1 | SVC-03 | CFG, AUTH, TRACE | AU | M26, I; native/API conditions U | — | Actual platform/API mapping | B |
| PERM-007.B | Clipboard-write: browser denial/cancellation | 10 | 09,15 | 09,15 | 11,16 | 1,5 | SVC-03 | FX, TRACE | AU | Policy-only; no real clipboard mutation | — | Policy broker and deny/cancel contract | PN |
| PERM-007.C | Clipboard-write: origin/frame/navigation negative | 03,10 | 09,14 | 02,09 | 11 | 1,5 | SVC-03 | FX, TRACE, STATE | AU | Policy-only; trusted-context fixture | — | Origin/request contract | PN |
| PERM-007.D | Clipboard-write: foreign-profile/private negative | 04,10 | 03,09,14 | 06,09 | 06,11 | 1,4 | SVC-03 | FX, TRACE, STATE | AU | Policy-only; A/B/private contexts | — | Scope binding | PN |
| PERM-007.E | Clipboard-write: temporary consumption/expiry | 10 | 09 | 09,15 | 11 | 1,5 | SVC-03 | FX, TRACE, STATE | AU | Controlled clock; native lifecycle U | — | Per-kind lifetime/gesture contract | U |
| PERM-007.F | Clipboard-write: native profile grant/private exclusion | 10 | 09,14 | 03,09 | 11 | 1,4 | SVC-03 | AUTH, TRACE, STATE | AU | Native/API conditions U | — | Native and persistent-grant mapping | B |
| PERM-007.G | Clipboard-write: native grant revocation | 10 | 09,14 | 09,14,15 | 11,16 | 1,5 | SVC-03 | AUTH, TRACE, STATE | AU | Native/API conditions U | — | Native positive baseline and revoke mapping | B |
| PERM-007.H | Clipboard-write: stale lifecycle-response rejection | 10,18 | 09,14 | 07,09,14 | 11,16,18 | 1,5 | SVC-03 | TRACE, STATE | AU | Policy-only; generation changes | — | Request/access fencing contract | PN |
| PERM-007.I | Clipboard-write: actual OS-denial precedence | 10 | 09 | 09 | 11 | 1 | SVC-03 | AUTH, TRACE | AU | Native authorization conditions U | — | Actual platform enforcement model | B |
| PERM-007.J | Clipboard-write: scoped reset/delete/cancel | 10,19 | 09,15 | 06,09,15 | 11 | 1,4,5 | SVC-03 | AUTH, TRACE, STATE | AU | Native reset conditions U | — | Per-kind reset/cancel contract | U |
| PERM-008.A | Bluetooth: native affirmative control | 10 | 09 | 09 | 11 | 1 | SVC-03 | CFG, AUTH, TRACE | AU | M26, I; device/API conditions U | — | Actual platform/API/device mapping | B |
| PERM-008.B | Bluetooth: browser denial/cancellation | 10 | 09,15 | 09,15 | 11,16 | 1,5 | SVC-03 | FX, TRACE | AU | Policy-only; no ambient scanning | — | Policy broker and deny/cancel contract | PN |
| PERM-008.C | Bluetooth: origin/frame/navigation negative | 03,10 | 09,14 | 02,09 | 11 | 1,5 | SVC-03 | FX, TRACE, STATE | AU | Policy-only; trusted-context fixture | — | Origin/request contract | PN |
| PERM-008.D | Bluetooth: foreign-profile/private negative | 04,10 | 03,09,14 | 06,09 | 06,11 | 1,4 | SVC-03 | FX, TRACE, STATE | AU | Policy-only; A/B/private contexts | — | Scope binding | PN |
| PERM-008.E | Bluetooth: temporary consumption/expiry | 10 | 09 | 09,15 | 11 | 1,5 | SVC-03 | FX, TRACE, STATE | AU | Controlled clock; native lifecycle U | — | Per-kind lifetime/device contract | U |
| PERM-008.F | Bluetooth: native profile grant/private exclusion | 10 | 09,14 | 03,09 | 11 | 1,4 | SVC-03 | AUTH, TRACE, STATE | AU | Native/device conditions U | — | Native and persistent-grant mapping | B |
| PERM-008.G | Bluetooth: native grant revocation | 10 | 09,14 | 09,14,15 | 11,16 | 1,5 | SVC-03 | AUTH, TRACE, STATE | AU | Native/device conditions U | — | Native positive baseline and revoke mapping | B |
| PERM-008.H | Bluetooth: stale lifecycle-response rejection | 10,18 | 09,14 | 07,09,14 | 11,16,18 | 1,5 | SVC-03 | TRACE, STATE | AU | Policy-only; generation changes | — | Request/access fencing contract | PN |
| PERM-008.I | Bluetooth: actual OS-denial precedence | 10 | 09 | 09 | 11 | 1 | SVC-03 | AUTH, TRACE | AU | Native authorization conditions U | — | Actual platform enforcement mapping | B |
| PERM-008.J | Bluetooth: scoped reset/delete/cancel | 10,19 | 09,15 | 06,09,15 | 11 | 1,4,5 | SVC-03 | AUTH, TRACE, STATE | AU | Native reset conditions U | — | Device/reset/cancel contract | U |
| PERM-009.A | USB: native affirmative control | 10 | 09 | 09 | 11 | 1 | SVC-03 | CFG, AUTH, TRACE | AU | M26, I; device/API conditions U | — | Actual platform/API/device mapping | B |
| PERM-009.B | USB: browser denial/cancellation | 10 | 09,15 | 09,15 | 11,16 | 1,5 | SVC-03 | FX, TRACE | AU | Policy-only; no device access | — | Policy broker and deny/cancel contract | PN |
| PERM-009.C | USB: origin/frame/navigation negative | 03,10 | 09,14 | 02,09 | 11 | 1,5 | SVC-03 | FX, TRACE, STATE | AU | Policy-only; trusted-context fixture | — | Origin/request contract | PN |
| PERM-009.D | USB: foreign-profile/private negative | 04,10 | 03,09,14 | 06,09 | 06,11 | 1,4 | SVC-03 | FX, TRACE, STATE | AU | Policy-only; A/B/private contexts | — | Scope binding | PN |
| PERM-009.E | USB: temporary consumption/expiry | 10 | 09 | 09,15 | 11 | 1,5 | SVC-03 | FX, TRACE, STATE | AU | Controlled clock; native lifecycle U | — | Per-kind lifetime/device contract | U |
| PERM-009.F | USB: native profile grant/private exclusion | 10 | 09,14 | 03,09 | 11 | 1,4 | SVC-03 | AUTH, TRACE, STATE | AU | Native/device conditions U | — | Native and persistent-grant mapping | B |
| PERM-009.G | USB: native grant revocation | 10 | 09,14 | 09,14,15 | 11,16 | 1,5 | SVC-03 | AUTH, TRACE, STATE | AU | Native/device conditions U | — | Native positive baseline and revoke mapping | B |
| PERM-009.H | USB: stale lifecycle-response rejection | 10,18 | 09,14 | 07,09,14 | 11,16,18 | 1,5 | SVC-03 | TRACE, STATE | AU | Policy-only; generation changes | — | Request/access fencing contract | PN |
| PERM-009.I | USB: actual OS-denial precedence | 10 | 09 | 09 | 11 | 1 | SVC-03 | AUTH, TRACE | AU | Native authorization conditions U | — | Actual platform enforcement mapping | B |
| PERM-009.J | USB: scoped reset/delete/cancel | 10,19 | 09,15 | 06,09,15 | 11 | 1,4,5 | SVC-03 | AUTH, TRACE, STATE | AU | Native reset conditions U | — | Device/reset/cancel contract | U |
| PERM-010.A | MIDI: native affirmative control | 10 | 09 | 09 | 11 | 1 | SVC-03 | CFG, AUTH, TRACE | AU | M26, I; device/API conditions U | — | Actual platform/API/device mapping | B |
| PERM-010.B | MIDI: browser denial/cancellation | 10 | 09,15 | 09,15 | 11,16 | 1,5 | SVC-03 | FX, TRACE | AU | Policy-only; no device access | — | Policy broker and deny/cancel contract | PN |
| PERM-010.C | MIDI: origin/frame/navigation negative | 03,10 | 09,14 | 02,09 | 11 | 1,5 | SVC-03 | FX, TRACE, STATE | AU | Policy-only; trusted-context fixture | — | Origin/request contract | PN |
| PERM-010.D | MIDI: foreign-profile/private negative | 04,10 | 03,09,14 | 06,09 | 06,11 | 1,4 | SVC-03 | FX, TRACE, STATE | AU | Policy-only; A/B/private contexts | — | Scope binding | PN |
| PERM-010.E | MIDI: temporary consumption/expiry | 10 | 09 | 09,15 | 11 | 1,5 | SVC-03 | FX, TRACE, STATE | AU | Controlled clock; native lifecycle U | — | Per-kind lifetime/device contract | U |
| PERM-010.F | MIDI: native profile grant/private exclusion | 10 | 09,14 | 03,09 | 11 | 1,4 | SVC-03 | AUTH, TRACE, STATE | AU | Native/device conditions U | — | Native and persistent-grant mapping | B |
| PERM-010.G | MIDI: native grant revocation | 10 | 09,14 | 09,14,15 | 11,16 | 1,5 | SVC-03 | AUTH, TRACE, STATE | AU | Native/device conditions U | — | Native positive baseline and revoke mapping | B |
| PERM-010.H | MIDI: stale lifecycle-response rejection | 10,18 | 09,14 | 07,09,14 | 11,16,18 | 1,5 | SVC-03 | TRACE, STATE | AU | Policy-only; generation changes | — | Request/access fencing contract | PN |
| PERM-010.I | MIDI: actual OS-denial precedence | 10 | 09 | 09 | 11 | 1 | SVC-03 | AUTH, TRACE | AU | Native authorization conditions U | — | Actual platform enforcement mapping | B |
| PERM-010.J | MIDI: scoped reset/delete/cancel | 10,19 | 09,15 | 06,09,15 | 11 | 1,4,5 | SVC-03 | AUTH, TRACE, STATE | AU | Native reset conditions U | — | Device/reset/cancel contract | U |
| PERM-011.A | Screen capture: native affirmative control | 10 | 09 | 09 | 11 | 1 | SVC-03 | CFG, AUTH, TRACE | AU | M26, I; capture/API conditions U | — | Actual platform/API/selection mapping | B |
| PERM-011.B | Screen capture: browser denial/cancellation | 10 | 09,15 | 09,15 | 11,16 | 1,5 | SVC-03 | FX, TRACE | AU | Policy-only; no capture | — | Policy broker and deny/cancel contract | PN |
| PERM-011.C | Screen capture: origin/frame/navigation negative | 03,10 | 09,14 | 02,09 | 11 | 1,5 | SVC-03 | FX, TRACE, STATE | AU | Policy-only; trusted-context fixture | — | Origin/request contract | PN |
| PERM-011.D | Screen capture: foreign-profile/private negative | 04,10 | 03,09,14 | 06,09 | 06,11 | 1,4 | SVC-03 | FX, TRACE, STATE | AU | Policy-only; A/B/private contexts | — | Scope binding | PN |
| PERM-011.E | Screen capture: temporary consumption/expiry | 10 | 09 | 09,15 | 11 | 1,5 | SVC-03 | FX, TRACE, STATE | AU | Controlled clock; native lifecycle U | — | Per-kind lifetime/capture contract | U |
| PERM-011.F | Screen capture: native profile grant/private exclusion | 10 | 09,14 | 03,09 | 11 | 1,4 | SVC-03 | AUTH, TRACE, STATE | AU | Native/capture conditions U | — | Native and persistent-grant mapping | B |
| PERM-011.G | Screen capture: native grant revocation | 10 | 09,14 | 09,14,15 | 11,16 | 1,5 | SVC-03 | AUTH, TRACE, STATE | AU | Native/capture conditions U | — | Native positive baseline and revoke mapping | B |
| PERM-011.H | Screen capture: stale lifecycle-response rejection | 10,18 | 09,14 | 07,09,14 | 11,16,18 | 1,5 | SVC-03 | TRACE, STATE | AU | Policy-only; generation changes | — | Request/access fencing contract | PN |
| PERM-011.I | Screen capture: actual OS-denial precedence | 10 | 09 | 09 | 11 | 1 | SVC-03 | AUTH, TRACE | AU | Native authorization conditions U | — | Actual platform enforcement mapping | B |
| PERM-011.J | Screen capture: scoped reset/delete/cancel | 10,19 | 09,15 | 06,09,15 | 11 | 1,4,5 | SVC-03 | AUTH, TRACE, STATE | AU | Native reset conditions U | — | Selection/reset/cancel contract | U |
| PERM-012 | Unknown kind: deny before native effect | 10,17 | 09,15 | 09,15 | 11,15 | 1,5 | SVC-03 | FX, TRACE, STATE | C0/I0 | T26 or M26/I; no native grant | — | Unknown-kind dispatch and deny observation | PN |
| PERM-013 | Trusted origins, frames, redirects and user action | 03,10 | 09,14 | 02,09 | 02,11,16 | 1,5 | SVC-03 | FX, TRACE, STATE | I0/C0 | M26, I, C for native route | — | Canonicalization and trusted attribution | U |
| PERM-014 | Grant lifetime, expiry, revoke and browser reset | 10 | 09,15 | 09,14,15 | 11,16 | 1,5 | SVC-03 | AUTH, TRACE, STATE | I0/AU | Per-kind native conditions U | — | Final lifetime/reset contracts | U |
| PERM-015 | Private decisions leave persistent grants unchanged | 09,10 | 04,09,14 | 03,06,09 | 06,11 | 1,4 | SVC-03 | TRACE, STATE | I0 | M26, I, P/N, F | — | Grant storage and private refusal | PN |
| PERM-016 | Pending response rejected after lock/navigation/switch | 10,18 | 09,14 | 07,09,14 | 11,16,18 | 1,5 | SVC-03 | AUTH, TRACE, STATE | I0/L0 | M26, I; A for unlock; no MS for browser-profile switch | — | Request/access generations and barrier input | PN |
| PERM-017 | Browser and actual native decisions remain independent | 10 | 09 | 09 | 11 | 1 | SVC-03 | AUTH, TRACE | AM/AU | M26, I, A; per-kind conditions U outside media | — | Actual native mapping for each selected kind | U |
| PERM-018 | Missing provider/capability fails closed | 10,17 | 09,15 | 01,09,15 | 11,15 | 1,5 | SVC-03 | CFG, TRACE | C0/I0 | T26 or M26/I; no grant needed | — | Required/optional capability rules | PN |
| PERM-019 | Restored records do not import native authority | 10,14,18 | 09,14,15 | 09,12,14 | 11,14,16 | 1,4,5 | SVC-03 | FX, TRACE, STATE | I0 | M26, I, F; A if native access attempted | 04* | Qualified imported record format and revalidation | U |
| PERM-020 | Runtime capability declarations match evidence | 17 | 02,15 | 01,02,08 | 10,15 | 1,5 | SVC-03 | CFG, TRACE | D0/I0 | M26/I for runtime claims | — | Actual provider/runtime inventory; no inferred support | U |
| PERM-021 | File tokens are scoped; cancel exposes nothing | 03,13 | 11,14,15 | 02,09,11 | 11,13,16,20 | 1,5 | SVC-03 | AUTH, TRACE, STATE | I0 | M26, I, A, C, F | — | Native file-selection/token lifetime contract | U |
| OFFLINE-001 | Cold launch without network or local server | 01 | 01 | 01,02,16 | 04 | 2,3 | SVC-04 | CFG, TRACE, UI | O0 | M26, I, O; servers stopped | — | Integrated bundled local product | PN |
| OFFLINE-002 | Relaunch and access intended persisted state | 01,20 | 01,15 | 03,05,06 | 04,05,09 | 3,4 | SVC-04 | TRACE, STATE, UI | O0 | M26, I, O, F; relaunch | 01/02/04* | Approved dataset and access/reopening policy | PN |
| OFFLINE-003 | Offline profile management and local authentication | 01,06 | 01,15 | 03,05,06 | 04,05,08,09 | 3,4 | SVC-04 | AUTH, TRACE, STATE | O0 | M26, I, O, F, K; A when required | 03* | Profile/key lifecycle; retained-copy policy where affected | U |
| OFFLINE-004 | Local settings and browser-grant inspection/revoke | 01,10 | 01,09 | 03,09 | 04,11 | 4,5 | SVC-04 | TRACE, STATE, UI | O0 | M26, I, O, F | — | Local UI/repository and grant contracts | PN |
| OFFLINE-005 | Offline history/download query and deletion | 01,11,12 | 01,10,11 | 03,10,11 | 04,12,13 | 4 | SVC-04 | TRACE, STATE | O0 | M26, I, O, F | 01/02 | Approved real fields/retention; synthetic controls remain limited | B |
| OFFLINE-006 | Intended local backup/export workflow | 01,16 | 01,12 | 05,11,12 | 04,14,19,20 | 4 | SVC-04 | AUTH, HASH, STATE | O0 | M26, I, O, A, F, K | 01/02/03* | Qualified format and explicit selection | U |
| OFFLINE-007 | Network-dependent failure preserves local usability | 01,19 | 01,15 | 02,15 | 04 | 1,2 | SVC-04 | TRACE, UI | O0 | M26, I, O; request-attempt observation | — | Declared remote/local operation inventory | PN |
| OFFLINE-008 | Private offline workflow leaves no durable state | 01,09 | 01,04,14 | 06,08 | 04,06,10 | 1,4 | SVC-04 | TRACE, STATE | O0 | M26, I, O, P/N, F | — | Private ownership/cleanup contract | PN |
| RECOVERY-001 | Content termination retires view, preserves other scopes | 04,20,22 | 03,08,14,15 | 02,06,08 | 06,10,16 | 1,5 | SVC-05 | FAULT, TRACE, STATE | R0 | M26, I, C, P/N, X | 04* | Safe process attribution and content recovery contract | U |
| RECOVERY-002 | Host death around commit preserves rows/revision/receipt | 19 | 15 | 03,06,15 | 04,05,16 | 3,4 | SVC-05 | FAULT, STATE, HASH | R0/DB0 | M26, F, X; I for app integration | —; synthetic data | Transaction boundaries and fault checkpoints | PN |
| RECOVERY-003 | Fresh identities; no pending/private authority restore | 09,18,20 | 04,14,15 | 06,14,15 | 06,16 | 1,3,5 | SVC-05 | TRACE, STATE | R0 | M26, I, P/N, F, X | 04 | Restore policy for positive cases; exclusions unconditional | B |
| RECOVERY-004 | No automatic POST/form/action replay or fabricated history | 11,20 | 10,15 | 02,06,10,15 | 12,16 | 1,4,5 | SVC-05 | TRACE, FAULT, STATE | R0 | M26, I, C, X | 01/04 | Navigation/recovery/history cause contract | B |
| RECOVERY-005 | Interrupted download/staging preserves external files | 12,13,19 | 11,15 | 03,06,11 | 06,13,20 | 1,4 | SVC-05 | FAULT, HASH, STATE | R0 | M26, I, C, F, X | 02 | Transfer finalization/reconciliation | U |
| RECOVERY-006 | Locked restart cannot bypass or replace keys | 08,19,20 | 07,14,15 | 05,06,07 | 08,09,18 | 1,4,5 | SVC-05 | AUTH, TRACE, STATE | R0/L0 | M26, I, A, K, F, X; MS only if session variant | 04* | Lock persistence, key access and restart contract | U |
| RECOVERY-007 | Corrupt/newer/migration-failed store is preserved | 19 | 15 | 03,06,15 | 04,05,07 | 4 | SVC-05 | FAULT, STATE, HASH | R0/DB0 | M26, F, X | 03 | Supported versions and recovery-copy policy | U |
| RECOVERY-008 | Interrupted promotion preserves archive/original | 14,15,19 | 12,13,15 | 05,06,12,13,15 | 14,17,19 | 4 | SVC-05 | FAULT, HASH, STATE | R0 | M26, I, F, K, X | 03/04;01/02* | Qualified archive, ledger and promotion checkpoints | U |
| RECOVERY-009 | Create/delete recovery separates metadata, external files and restore conflicts | 04,13,16,19 | 03,11,12,15 | 03,06,11,12,15 | 05,13,14,20 | 1,4 | SVC-05 | FAULT, TRACE, STATE, HASH, AUTH | R0 | M26, I, F, X; K/P/N for affected resources | 03* | Scoped saga; file-delete operation U; conflict authorization | U |
| RECOVERY-010 | Recovery UI reflects actual state and approved choices | 19,20 | 15 | 06,15 | 02,16 | 1,3,5 | SVC-05 | UI, TRACE | R0 | M26, I, X | 04 | Approved recovery/reopening policy and error contract | B |
| ISO-001 | Required website-data-class isolation/sharing/deletion | 04,22 | 03,08 | 02,08 | 05,10 | 1 | EXP-01 | CFG, TRACE, STATE | I0 | M26, I, C, P/N | — | Declared class inventory and store bindings | PN |
| PRIV-001 | Private website-data teardown and restart | 09,22 | 04,08,14 | 06,08 | 06,10 | 1,4 | EXP-02 | TRACE, STATE, FAULT | I0/R0 | M26, I, P/N, F; X for crash/restart | — | Private grouping and cleanup contract | PN |
| CRYPTO-001 | Declared DB artifacts and invalid-access controls | 05,06,19 | 05,14,15 | 03,04 | 04,05,07 | 4 | EXP-03 | CFG, HASH, STATE, FAULT | DB0 | M26, F; controlled reopen | —; synthetic only | Selected provider/configuration and catalog inventory | U |
| KEY-001 | Normal key access; deny/cancel authorization | 07 | 06 | 05 | 08,09 | 4 | EXP-04 | AUTH, TRACE | AMK | M26, I, A, K, F | — | Native Keychain/access-control configuration | U |
| KEY-002 | Independent material verification/cross-Mac recovery | 07,14 | 06,12 | 05,12 | 08,14,19 | 4 | EXP-04 | AUTH, HASH | X0 | M26, I, A, K, F, 2M, O | 03* | Recovery format and encrypted profile fixture | U |
| LOCK-001 | Approved triggers enforce key/view access barrier | 08,22 | 07,08,14,15 | 05,06,07,08 | 09,10,18 | 1,4,5 | EXP-05 | AUTH, TRACE, STATE | L0 | M26, I, A, K, F, P/N; MS only session switch | 04* | Public OS signals and actual barrier contract | U |
| XFER-001 | Download bytes, resume and staging finalization | 12,13 | 11 | 07,11 | 06,13,18 | 1,4 | EXP-06 | AUTH, HASH, STATE | I0/R0 | M26, I, A, C, F; P/N; X for declared restart | 02 | Native transfer/resume and cleanup contract | U |
| BACKUP-001 | Coherent catalog/profile cross-Mac archive restore | 06,14,19 | 12,15 | 03,05,12 | 05,08,14,19 | 4 | EXP-07 | CFG, HASH, STATE | X0 | M26, I, A, F, K, 2M, O | 01/02/03* | Snapshot/key/archive formats and recovery proof | U |
| BACKUP-002 | Selected external files and safe restore conflicts | 16 | 11,12 | 11,12 | 13,14,20 | 4 | EXP-07 | AUTH, HASH, STATE | X0 | M26, I, A, F, 2M, O | 03* | Selection manifest and authorized destination mapping | U |
| BACKUP-003 | Declared WebKit backup/restore/migration coverage | 22 | 08 | 08 | 06,10,14 | 1,4 | EXP-07 | CFG, HASH, STATE | X0/I0 | M26, I, C/O by phase, P; 2M for cross-Mac claim | — | Class-specific public support; qualified archive substrate | U |
| DELETE-001 | Known deletion and unknown-coverage reconciliation | 11,15,19 | 10,13,15 | 06,10,12,13 | 12,14,17 | 4 | EXP-08 | TRACE, STATE, FAULT | I0/R0 | M26, I, F; X for interruption | 01/02/03/04* | Protected ledger, lineage and confirmation contract | U |
| **REQ-21 / existing Stage C reference** | **Final candidate release qualification—not a new case, EXP or SVC** | **21** | **— separate Stage C; no AC01–AC15 assignment** | **— existing release requirements; numbered mapping not invented** | **U—no specific OD-R row assigned; existing release authority governs** | **1,2** | **Existing Stage C gates** | **CFG, AUTH, HASH, FAULT, UI, RESULT, REVIEW** | **I0/DB0 where applicable; final candidate environment U** | **M26 matrix; supported architectures; clean install; controlled update network; actual signed/notarized candidate** | **OP gates affecting release must be resolved; no defaults selected** | **Qualified candidate, release procedures and complete release-case inventory** | **PN—gate; detailed inventory U** |

## REQ-21: retained Stage C qualification reference

REQ-21 is now explicitly routed to **final candidate qualification**. Its lack of an AC01–AC15 assignment is intentional under this refinement, not repaired by inventing AC16 or assigning AC15.

The existing release route includes:

| Existing release obligation | Required evidence categories |
|---|---|
| macOS 26.0/latest supported 26.x and supported architecture behavior | CFG, execution results, UI and reviewer qualification |
| Developer ID signatures and nested code | Signature/identity/configuration records; no private signing material |
| Apple notarization and Gatekeeper clean-open/install | AUTH, UI, RESULT |
| App Sandbox, Hardened Runtime and minimal entitlements | CFG, actual behavior and rejection/failure evidence |
| Candidate compatibility, reliability and approved performance qualification | Candidate-pinned results and limitations |
| Installer/updater metadata and artifact integrity | HASH, rejection/fault results |
| Replay/expiry/channel/minimum-version/revocation/rollback controls | CFG, FAULT, RESULT |
| Dependency/provenance/license and operational security review | CFG, REVIEW |
| Separate internal-release decision | Authorized reviewer/owner disposition |

This reference creates no execution permission. Final case inventory, actual candidate and environment selection remain unspecified.

## SVC-05 / RECOVERY-009 clarification

The existing case is retained with these explicit OD-R20 conditions:

- Profile deletion must not silently delete externally stored user download files.
- Browser-owned metadata deletion is distinct from deletion of the external file.
- Restore conflicts must not silently overwrite existing external files.
- Any affirmative file deletion requires an explicitly authorized, defined operation.

An affirmative external-file-deletion subcase remains **Unspecified — requires specification** until that operation has a contract. This does not invent a file-delete command or authorize one.

## Consistency and preservation summary

### Coverage

All **REQ-01–REQ-22** appear in the matrix. REQ-21 remains separately routed to Stage C.

Every existing AC has an explicitly grounded proposed route:

| AC | Example grounded route |
|---|---|
| AC01 | OFFLINE-001–008 |
| AC02 | PKG-001/002/004 |
| AC03 | ISO-001, PKG-007 |
| AC04 | PRIV-001, PERM-015, OFFLINE-008 |
| AC05 | CRYPTO-001 |
| AC06 | KEY-001/002 |
| AC07 | LOCK-001, RECOVERY-006 |
| AC08 | ISO-001, PRIV-001, LOCK-001, BACKUP-003 |
| AC09 | PERM variants and PERM-013–019 |
| AC10 | OFFLINE-005, DELETE-001 |
| AC11 | XFER-001, PERM-021, RECOVERY-005/009 |
| AC12 | BACKUP-001/002, KEY-002, RECOVERY-008 |
| AC13 | DELETE-001, RECOVERY-008 |
| AC14 | BRIDGE-004/007, PERM-015/016 |
| AC15 | PKG-005–007, BRIDGE-005/008, recovery cases |

These are routes, not passed acceptance criteria.

### Changes made

- Expanded the matrix to individual supporting cases and all 110 permission variants.
- Preserved `unknown` as denial-only, with no affirmative grant case.
- Kept unmapped native positive permission paths blocked.
- Added the explicit Stage C reference for REQ-21.
- Added the four OD-R20 clarifications to RECOVERY-009.

### Preserved

The five SVC charters otherwise remain intact. EXP-01–EXP-08 objectives and scopes, OP-01–OP-04, OD-R01–OD-R20, WS01.1, historical crosswalk meanings, F01–F17 mappings, ADR statuses and conditional WKWebView strategy remain unchanged.

### Remaining gaps

Concrete schemas, per-kind mappings, grant/reset semantics, platform configurations, executable fixtures, evidence parameters and final release-case details remain unresolved where marked.

The matrix is consolidated; **validation readiness and implementation readiness are not established**.

No repository access, Git operation, file modification, test/fixture creation, build, benchmark, experiment or validation-evidence generation occurred during this refinement.

**M1 Developer Specification v1.0 — Proposed. M1 Validation Plan v1.0 — Proposed. M1 Supporting Validation Charters and Case-Level Traceability v1.0 — Proposed. Owner dispositions are discussion-only. All experiments and supporting validation activities remain Not Run. Implementation remains Not Started. Repository changes are Not Authorized. Implementation authorization is Not Granted. No builds, tests, experiments, commits, pushes or release activities are authorized.**