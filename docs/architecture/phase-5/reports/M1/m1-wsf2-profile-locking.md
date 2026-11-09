# WS-F2 profile locking

2026-11-09. WS-F2 implementation/qualification review. [Closeout](m1-wsf2-closeout.md) · [Actual results](m1-wsf2-qualification-results.md) · [Evidence](../../evidence/20261109T105707Z-webkit-storage-wsf2/README.md). **No release approval.**

## Policy and native enforcement

`BrowserCore/ProfileSecurityCoordinator.swift` implements Unlocked → LockRequested → Quiescing → Locked, and UnlockRequested → Unlocking → Unlocked or RecoveryRequired. Unknown profiles fail closed. Initial locked registration performs retirement checks; it cannot set Locked merely from a UI flag. Monotonic epochs reject stale async work, including an unlock reply arriving after a newer lock. Duplicate in-progress locks do not start parallel retirement. A later explicit lock may safely converge from RecoveryRequired after outstanding references drain; exact terminal-state equality is not required in that situation.

Lock installs the native security fence first, invalidates permission grants/prompts, revokes key leases, closes owned Core views, quiesces and retires the native store. Locked requires completed owned-resource retirement and no active key lease. Retained external/configuration/pending references produce RecoveryRequired. Core's ordinary acquisition API cannot remove this fence. Other profiles retain separate authority and native resources.

`NativeProfileBarrier` integrates existing Core/view/resource ports, not a second lifecycle coordinator. `NativeProfileAuthentication` implements real OS authentication for explicit unlock. Even successful OS authentication cannot unlock without authenticated key/catalog reconciliation; the D2A-01 gate returns RecoveryRequired rather than admitting an unprotected profile. Unlock performs no automatic navigation/form/POST replay.

## Native observations and limits

Qualification exercises two views/windows, a simultaneous independent profile, lock during outstanding controlled navigation, repeated requests, blocked old-view navigation, key-lease absence, other-profile survival and actual lock-fence process death/relaunch. These use synthetic catalogs; no real loaded profile key existed because Keychain creation was blocked. No-key-cache observation is therefore not qualification of revoking a successfully acquired protected key.

Navigation can leave a locally retained async object briefly alive. The first lock may truthfully return RecoveryRequired; a later retry may reach Locked only when resource/key observations pass. The earlier too-strict equality assertion and its failure remain preserved. Actual restart uses a recorded synthetic checkpoint and conservative initial locking with no creating factory. It is not a durable protected lock receipt or complete crash-safe lock/unlock transaction.

## OS lifecycle and outstanding requirements

`NativeSecurityLifecycle` observes public sleep/session-resign signals, local activity and a configurable inactivity timer (default900seconds, minimum30). App termination awaits Core lockAll before replying to AppKit. No global input monitor, undocumented screen-lock notification or private API is used. Actual macOS lock-screen trigger coverage, sleep/session-switch integration, inactivity timing and signed restart behavior remain NOT_EXECUTED; the missing screen-lock signal route is an explicit mandatory gap, not a waiver of OD-R18.

Downloads are not implemented; no live transfer is silently ignored or claimed suspended. In-flight clear/remove, key-provider operations and multiwindow hostile interleavings still need complete integrated qualification. WebKit files are not cryptographically revoked by a profile lock, and weak object observations do not prove every internal process stopped. Gate D remains partial/BLOCKED for full native unlock/key/persistence/OS-trigger guarantees.
