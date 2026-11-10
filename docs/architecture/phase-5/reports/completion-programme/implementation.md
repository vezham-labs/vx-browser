# Implementation and integration

The checkout started clean on cross-browser-research at 6c19e9c. The programme inspected the local timeline branch through Git and records new progress on the working branch.

| Surface | Implementation |
| --- | --- |
| Toolbar and address | SwiftUI controls, native focus and bounded local address input. Ordinary navigation preserves query and fragment components. |
| Sidebar, tabs and Spaces | Native list, selection, context menus, drag/drop, workspace and Space menus and sheets. Existing Swift command handlers own mutation and order. |
| Command bar | Native sheet for tab search, address entry and browser actions. |
| Split | Existing AppKit split and divider. Native pane controls expose selection and unsplit. |
| Mini | Separate native window and private store. A native confirmation sheet displays the eligible URL and destination. |
| Settings and bookmarks | Native appearance controls and temporary bookmark editing, filtering, removal and ordering. |
| Blank and recovery states | Native text and recovery actions reflect the existing retirement fence. |
| Website context actions | WebKit and the native delegate retain page policies. |

The native UI check on isolated build 02 observed accessibility labels, keyboard submission of a loopback URL with query and fragment, link activation, Back, Command-T, two independently presented website tabs, Split Screen via context menu, the workspace name sheet, and a Mini handoff that committed in Main and closed Mini. Build 01 exposed address focus loss caused by polling. The fix moves the responder only when website content owns it or the window is closing. The final candidate adds sidebar visibility, keyboard list focus and temporary bookmark management. Their detailed interaction matrix remains unexecuted. DOM-based historical host suites need native UI witnesses. The legacy Playwright suite is still executable.

## Protected storage

ProtectedCatalog still rejects production catalog and journal operations. Main and Mini browse in private WebKit scopes. The existing provider qualification approval permits exactly one 100-byte encrypted-header read before key application in the pinned qualification path. Production needs admission through the existing authority with signed Keychain custody and explicit production applicability of the bounded exception. There are zero valid code-signing identities on this Mac.

The tagged Go suite compiles ProtectedStoreWorker against the retained SHA256-pinned SQLCipher 4.20.0 Community/CommonCrypto inputs. It authenticates the existing read-only descriptor, profile/store and schema before copying to an encrypted RAM VFS. Revision compare-and-swap, a cooperative writer lock, synced staging and atomic rename publish the ciphertext. An explicit prior ciphertext copy is retained. The worker refuses unknown schema, wrong keys, foreign scope and ambiguous sidecars. It demonstrates reconciliation by reopen after an uncertain reply. The worker is excluded from the Xcode graph and requires the qualification build define.

Production normal-profile provisioning, the descriptor broker, Keychain leases, the catalog/recovery adapters and application mounting remain unimplemented. A future signed restore must decode the versioned logical graph before mounting it and leave website views dormant until explicit eligible navigation. Private and Mini graphs stay volatile. Missing or revoked keys fence access. Corruption preserves current and prior sources. Unknown versions refuse mutation. Profile reset/delete and durable migration need production qualification.
