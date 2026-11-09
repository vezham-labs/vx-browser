# WS-F2 WebKit runtime hardening

2026-11-09. WS-F2 implementation/qualification review. [Closeout](m1-wsf2-closeout.md) · [Actual results](m1-wsf2-qualification-results.md) · [Evidence](../../evidence/20261109T105707Z-webkit-storage-wsf2/README.md). **No release approval.**

## Implemented integration

The existing NativeWebKitStorage is extended rather than replaced. Its explicit store/configuration/view ownership, noncreating identifier observation, default-store prohibition, construction-before-publication ordering, generation checks, separate clear/remove callbacks and15-second observed private-retirement budget remain. Earlier2-second private failures and all WS-F1 evidence stay unchanged. No private API, filesystem manipulation of engine data, SQLCipher wrapping or default-store warmup is added.

The security fence is independent of ordinary lifecycle acquisition fences. Core's allow-acquisition request cannot clear a security lock or content-process poison fence. Lock cancels owned navigation continuations, stops loading, retires views/configurations through Core, and observes resources before returning Locked. The host rechecks authority/native publication after its awaited journal finalization. Navigation request issuance is an additional coarse structured trace event; no URL/content is logged.

## HTTP cache investigation

The new controlled origin uses a unique `/cache-probe/UUID`, fresh per-test server counters, explicit `Cache-Control: public, max-age=86400, immutable`, ETag and actual server request observations. The page awaits two `force-cache` fetches and returns only registered public synthetic response markers. A and B use the same origin/path, distinct store mappings and distinct response markers. Within a live profile the second fetch reuses the response without another server request. Actual process exit/relaunch and abrupt termination/relaunch cause new network retrieval in the recorded fixture. No conditional ETag request was observed in those runs. This establishes bounded response/network behavior, not WebKit disk contents or a universal persistence guarantee.

Selected HTTP-cache and full selected-category clearing now have in-process positive population before clearing, callback/record verification and a new page-visible response afterward. Reconstructing a view after that clear is distinct from app restart. Normal store removal records callback and noncreating absence; no creating check reopens removed identifiers. Exact per-process marker and server observations are in the current `f2-webkit-native-*` evidence and cache-analysis record. WS-F1's original HTTP-cache INCONCLUSIVE results remain historical; disk persistence remains INCONCLUSIVE where public observability is insufficient.

## Expanded lifecycle and limitations

Qualification includes same-profile two-view/two-window composition, a separate simultaneously open profile, manual lock, other-profile survival, navigation outstanding during lock, repeated lock convergence, actual lock-fence child termination and conservative fresh-process locking. Resources may initially need RecoveryRequired while an awaited navigation's local references drain; a later lock may reach Locked only after empty-resource/no-key observations. This is not a false earlier Locked result or an assertion that all WebKit internal processes stopped.

The original full WS-F1 suite is also executed against WS-F2 implementation inputs. It retains persistent/private/isolation/switch/selected clear/normal remove and11 lifecycle cutpoints plus private termination. No different-revision pass aggregation. In-use/error/timeout tests not actually forced at the native API remain unqualified; fake errors are supporting policy evidence only. Selected domain-record/modified-since semantics, issued-before-callback timing, independently attributed engine-process faults and complete native lock/key barriers remain open.
