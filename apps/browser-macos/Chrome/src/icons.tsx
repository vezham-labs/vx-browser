import type { ReactNode } from 'react';

const marks: Record<string, ReactNode> = {
  split: <><rect x="3" y="4" width="18" height="16" rx="3"/><path d="M12 4v16"/></>,
  pin: <path d="m8 3 8 0-1 6 3 4H6l3-4zm4 10v8"/>,
  logo: <><path d="M3 5h6l3 10 3-10h6L14 20h-4z"/><path d="M5 10h4m6 0h4"/></>,
  back: <><path d="m14 6-6 6 6 6"/><path d="M8 12h11"/></>,
  forward: <><path d="m10 6 6 6-6 6"/><path d="M5 12h11"/></>,
  reload: <><path d="M20 11a8 8 0 1 0-2 6"/><path d="M20 5v6h-6"/></>,
  stop: <rect x="7" y="7" width="10" height="10" rx="2"/>,
  sidebar: <><rect x="3" y="5" width="18" height="14" rx="3"/><path d="M9 5v14"/></>,
  tabs: <><rect x="6" y="5" width="14" height="12" rx="2"/><path d="M4 9H3v11h13v-1"/></>,
  bookmarks: <path d="M6 5h12v15l-6-4-6 4z"/>,
  history: <><path d="M4 11a8 8 0 1 1 2 7M4 5v6h6"/><path d="M12 8v5l3 2"/></>,
  downloads: <><path d="M12 3v12m-4-4 4 4 4-4M5 16v4h14v-4"/></>,
  profiles: <><circle cx="12" cy="8" r="3"/><path d="M5 20v-2c0-5 14-5 14 0v2"/></>,
  settings: <><circle cx="12" cy="12" r="3"/><path d="m10 3-1 3-3 1-3 3 2 2-1 4 4 1 2 4 4-1 1-3 4-1 1-4-3-2V6l-4-1z"/></>,
  search: <><circle cx="10" cy="10" r="5"/><path d="m14 14 5 5"/></>,
  plus: <path d="M5 12h14M12 5v14"/>,
  close: <path d="m6 6 12 12M18 6 6 18"/>,
  menu: <><circle cx="5" cy="12" r="1"/><circle cx="12" cy="12" r="1"/><circle cx="19" cy="12" r="1"/></>,
  shield: <><path d="M12 3 5 6v5c0 5 3 8 7 10 4-2 7-5 7-10V6z"/><path d="m9 12 2 2 4-4"/></>,
  lock: <><rect x="6" y="11" width="12" height="9" rx="2"/><path d="M9 11V8a3 3 0 0 1 6 0v3"/></>,
  info: <><circle cx="12" cy="12" r="8"/><path d="M12 11v5m0-8h.01"/></>,
  up: <path d="m7 14 5-5 5 5"/>,
  down: <path d="m7 10 5 5 5-5"/>,
  globe: <><circle cx="12" cy="12" r="8"/><ellipse cx="12" cy="12" rx="4" ry="8"/><path d="M4 12h16"/></>,
  arrow: <path d="M5 12h14m-6-6 6 6-6 6"/>,
  command: <path d="M8 8H6a2 2 0 1 1 2-2v12a2 2 0 1 1-2-2h12a2 2 0 1 1-2 2V6a2 2 0 1 1 2 2z"/>,
  folder: <path d="M3 7h7l2 2h9v10H3z"/>,
};
export function Icon({ name, size = 18 }: { name: string; size?: number }) {
  return <svg aria-hidden="true" width={size} height={size} viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.65" strokeLinecap="round" strokeLinejoin="round">{marks[name]}</svg>;
}
