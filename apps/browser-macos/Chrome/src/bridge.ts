export type Appearance = 'system' | 'light' | 'dark';
export type Tab = {
  id: string;
  title: string;
  url?: string;
  loading: boolean;
  progress: number;
  back: boolean;
  forward: boolean;
  connection: 'encrypted' | 'unencrypted' | 'unknown';
  failure?: 'load-failed' | 'content-unavailable';
};
export type BrowserState = {
  revision: number;
  session: 'inactive' | 'private';
  sessionID?: string;
  profile: 'unavailable';
  tabs: Tab[];
  selected?: string;
  appearance: Appearance;
};
export type Command =
  | { type: 'snapshot' | 'startPrivate' | 'endPrivate' | 'newTab' }
  | { type: 'activate' | 'close' | 'duplicate' | 'back' | 'forward' | 'reload' | 'stop' | 'copy' | 'paste'; tab: string }
  | { type: 'move'; tab: string; offset: number }
  | { type: 'navigate'; tab: string; url: string }
  | { type: 'appearance'; value: Appearance }
  | { type: 'presentation'; visible: boolean; left: number; top: number };

type Failure = 'busy' | 'unavailable' | 'invalid' | 'failed' | 'disconnected';
export type Result = { id: string; state: BrowserState; error?: Failure; text?: string };

type HostWindow = Window & {
  webkit?: { messageHandlers?: { browserChrome?: { postMessage(value: object): Promise<Result> } } };
};

export const initialState: BrowserState = {
  revision: 0, session: 'inactive', profile: 'unavailable', tabs: [], appearance: 'system',
};

let requestNumber = 0;

export async function dispatch(command: Command): Promise<Result> {
  const id = String(++requestNumber);
  const handler = (window as HostWindow).webkit?.messageHandlers?.browserChrome;
  if (!handler) return { id, error: 'disconnected', state: initialState };
  try {
    const result = await handler.postMessage({ id, version: 1, ...command });
    if (result.id === id) return result;
  } catch {
    // Native failures are surfaced without exposing request content or OS diagnostics.
  }
  return { id, error: 'disconnected', state: initialState };
}
