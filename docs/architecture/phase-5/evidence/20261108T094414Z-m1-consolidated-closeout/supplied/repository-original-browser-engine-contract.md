# Vezham Browser Engine Contract

**Status:** Proposed detailed API contract under the approved engine-independent architecture; WKWebView direction conditionally accepted for planning/implementation. ADR 0001 remains Proposed. Current execution scope is M0 host foundation, not the full adapter.  
**Target language:** Engine-independent TypeScript browser-core API behind a Swift/AppKit native host adapter. React/TypeScript browser chrome uses a separate typed, allowlisted bridge.  
**Scope:** Normalize common navigation/page-view behavior without pretending WebKit and Chromium have identical capabilities. Platform baseline is macOS 26 Tahoe and later. `@vezham/aura` is not ready and is excluded. WKWebView has conditional owner acceptance as the MVP adapter direction; CEF remains evaluation-only and is not an active implementation.

## Design rules

1. A browser engine adapter is a privileged native boundary. The React UI sends typed commands; it never receives engine pointers, profile paths, arbitrary file paths, or engine-private objects.
2. Page JavaScript and native browser UI are separate trust domains. No general-purpose page-to-native bridge is part of this contract.
3. Engine lifecycle, view lifecycle, profile/data lifecycle, browser history, and cloud sync are separate services. Engine objects do not own all durable browser state.
4. Every capability has `supported`, `partial`, or `unsupported` status with a note. A method can return `unsupported`; it must never silently claim stronger semantics.
5. Events are scoped by `viewId` and include a monotonically increasing sequence per view. Consumers must ignore events for disposed views and tolerate process crashes/recreation.
6. The browser chrome is a trusted, app-owned React surface. It is hosted and authorized by Swift/AppKit; it must never share a document or privileged message handler with remote website content.
7. The browser core owns product policy and durable app data; the engine adapter only translates that policy into WebKit/CEF operations. Remote sites are untrusted content rendered by the adapter.
8. Tamizhi receives page-derived data only through a separately authorized, user-initiated content-access flow. Vezham ID/cloud services are optional services outside the rendering engine and are not prerequisites for local browsing.
9. The React-to-native transport exposes only versioned, typed, allowlisted commands and events. It has no generic method invocation, object reflection, raw engine object, arbitrary file path, or page-originated dispatch.

## Trust boundaries and command transport

```text
React + TypeScript browser chrome (trusted app UI)
        │ typed allowlisted command/event protocol
Swift + AppKit host (authorization, OS panels, lifecycle)
        │ browser-core policy calls
Engine-independent browser core (profiles, permissions, history, downloads policy)
        │ adapter-private calls
WKWebView adapter (proposed) ── future CEF adapter
        │ isolated engine content process(es)
Remote websites (untrusted)

Tamizhi intelligence ← explicit, minimized page-content grant
Optional Vezham ID/cloud ← opt-in account/sync services; not required to browse
```

The browser chrome must be served from an app-owned origin/surface that cannot navigate to remote content. Remote website views receive no app message handler. The host validates command schema, protocol version, caller surface, request size, profile/view ownership, and current authorization before performing an operation. Responses/events are similarly typed and scoped. UI-origin XSS is a privileged compromise, so the UI surface needs a restrictive CSP, dependency controls, and navigation allowlisting.

The engine-independent TypeScript APIs below describe the browser core/adapter boundary, not a direct React IPC API. A separate command dispatcher maps a small allowlist (for example, navigate, stop, set zoom, respond to a permission prompt, choose/cancel download, and start/advance find) to core methods. Cookie values, website-data paths, native URLs, JavaScript source, profile filesystem paths, and engine objects are not exposed through that UI command protocol.

Illustrative boundary shape (Swift remains authoritative and revalidates every field):

```ts
export type ChromeCommand =
  | { protocol: 1; requestId: string; type: 'navigate'; viewId: ViewId; url: string }
  | { protocol: 1; requestId: string; type: 'go-back'; viewId: ViewId }
  | { protocol: 1; requestId: string; type: 'set-zoom'; viewId: ViewId; factor: number }
  | { protocol: 1; requestId: string; type: 'find'; viewId: ViewId; query: string }
  | {
      protocol: 1;
      requestId: string;
      type: 'permission-response';
      permissionRequestId: PermissionRequestId;
      decision: PermissionDecision;
    }
  | { protocol: 1; requestId: string; type: 'download-cancel'; downloadId: DownloadId };

export type ChromeEvent =
  | {
      protocol: 1;
      type: 'navigation';
      viewId: ViewId;
      navigationId: NavigationId;
      state: 'started' | 'committed' | 'finished' | 'failed';
      url?: string;
    }
  | { protocol: 1; type: 'permission-prompt'; request: PermissionRequest }
  | { protocol: 1; type: 'download'; download: BrowserDownload }
  | { protocol: 1; type: 'view-crashed'; viewId: ViewId; recoverable: boolean };
```

This illustrates a bounded allowlist, not a complete approved product API. It intentionally has no arbitrary script evaluation, cookie inspection, filesystem access, or cloud/account command. Add operations only with a documented need, authorization rule, and security test.

## Core types

```ts
export type EngineId = string;
export type ViewId = string;
export type ProfileId = string;
export type NavigationId = string;
export type PermissionRequestId = string;
export type DownloadId = string;
export type MenuRequestId = string;

export type Support = 'supported' | 'partial' | 'unsupported';

export interface Capability<TDetail = string> {
  support: Support;
  /** Human-readable limitation. Required for partial/unsupported. */
  note?: TDetail;
}

export interface EngineCapabilities {
  engineName: string;
  engineVersion: string;
  platform: 'macos' | string;
  viewEmbedding: Capability<'native-child-view' | 'offscreen' | string>;
  persistentProfiles: Capability;
  privateProfiles: Capability;
  cookieReadWrite: Capability;
  websiteDataClear: Capability;
  navigationPolicy: Capability;
  downloadManagement: Capability;
  uploadPanel: Capability;
  permissionKinds: Partial<Record<PermissionKind, Capability>>;
  findInPage: Capability;
  pageZoom: Capability;
  sessionHistory: Capability;
  durableHistory: Capability;
  contextMenu: Capability;
  processCrashEvents: Capability;
  pageJavaScript: Capability;
  isolatedJavaScriptWorld: Capability;
  extensionRuntime: Capability;
  extensionApiCoverage?: string[];
  processModel: Capability<
    'engine-managed-multiprocess' | 'system-managed-content-process' | 'unknown' | string
  >;
  /** Does not assert a sandbox guarantee. Use details and release evidence for that. */
  sandboxConfiguration: Capability;
}

export interface EngineInitOptions {
  appVersion: string;
  userDataRoot: string; // Native host validates and owns; never expose to page/UI JS.
  locale: string;
  enableRemoteDebugging?: false; // Default is disabled. A development-only build may opt in explicitly.
}

export interface ViewCreateOptions {
  profileId: ProfileId;
  initialUrl?: string;
  /** Opaque host-owned native surface identifier; never an OS pointer from TypeScript. */
  hostSurfaceId: string;
  backgroundColor?: string;
}

export interface ViewBounds {
  x: number;
  y: number;
  width: number;
  height: number;
  scaleFactor: number;
}

export type PermissionKind =
  | 'camera'
  | 'microphone'
  | 'camera-and-microphone'
  | 'geolocation'
  | 'notifications'
  | 'clipboard-read'
  | 'clipboard-write'
  | 'bluetooth'
  | 'usb'
  | 'midi'
  | 'screen-capture'
  | 'unknown';

export interface PermissionRequest {
  requestId: PermissionRequestId;
  profileId: ProfileId;
  viewId: ViewId;
  requestingOrigin: string;
  topLevelOrigin?: string;
  frameOrigin?: string;
  kind: PermissionKind;
  requestedAt: number;
  userGesture: 'yes' | 'no' | 'unknown';
}

export type PermissionDecision = 'allow-once' | 'allow-for-profile' | 'deny';

export interface BrowserDownload {
  downloadId: DownloadId;
  viewId: ViewId;
  profileId: ProfileId;
  sourceOrigin: string;
  suggestedName: string;
  mimeType?: string;
  receivedBytes: number;
  totalBytes?: number;
  state: 'needs-destination' | 'in-progress' | 'paused' | 'completed' | 'failed' | 'cancelled';
  errorCode?: string;
}

export type WebsiteDataKind =
  | 'cookies'
  | 'local-storage'
  | 'indexed-db'
  | 'cache'
  | 'service-workers'
  | 'media-keys'
  | 'http-auth'
  | 'other';

export interface WebsiteDataRecord {
  origin: string;
  kinds: WebsiteDataKind[];
  modifiedAt?: number;
}

export interface BrowserHistoryEntry {
  id: string;
  profileId: ProfileId;
  url: string;
  title?: string;
  visitedAt: number;
  transition?: 'typed' | 'link' | 'reload' | 'redirect' | 'other';
}

export interface ContextMenuRequest {
  requestId: MenuRequestId;
  viewId: ViewId;
  profileId: ProfileId;
  pageOrigin: string;
  linkUrl?: string;
  imageUrl?: string;
  editable: boolean;
  /** Return selected text only when the user opens a menu that needs selection actions. */
  selectedText?: string;
  availableActions: Array<
    | 'back'
    | 'forward'
    | 'reload'
    | 'copy'
    | 'paste'
    | 'select-all'
    | 'inspect'
    | 'open-link'
    | 'save-image'
    | 'custom'
  >;
}

export type EngineEvent =
  | {
      type: 'navigation-started';
      viewId: ViewId;
      navigationId: NavigationId;
      url: string;
      mainFrame: boolean;
      sequence: number;
    }
  | {
      type: 'navigation-redirected';
      viewId: ViewId;
      navigationId: NavigationId;
      url: string;
      sequence: number;
    }
  | {
      type: 'navigation-committed';
      viewId: ViewId;
      navigationId: NavigationId;
      url: string;
      sequence: number;
    }
  | {
      type: 'page-progress';
      viewId: ViewId;
      navigationId: NavigationId;
      fraction?: number;
      stage?: 'dom-content-loaded' | 'load';
      sequence: number;
    }
  | {
      type: 'navigation-finished';
      viewId: ViewId;
      navigationId: NavigationId;
      url: string;
      title?: string;
      sequence: number;
    }
  | {
      type: 'navigation-failed';
      viewId: ViewId;
      navigationId: NavigationId;
      url: string;
      code: string;
      provisional: boolean;
      sequence: number;
    }
  | { type: 'permission-requested'; request: PermissionRequest; sequence: number }
  | { type: 'download-changed'; download: BrowserDownload; sequence: number }
  | { type: 'context-menu-requested'; request: ContextMenuRequest; sequence: number }
  | { type: 'title-changed'; viewId: ViewId; title?: string; sequence: number }
  | { type: 'url-changed'; viewId: ViewId; url?: string; sequence: number }
  | {
      type: 'crashed';
      viewId: ViewId;
      process: 'web-content' | 'renderer' | 'gpu' | 'browser' | 'unknown';
      reason?: string;
      recoverable: boolean;
      sequence: number;
    }
  | { type: 'recovered'; viewId: ViewId; previousNavigationId?: NavigationId; sequence: number };

export type EngineResult<T> =
  | {
      ok: true;
      value: T;
    }
  | {
      ok: false;
      error: { code: string; message: string; retryable: boolean };
    };

export interface EngineSubscription {
  unsubscribe(): void;
}
```

## Proposed adapter surface

```ts
export interface BrowserEngine {
  readonly id: EngineId;
  readonly capabilities: EngineCapabilities;

  initialize(options: EngineInitOptions): Promise<void>;
  shutdown(): Promise<void>;
  subscribe(listener: (event: EngineEvent) => void): EngineSubscription;

  profiles: ProfileStore;
  views: BrowserViews;
  permissions: PermissionController;
  downloads: DownloadController;
  find: FindController;
  cookies: CookieController;
  websiteData: WebsiteDataController;
  sessionHistory: SessionHistoryController;
  contextMenus: ContextMenuController;
  pageScripts: PageScriptController;
}

export interface ProfileStore {
  /** Private mode gets a unique ephemeral store. parentProfileId links policy/UI only; it never reuses the parent store. */
  create(input: {
    id: ProfileId;
    name: string;
    mode: 'persistent' | 'private';
    parentProfileId?: ProfileId;
  }): Promise<void>;
  list(): Promise<Array<{ id: ProfileId; name: string; mode: 'persistent' | 'private' }>>;
  /** Must fail if a view/download still owns the profile. No implicit forced deletion. */
  delete(profileId: ProfileId): Promise<void>;
}

export interface BrowserViews {
  create(options: ViewCreateOptions): Promise<ViewId>;
  setBounds(viewId: ViewId, bounds: ViewBounds): Promise<void>;
  navigate(
    viewId: ViewId,
    url: string,
    cause?: 'user' | 'browser-ui' | 'restore',
  ): Promise<NavigationId>;
  goBack(viewId: ViewId): Promise<boolean>;
  goForward(viewId: ViewId): Promise<boolean>;
  reload(viewId: ViewId, mode?: 'normal' | 'from-origin'): Promise<void>;
  stop(viewId: ViewId): Promise<void>;
  setZoom(viewId: ViewId, factor: number): Promise<void>; // 1.0 is the engine default.
  getZoom(viewId: ViewId): Promise<number>;
  recover(
    viewId: ViewId,
    strategy: 'reload-current' | 'restore-last-committed' | 'show-error',
  ): Promise<void>;
  dispose(viewId: ViewId): Promise<void>;
}

export interface PermissionController {
  respond(requestId: PermissionRequestId, decision: PermissionDecision): Promise<void>;
  get(
    profileId: ProfileId,
    origin: string,
    kind: PermissionKind,
  ): Promise<PermissionDecision | 'ask'>;
  revoke(profileId: ProfileId, origin: string, kind?: PermissionKind): Promise<void>;
}

export interface DownloadController {
  chooseDestination(downloadId: DownloadId, destinationToken: string): Promise<void>;
  cancel(downloadId: DownloadId): Promise<void>;
  pause?(downloadId: DownloadId): Promise<void>;
  resume?(downloadId: DownloadId): Promise<void>;
}

export interface FindController {
  start(
    viewId: ViewId,
    query: string,
    options?: { caseSensitive?: boolean; backwards?: boolean; wrap?: boolean },
  ): Promise<FindResult>;
  next(viewId: ViewId, direction: 'forward' | 'backward'): Promise<FindResult>;
  stop(viewId: ViewId, clearSelection?: boolean): Promise<void>;
}

export interface FindResult {
  activeMatchFound: boolean;
  /** Optional because the engines expose different result details. */
  matchCount?: number;
  activeMatchOrdinal?: number;
}

export interface CookieRecord {
  name: string;
  value: string;
  domain: string;
  path: string;
  expiresAt?: number;
  secure: boolean;
  httpOnly: boolean;
  sameSite?: 'strict' | 'lax' | 'none' | 'unspecified';
}

export interface CookieController {
  list(profileId: ProfileId, origin?: string): Promise<CookieRecord[]>;
  set(profileId: ProfileId, origin: string, cookie: CookieRecord): Promise<void>;
  delete(profileId: ProfileId, origin: string, name?: string): Promise<void>;
}

export interface WebsiteDataController {
  list(profileId: ProfileId, kinds?: WebsiteDataKind[]): Promise<WebsiteDataRecord[]>;
  clear(
    profileId: ProfileId,
    input: { origins?: string[]; kinds?: WebsiteDataKind[]; modifiedSince?: number },
  ): Promise<void>;
}

export interface SessionHistoryController {
  /** Current view's engine back/forward list; it is not durable global history. */
  listNavigationEntries(
    viewId: ViewId,
  ): Promise<Array<{ url: string; title?: string; current: boolean }>>;
  /** Durable Vezham history belongs to app storage, not the rendering engine. */
  recordCommittedNavigation(entry: BrowserHistoryEntry): Promise<void>;
  query(input: {
    profileId: ProfileId;
    text?: string;
    after?: number;
    before?: number;
    limit: number;
  }): Promise<BrowserHistoryEntry[]>;
  delete(entryIds: string[]): Promise<void>;
  clear(profileId: ProfileId): Promise<void>;
}

export interface ContextMenuController {
  respond(
    requestId: MenuRequestId,
    action: ContextMenuRequest['availableActions'][number],
  ): Promise<void>;
}

export interface PageScriptController {
  /** Fixed browser-owned operations only; this is not an arbitrary source evaluator. */
  execute(input: {
    viewId: ViewId;
    operation: 'read-selection' | 'extract-readable-content';
    grantId: string;
  }): Promise<{ text: string; truncated: boolean }>;
}
```

Profile invariants: each persistent profile owns a distinct website data store plus separately keyed Vezham-owned state. Private profiles use non-persistent engine storage, do not write normal history or sync records, and remove app-owned temporary session data when the private session closes. Windows and views have an immutable profile assignment for their lifetime. A private profile’s optional parent ID is descriptive for UI policy only, never a storage-sharing mechanism.

The pseudo-interface above intentionally treats persistent history as app-owned, destinations as opaque native tokens, and page-derived text extraction as a restricted optional capability. It does not expose arbitrary JavaScript evaluation. Implementations may add adapter-private APIs, but the shared product layer must not depend on them without capability checks.

## Event and lifecycle semantics

- `initialize` creates engine services once per application process. `shutdown` rejects new work, closes views, flushes engine-owned data where supported, then exits helpers. It must be idempotent.
- Each view is created with its profile/data store before navigation. Engine configuration that is immutable after view construction belongs in profile creation or `ViewCreateOptions`.
- A new top-level navigation gets a `navigationId`; redirects retain it. Subframe events may be ignored by the app shell unless the feature explicitly needs them.
- Event order is best effort across native callback queues. `sequence` orders events from one view; only the terminal `navigation-finished` or `navigation-failed` closes that navigation.
- Progress is advisory. An engine may report only coarse stages and may not provide an equivalent fraction.
- On a content-process/renderer crash, preserve view/profile metadata outside the engine, block stale events, notify the UI, and recover through an explicit strategy. Never assume renderer memory state survived.
- Every asynchronous callback must be cancellation-safe. Disposal cancels pending prompts/actions or resolves them as cancelled; it must not invoke stale UI callbacks.

## Features that are not fully portable

1. **Process and sandbox topology:** WebKit owns process management; CEF exposes Chromium helpers and sandbox setup. The contract reports capability facts but cannot promise equal process boundaries or threat resistance.
2. **Permissions:** Engines expose different permission categories, prompt defaults, origin/frame data, and OS permission interactions. Product policy is normalized; engine request coverage remains capability-specific.
3. **Extensions:** Safari Web Extensions and CEF/Chrome-runtime extension support are different systems. No portable “install Chrome extension” contract is proposed.
4. **Network interception:** WebKit navigation delegates are not a general equivalent to Chromium request/response handlers. An app-level content-blocking abstraction may be partial and engine-specific.
5. **Profile migration/export:** Cookie attributes, local storage, service workers, caches, HTTP auth, and browser-specific settings do not have a common complete export format. Do not promise engine-to-engine profile migration.
6. **Find results:** Both engines can search page text, but count/ordinal and selection behavior may differ; detailed result fields remain optional.
7. **Context menus and native file panels:** Menus, input panels, drag/drop, accessibility, IME, printing, media capture, and fullscreen hooks need native platform adaptation.
8. **History:** A durable, profile-scoped history database is Vezham-owned. Engine navigation stacks are per-view session data only.
9. **Zoom and page JS:** Rendering scale semantics differ. Page script injection and isolated worlds are not identical; the portable contract only offers page-world execution under an explicit grant.
10. **Engine versions and codecs:** WebKit follows macOS availability; Chromium distributions vary by build flags, codecs, patches, and CEF branch. `engineVersion` and feature declarations must be observable.

## Staged adapter acceptance requirements

The [owner decision](phase-3/owner-approval-decision.md) and [ADR 0001](../decisions/0001-browser-engine-strategy.md) separate Stage A decision evidence, Stage B implementation validation and Stage C final-release qualification. These criteria remain mandatory at their applicable stage; they are not all prerequisites to starting a minimal native host. M0 introduces no production core/adapter/bridge API.

- Before the affected adapter method is implemented, pin its public SDK/engine reference and behavior test plan.
- Profile isolation is tested with cookies, local storage, IndexedDB, service workers, and concurrent views.
- Permission callbacks are mapped per permission kind and default-deny behavior is confirmed.
- Upload, download, crash/recovery, find, zoom, and context-menu semantics are documented for that adapter.
- No app UI or Tamizhi credential can be read through the page-world API.
- Engine capability metadata is populated from the selected build/runtime, not hard-coded marketing assumptions.
- Two persistent profiles show zero cross-profile cookies, sessions, local storage, IndexedDB, or service-worker state; private data uses a non-persistent store and is excluded from normal history and sync.
- The trusted UI command allowlist is tested independently from website content; no page can invoke a host command or read browser UI/account data.
- Performance, compatibility, crash recovery, distribution, and security gates are recorded in [the MVP acceptance criteria](browser-mvp-acceptance-criteria.md).
