# Remaining blockers

| Requirement | State | Owner and next action |
| --- | --- | --- |
| SQLCipher admission and protected catalog | Blocked at production policy and integration boundary | Product/security to authorize the exact production read fence and scope. Storage engineering to implement the descriptor broker, native key custody handoff, atomic catalog/recovery adapters, profile lifecycle and durable UI mounting. |
| Positive Keychain lifecycle | Blocked by signing environment | Signing owner to provision an authorized app identity and matching team/profile. Verify user presence, isolated group, create/read/reacquire/revoke, negative and restart controls on disposable data. |
| Twenty production workspace cases | Blocked | Storage and QA owners to qualify the signed production path and execute the individual matrix. |
| WebKit helper exit | Not executed | QA to establish safe per-candidate process attribution on an isolated supported OS. |
| VoiceOver and physical input | Not executed | QA to use the native manual checklist on a physical or isolated supported macOS environment. |
| Signed Release and notarization | Blocked | Release owner to supply Developer ID identity and approved notary Keychain profile. Qualify package installation, signing, privacy behavior and runtime on macOS 26. |
| Legacy DOM-only host suites | Not applicable to active native shell | Browser QA to port remaining relevant DOM interactions to native witnesses. The legacy fixture suite runs independently. |
