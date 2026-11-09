export type Appearance = 'system' | 'light' | 'dark'
export type Tab = {
  id: string
  space: string
  group?: string
  pinned: boolean
  title: string
  url?: string
  loading: boolean
  progress: number
  back: boolean
  forward: boolean
  connection: 'encrypted' | 'unencrypted' | 'unknown'
  favicon?: string
  failure?: 'load-failed' | 'content-unavailable'
}
export type MiniPreview = {
  token: string
  url: string
  workspace: string
  space: string
}
export type BrowserState = {
  revision: number
  session: 'inactive' | 'private'
  sessionID?: string
  recovery?: 'retiring' | 'ready' | 'rebuilding' | 'failed'
  profile: 'unavailable'
  tabs: Tab[]
  selected?: string
  appearance: Appearance
  spaces: { id: string; name: string }[]
  activeSpace: string
  groups: { id: string; space: string; name: string; collapsed: boolean }[]
  split: string[]
  splitCompact: boolean
  mini: boolean
  workspaces?: { id: string; name: string; empty: boolean }[]
  activeWorkspace?: string
  miniEligible?: boolean
}
export type Command =
  | {
      type:
        'snapshot' | 'recoverPrivate' | 'startPrivate' | 'endPrivate' | 'newTab'
    }
  | {
      type:
        | 'activate'
        | 'close'
        | 'duplicate'
        | 'back'
        | 'forward'
        | 'reload'
        | 'stop'
        | 'copy'
        | 'paste'
      tab: string
    }
  | { type: 'move'; tab: string; offset: number }
  | { type: 'navigate'; tab: string; url: string }
  | { type: 'appearance'; value: Appearance }
  | { type: 'spaceCreate' | 'groupCreate' | 'workspaceCreate'; name: string }
  | {
      type: 'spaceRename' | 'groupRename' | 'workspaceRename'
      target: string
      name: string
    }
  | {
      type:
        | 'spaceSwitch'
        | 'spaceDelete'
        | 'groupToggle'
        | 'groupDelete'
        | 'workspaceSwitch'
        | 'workspaceDelete'
      target: string
    }
  | { type: 'groupMove' | 'workspaceMove'; target: string; offset: number }
  | { type: 'pin' | 'split'; tab: string }
  | { type: 'tabSpace'; tab: string; target: string }
  | { type: 'tabGroup'; tab: string; target?: string }
  | { type: 'unsplit' | 'miniTransferPreview' }
  | { type: 'miniTransfer'; target: string }
  | { type: 'miniOpen'; tab?: string; url?: string }
  | { type: 'presentation'; visible: boolean; left: number; top: number }

type Failure =
  | 'busy'
  | 'unavailable'
  | 'invalid'
  | 'failed'
  | 'transferUnconfirmed'
  | 'disconnected'
export type Result = {
  id: string
  state: BrowserState
  error?: Failure
  text?: string
  miniPreview?: MiniPreview
}

type HostWindow = Window & {
  webkit?: {
    messageHandlers?: {
      browserChrome?: { postMessage(value: object): Promise<Result> }
    }
  }
}

export const initialState: BrowserState = {
  revision: 0,
  session: 'inactive',
  profile: 'unavailable',
  tabs: [],
  appearance: 'system',
  spaces: [],
  groups: [],
  activeSpace: '',
  split: [],
  splitCompact: false,
  mini: false
}

let requestNumber = 0

export async function dispatch(command: Command): Promise<Result> {
  const id = String(++requestNumber)
  const handler = (window as HostWindow).webkit?.messageHandlers?.browserChrome
  if (!handler) return { id, error: 'disconnected', state: initialState }
  try {
    const result = await handler.postMessage({ id, version: 1, ...command })
    if (result.id === id) return result
  } catch {
    // Native failures are surfaced without exposing request content or OS diagnostics.
  }
  return { id, error: 'disconnected', state: initialState }
}
