import { Button, Input } from '@heroui/react';
import { useCallback, useEffect, useLayoutEffect, useRef, useState } from 'react';
import type { FormEvent, KeyboardEvent, ReactNode } from 'react';
import { dispatch, initialState } from './bridge';
import type { Appearance, Command, Result, Tab } from './bridge';
import { Icon } from './icons';
import { destination, search } from './navigation';

const sections = ['Tabs', 'Bookmarks', 'History', 'Downloads', 'Profiles', 'Settings'] as const;
type Section = typeof sections[number];
type Bookmark = { id: string; name: string; url: string; folder: string };
const settingSections = ['General', 'Appearance', 'Tabs', 'Search', 'Privacy', 'Website permissions', 'Downloads', 'Profiles', 'Keyboard shortcuts', 'Advanced'] as const;
const shortcutList = [['Focus address', '⌘L'], ['New tab', '⌘T'], ['Close tab', '⌘W'], ['Reload', '⌘R'], ['Commands', '⌘K'], ['Settings', '⌘,']];
const errors = {
  busy: 'Another browser action is in progress.',
  unavailable: 'This action is unavailable for the current tab or session.',
  invalid: 'This address or action is unsupported.',
  failed: 'The browser could not complete that action.',
  disconnected: 'The native browser host is unavailable.',
};

function Tool({ icon, label, action, disabled = false }: { icon: string; label: string; action: () => void; disabled?: boolean }) {
  return <Button isIconOnly size="sm" variant="ghost" className="tool" aria-label={label} isDisabled={disabled} onPress={action}><Icon name={icon} /></Button>;
}

function Empty({ icon, title, children }: { icon: string; title: string; children: ReactNode }) {
  return <div className="empty"><span className="tile"><Icon name={icon} size={23}/></span><h2>{title}</h2><p>{children}</p></div>;
}

export function Browser() {
  const [browser, setBrowser] = useState(initialState);
  const [connected, setConnected] = useState(false);
  const [section, setSection] = useState<Section>('Tabs');
  const [settings, setSettings] = useState<typeof settingSections[number]>('Appearance');
  const [sidebar, setSidebar] = useState(true);
  const [sideWidth, setSideWidth] = useState(214);
  const [draft, setDraft] = useState('');
  const [editing, setEditing] = useState(false);
  const [notice, setNotice] = useState('');
  const [palette, setPalette] = useState(false);
  const [query, setQuery] = useState('');
  const [menu, setMenu] = useState<string>();
  const [bookmarks, setBookmarks] = useState<Bookmark[]>([]);
  const [bookmarkQuery, setBookmarkQuery] = useState('');
  const [bookmarkForm, setBookmarkForm] = useState<Bookmark>();
  const address = useRef<HTMLInputElement>(null);
  const commands = useRef<HTMLInputElement>(null);
  const previousFocus = useRef<HTMLElement | null>(null);
  const content = useRef<HTMLElement>(null);
  const dragged = useRef<string>(undefined);
  const active = browser.tabs.find((tab) => tab.id === browser.selected);
  const inPrivate = browser.session === 'private';
  const isWeb = section === 'Tabs' && Boolean(active?.url && !active.failure) && !palette && !menu && !editing;
  const theme = browser.appearance;

  const accept = useCallback((response: Result) => {
    if (response.error === 'disconnected') { setConnected(false); return; }
    setConnected(true);
    setBrowser((state) => response.state.revision > state.revision ? response.state : state);
  }, []);
  const send = useCallback(async (command: Command) => {
    const response = await dispatch(command);
    accept(response);
    if (response.error) setNotice(errors[response.error]);
    else if (command.type !== 'snapshot') setNotice('');
    return response;
  }, [accept]);

  useEffect(() => {
    let mounted = true;
    let pending = false;
    const update = async () => {
      if (pending) return;
      pending = true;
      const result = await dispatch({ type: 'snapshot' });
      pending = false;
      if (mounted) accept(result);
    };
    void update();
    const timer = setInterval(update, 240);
    return () => { mounted = false; clearInterval(timer); };
  }, [accept]);

  useEffect(() => {
    document.documentElement.dataset.theme = theme;
  }, [theme]);

  useLayoutEffect(() => {
    setBookmarks([]); setBookmarkForm(undefined); setBookmarkQuery('');
  }, [browser.sessionID]);

  useEffect(() => {
    const surface = content.current;
    if (!surface || !connected) return;
    const present = () => {
      const rect = surface.getBoundingClientRect();
      void dispatch({ type: 'presentation', visible: isWeb, left: rect.left, top: rect.top });
    };
    const observer = new ResizeObserver(present);
    observer.observe(surface);
    window.addEventListener('resize', present);
    present();
    return () => { observer.disconnect(); window.removeEventListener('resize', present); };
  }, [connected, isWeb, sidebar, sideWidth, section]);

  useEffect(() => {
    if (palette) commands.current?.focus();
  }, [palette]);

  function choose(value: Section) { setSection(value); setMenu(undefined); }
  function focusAddress() {
    choose('Tabs');
    setDraft(active?.url ?? '');
    setEditing(true);
    requestAnimationFrame(() => { address.current?.focus(); address.current?.select(); });
  }
  function openPalette() {
    previousFocus.current = document.activeElement instanceof HTMLElement ? document.activeElement : null;
    setQuery(''); setMenu(undefined); setPalette(true);
  }
  function closePalette() {
    setPalette(false);
    requestAnimationFrame(() => previousFocus.current?.focus());
  }
  function tabAction(type: 'close' | 'duplicate' | 'back' | 'forward' | 'reload' | 'stop' | 'copy' | 'paste', tab = active) {
    if (!tab) return;
    void send({ type, tab: tab.id }).then((response) => {
      if (type === 'copy' && !response.error) setNotice('Address copied.');
      if (type === 'paste' && response.text) void openAddress(response.text);
    });
    setMenu(undefined);
  }
  async function createTab() {
    const result = await send({ type: inPrivate ? 'newTab' : 'startPrivate' });
    if (!result.error) {
      choose('Tabs');
      setEditing(false);
    }
  }
  function selectTab(tab: Tab) {
    choose('Tabs');
    setEditing(false);
    void send({ type: 'activate', tab: tab.id });
  }
  async function openAddress(value: string) {
    const url = destination(value);
    if (!url) { setNotice('Enter a valid web address or search query.'); return; }
    if (!active) { setNotice('Start a private session to browse.'); return; }
    choose('Tabs');
    setEditing(false);
    address.current?.blur();
    await send({ type: 'navigate', url, tab: active.id });
  }
  function handleAddress(event: FormEvent) { event.preventDefault(); void openAddress(draft); }
  function keyAction(key: string) {
    switch (key) {
      case 'l': focusAddress(); break;
      case 't': void createTab(); break;
      case 'w': tabAction('close'); break;
      case 'r': tabAction('reload'); break;
      case 'k': openPalette(); break;
      case ',': choose('Settings'); break;
      case '[': tabAction('back'); break;
      case ']': tabAction('forward'); break;
    }
  }
  useEffect(() => {
    const shortcut = (event: globalThis.KeyboardEvent) => {
      if (!event.metaKey || event.altKey || event.ctrlKey || !['l', 't', 'w', 'r', 'k', ',', '[', ']'].includes(event.key.toLowerCase())) return;
      event.preventDefault();
      keyAction(event.key.toLowerCase());
    };
    const fromHost = (event: Event) => keyAction((event as CustomEvent<string>).detail);
    window.addEventListener('keydown', shortcut);
    window.addEventListener('vezham-shortcut', fromHost);
    return () => {
      window.removeEventListener('keydown', shortcut);
      window.removeEventListener('vezham-shortcut', fromHost);
    };
  });

  const paletteActions = [
    { name: inPrivate ? 'New tab' : 'Start private session', key: '⌘T', run: createTab },
    { name: 'Focus address', key: '⌘L', run: focusAddress, disabled: !active },
    { name: 'Reload tab', key: '⌘R', run: () => tabAction('reload'), disabled: !active?.url },
    { name: 'Toggle sidebar', key: '', run: () => setSidebar((value) => !value) },
    ...sections.slice(1).map((name) => ({ name: 'Open ' + name.toLowerCase(), key: name === 'Settings' ? '⌘,' : '', run: () => choose(name) })),
  ].filter((item) => item.name.toLowerCase().includes(query.toLowerCase()));

  function paletteKey(event: KeyboardEvent<HTMLDialogElement>) {
    if (event.key === 'Escape') { event.preventDefault(); closePalette(); }
    const items = Array.from(event.currentTarget.querySelectorAll<HTMLElement>('input, button:not([disabled])'));
    if (event.key === 'ArrowDown' || event.key === 'ArrowUp') {
      event.preventDefault();
      const index = items.indexOf(document.activeElement as HTMLElement);
      items[(index + (event.key === 'ArrowDown' ? 1 : items.length - 1)) % items.length]?.focus();
    } else if (event.key === 'Tab' && items.length) {
      const edge = event.shiftKey ? items[0] : items.at(-1);
      if (document.activeElement === edge) { event.preventDefault(); (event.shiftKey ? items.at(-1) : items[0])?.focus(); }
    }
  }

  function addBookmark(event: FormEvent) {
    event.preventDefault();
    if (!inPrivate || !bookmarkForm) return;
    const url = destination(bookmarkForm.url);
    if (!url || !bookmarkForm.name.trim()) { setNotice('Enter a name and a valid destination.'); return; }
    setBookmarks((items) => items.some((item) => item.id === bookmarkForm.id)
      ? items.map((item) => item.id === bookmarkForm.id ? { ...bookmarkForm, url } : item)
      : [...items, { ...bookmarkForm, url }]);
    setBookmarkForm(undefined); setNotice('');
  }

  function moveBookmark(id: string, offset: number) {
    setBookmarks((items) => {
      const index = items.findIndex((item) => item.id === id);
      const next = index + offset;
      if (index < 0 || next < 0 || next >= items.length) return items;
      const moved = items.slice();
      [moved[index], moved[next]] = [moved[next], moved[index]];
      return moved;
    });
  }

  function tabMenu(tab: Tab) {
    return <div className="popover" aria-label="Tab actions">
      <Button variant="ghost" size="sm" isDisabled={!tab.url} onPress={() => tabAction('reload', tab)}>Reload</Button>
      <Button variant="ghost" size="sm" onPress={() => tabAction('duplicate', tab)}>Duplicate tab</Button>
      <Button variant="ghost" size="sm" onPress={() => { void send({ type: 'move', tab: tab.id, offset: -1 }); setMenu(undefined); }}>Move left</Button>
      <Button variant="ghost" size="sm" onPress={() => { void send({ type: 'move', tab: tab.id, offset: 1 }); setMenu(undefined); }}>Move right</Button>
      <Button variant="ghost" size="sm" isDisabled={!tab.url} onPress={() => tabAction('copy', tab)}>Copy address</Button>
      <Button variant="ghost" size="sm" onPress={() => tabAction('close', tab)}>Close tab</Button>
    </div>;
  }

  return <div className="browser" style={{ '--sidebar-width': sidebar ? sideWidth + 'px' : '0px' } as React.CSSProperties}
    onKeyDown={(event) => { if (event.key === 'Escape' && menu) setMenu(undefined); }}>
    <header className="chrome">
      <div className="browser-toolbar">
        <Tool icon="sidebar" label={sidebar ? 'Hide sidebar' : 'Show sidebar'} action={() => setSidebar(!sidebar)}/>
        <span className="divider"/>
        <Tool icon="back" label="Go back" action={() => tabAction('back')} disabled={!active?.back}/>
        <Tool icon="forward" label="Go forward" action={() => tabAction('forward')} disabled={!active?.forward}/>
        <Tool icon={active?.loading ? 'stop' : 'reload'} label={active?.loading ? 'Stop loading' : 'Reload'} action={() => tabAction(active?.loading ? 'stop' : 'reload')} disabled={!active?.url}/>
        <div className="omnibox">
          <form onSubmit={handleAddress} className="address">
            <span title={active?.connection === 'encrypted' ? 'WebKit reports an encrypted connection' : active?.connection === 'unencrypted' ? 'Unencrypted connection' : 'Connection information unavailable'}><Icon name={active?.connection === 'encrypted' ? 'lock' : active?.connection === 'unencrypted' ? 'info' : 'search'} size={15}/></span>
            <Input ref={address} aria-label="Address and search" placeholder={inPrivate ? 'Search or enter an address' : 'Start a private session to browse'}
              value={editing ? draft : active?.url ?? ''} disabled={!active} onChange={(event) => setDraft(event.target.value)}
              onFocus={() => { setDraft(active?.url ?? ''); setEditing(true); }}
              onBlur={() => { setEditing(false); }}
              onKeyDown={(event) => { if (event.key === 'Escape') { setEditing(false); address.current?.blur(); } }}/>
            <kbd>⌘L</kbd>
          </form>
          {editing && draft && <div className="suggestions">
            {search.suggestions(draft).map((item) => <Button key={item.label} variant="ghost" onPress={() => void openAddress(item.value)}
              onPointerDown={(event) => event.preventDefault()}><Icon name="search" size={15}/>{item.label}<span className="truncate">{item.value}</span></Button>)}
          </div>}
        </div>
        <Tool icon="command" label="Open command palette" action={openPalette}/>
        <div className="nav-menu">
          <Tool icon="menu" label="Navigation actions" action={() => setMenu(menu === 'navigation' ? undefined : 'navigation')}/>
          {menu === 'navigation' && <div className="popover">
            <Button size="sm" variant="ghost" isDisabled={!active?.url} onPress={() => tabAction('copy')}>Copy address</Button>
            <Button size="sm" variant="ghost" isDisabled={!active} onPress={() => tabAction('paste')}>Paste and navigate</Button>
            <Button size="sm" variant="ghost" onPress={() => choose('Settings')}>Settings</Button>
          </div>}
        </div>
        <span className={inPrivate ? 'session-tag private' : 'session-tag'}><span className="session-dot"/>{inPrivate ? 'Private session' : 'Workspace'}</span>
      </div>
      <div className="tabbar">
        <div className="tabstrip" role="tablist" aria-label="Browser tabs">
          {!browser.tabs.length && <button className="tab start-tab" role="tab" aria-selected={section === 'Tabs'} onClick={() => choose('Tabs')}><Icon name="logo" size={15}/> Start</button>}
          {browser.tabs.map((tab) => <div key={tab.id} className={tab.id === browser.selected ? 'tab-wrap current' : 'tab-wrap'}
            onContextMenu={(event) => { event.preventDefault(); setMenu(tab.id); }}
            onDragOver={(event) => event.preventDefault()}
            onDrop={(event) => {
              event.preventDefault();
              const from = browser.tabs.findIndex((item) => item.id === dragged.current);
              const to = browser.tabs.indexOf(tab);
              if (from >= 0 && from !== to) void send({ type: 'move', tab: browser.tabs[from].id, offset: to - from });
              dragged.current = undefined;
            }}>
            <button className="tab" role="tab" aria-selected={tab.id === browser.selected} draggable
              onDragStart={(event) => { dragged.current = tab.id; event.dataTransfer.effectAllowed = 'move'; }}
              onDragEnd={() => { dragged.current = undefined; }}
              onKeyDown={(event) => {
                if (event.key === 'ContextMenu' || (event.shiftKey && event.key === 'F10')) { event.preventDefault(); setMenu(tab.id); }
                if (event.key === 'ArrowLeft' || event.key === 'ArrowRight') {
                  const next = browser.tabs[(browser.tabs.indexOf(tab) + (event.key === 'ArrowLeft' ? browser.tabs.length - 1 : 1)) % browser.tabs.length];
                  if (next) { event.preventDefault(); selectTab(next); }
                }
              }} onClick={() => selectTab(tab)}>
              {tab.loading ? <span className="spinner" aria-label="Loading"/> : <Icon name={tab.url ? 'globe' : 'logo'} size={14}/>}
              <span>{tab.title || 'New tab'}</span>
            </button>
            <Tool icon="close" label={'Close ' + (tab.title || 'tab')} action={() => tabAction('close', tab)}/>
          </div>)}
        </div>
        <Tool icon="plus" label={inPrivate ? 'New tab' : 'Start private session'} disabled={!connected} action={() => void createTab()}/>
      </div>
      {menu && menu !== 'navigation' && <div className="tab-popover">{browser.tabs.filter((tab) => tab.id === menu).map((tab) => <div key={tab.id}>{tabMenu(tab)}</div>)}</div>}
      {inPrivate && bookmarks.length > 0 && <nav className="bookmark-toolbar" aria-label="Session bookmarks">
        <Icon name="bookmarks" size={14}/>{bookmarks.map((item) =>
          <Button variant="ghost" size="sm" key={item.id} onPress={() => void openAddress(item.url)}>{item.name}</Button>)}
      </nav>}
      {active?.loading && <div className="progress" role="progressbar" aria-label="Page loading" aria-valuenow={Math.round(active.progress * 100)}><span style={{ width: active.progress * 100 + '%' }}/></div>}
    </header>
    <div className="workspace">
      {sidebar && <aside className="sidebar" aria-label="Workspace sidebar">
        <div className="wordmark"><span className="brandmark"><Icon name="logo" size={21}/></span><div><strong>Vezham</strong><small>Browser</small></div></div>
        <div className="sidebar-label">Workspace</div>
        <nav aria-label="Workspace">
          {sections.map((item) => <Button variant="ghost" className="side-item" key={item} aria-current={section === item ? 'page' : undefined} onPress={() => choose(item)}>
            <Icon name={item.toLowerCase()} size={17}/>{item}
            {item === 'Tabs' && browser.tabs.length > 0 && <span className="side-count">{browser.tabs.length}</span>}
          </Button>)}
        </nav>
        <div className="side-footer">
          <span><Icon name={inPrivate ? 'shield' : 'profiles'} size={15}/>{inPrivate ? 'Private session' : 'No active profile'}</span>
          {inPrivate && <Button size="sm" variant="ghost" onPress={() => { void send({ type: 'endPrivate' }); choose('Tabs'); }}>End session</Button>}
        </div>
        <div role="separator" aria-label="Resize sidebar" aria-orientation="vertical" aria-valuemin={166} aria-valuemax={300} aria-valuenow={sideWidth}
          tabIndex={0} className="resizer"
          onKeyDown={(event) => { if (event.key === 'ArrowLeft' || event.key === 'ArrowRight') { event.preventDefault(); setSideWidth((width) => Math.max(166, Math.min(300, width + (event.key === 'ArrowLeft' ? -12 : 12)))); } }}
          onPointerDown={(event) => event.currentTarget.setPointerCapture(event.pointerId)}
          onPointerMove={(event) => { if (event.currentTarget.hasPointerCapture(event.pointerId)) setSideWidth(Math.max(166, Math.min(300, event.clientX))); }}/>
      </aside>}
      <main className="content" ref={content} aria-label="Browser workspace">
        {section === 'Tabs' && !active?.url && !active?.failure && <section className="welcome">
          <div className="motif" aria-hidden="true"><i/><i/><i/><i/></div>
          <div className="welcome-inner">
            <span className="eyebrow"><Icon name={inPrivate ? 'shield' : 'logo'} size={17}/>{inPrivate ? 'Private browsing' : 'Vezham browser'}</span>
            <h1>{inPrivate ? 'Where to?' : <>A little room<br/>to explore.</>}</h1>
            <p>{inPrivate ? 'Enter a destination or search the web. This session stays separate and closes with its last tab.' : 'Open a private session to explore the web. Your tabs and website data are discarded when the session ends.'}</p>
            {inPrivate ? <form className="start-search" onSubmit={(event) => { event.preventDefault(); const data = new FormData(event.currentTarget); void openAddress(String(data.get('query') ?? '')); }}>
              <Icon name="search"/><Input aria-label="New tab search" name="query" placeholder="Search or enter an address"/><Button type="submit" variant="primary" isIconOnly aria-label="Go"><Icon name="arrow"/></Button>
            </form> : <Button className="primary" variant="primary" onPress={() => void createTab()} isDisabled={!connected}><Icon name="plus" size={18}/> Start private session <Icon name="arrow" size={16}/></Button>}
            {inPrivate && bookmarks.length > 0 && <div className="favorites">{bookmarks.slice(0, 6).map((item) => <Button key={item.id} variant="outline" onPress={() => void openAddress(item.url)}><Icon name="bookmarks" size={15}/>{item.name}</Button>)}</div>}
            <div className="welcome-note"><Icon name={inPrivate ? 'lock' : 'shield'} size={15}/>{inPrivate ? 'Search queries are sent to DuckDuckGo on submit.' : 'Protected profiles are currently unavailable.'}</div>
          </div>
        </section>}
        {section === 'Tabs' && active?.failure && <div className="panel"><Empty icon="globe" title={active.failure === 'content-unavailable' ? 'Web content stopped' : 'This page couldn’t load'}>{active.failure === 'content-unavailable' ? 'End this private session and start another to continue.' : 'Check the address or try loading the page again.'}</Empty>
          <Button variant="outline" onPress={() => active.failure === 'content-unavailable' ? void send({ type: 'endPrivate' }) : tabAction('reload')}>{active.failure === 'content-unavailable' ? 'End session' : 'Try again'}</Button></div>}
        {section === 'Tabs' && active?.url && !active.failure && !isWeb && <div className="page-covered" aria-hidden="true"><Icon name="globe" size={30}/></div>}
        {section === 'Bookmarks' && <div className="panel">
          <div className="panel-heading"><div><span className="eyebrow">Library</span><h1>Bookmarks</h1></div><Button variant="primary" isDisabled={!inPrivate} onPress={() => setBookmarkForm({ id: crypto.randomUUID(), name: '', url: '', folder: '' })}><Icon name="plus" size={16}/> Add bookmark</Button></div>
          <p className="muted">Session bookmarks are held in memory and disappear when the private session ends.</p>
          <Input aria-label="Filter bookmarks" placeholder="Filter bookmarks" value={bookmarkQuery} onChange={(event) => setBookmarkQuery(event.target.value)}/>
          {bookmarkForm && <form className="editor" onSubmit={addBookmark}>
            <Input aria-label="Bookmark name" placeholder="Name" value={bookmarkForm.name} onChange={(event) => setBookmarkForm({ ...bookmarkForm, name: event.target.value })}/>
            <Input aria-label="Bookmark address" placeholder="Web address" value={bookmarkForm.url} onChange={(event) => setBookmarkForm({ ...bookmarkForm, url: event.target.value })}/>
            <Input aria-label="Bookmark folder" placeholder="Folder (optional)" value={bookmarkForm.folder} onChange={(event) => setBookmarkForm({ ...bookmarkForm, folder: event.target.value })}/>
            <div className="row-actions"><Button type="submit" variant="primary">Save bookmark</Button><Button variant="ghost" onPress={() => setBookmarkForm(undefined)}>Cancel</Button></div>
          </form>}
          {!bookmarks.length && <Empty icon="bookmarks" title="Room for favorites">{inPrivate ? 'Add a bookmark for this session.' : 'Start a private session to add temporary bookmarks.'}</Empty>}
          {[...new Set(bookmarks.map((item) => item.folder))].map((folder) => {
            const entries = bookmarks.filter((item) => item.folder === folder && (item.name + item.url).toLowerCase().includes(bookmarkQuery.toLowerCase()));
            return entries.length > 0 && <div className="bookmark-group" key={folder}><h2><Icon name="folder" size={17}/>{folder || 'Favorites'}</h2>{entries.map((item) => <div className="bookmark-row" key={item.id}><Button variant="ghost" onPress={() => void openAddress(item.url)}>{item.name}</Button><Tool icon="up" label={'Move ' + item.name + ' earlier'} action={() => moveBookmark(item.id, -1)} disabled={bookmarks[0]?.id === item.id}/><Tool icon="down" label={'Move ' + item.name + ' later'} action={() => moveBookmark(item.id, 1)} disabled={bookmarks.at(-1)?.id === item.id}/><Button size="sm" variant="ghost" onPress={() => setBookmarkForm(item)}>Edit</Button><Button size="sm" variant="ghost" onPress={() => setBookmarks((list) => list.filter((entry) => entry.id !== item.id))}>Remove</Button></div>)}</div>;
          })}
        </div>}
        {section === 'History' && <div className="panel"><div className="panel-heading"><div><span className="eyebrow">Library</span><h1>History</h1></div><Button variant="outline" isDisabled>Clear history</Button></div><Empty icon="history" title="No history is recorded">{inPrivate ? 'Pages visited in this session are excluded from browser history.' : 'History will be available with protected profiles.'}</Empty></div>}
        {section === 'Downloads' && <div className="panel"><div className="panel-heading"><div><span className="eyebrow">Library</span><h1>Downloads</h1></div></div><Empty icon="downloads" title="Downloads are unavailable">Native file transfers and download metadata are unavailable in this build.</Empty></div>}
        {section === 'Profiles' && <div className="panel"><div className="panel-heading"><div><span className="eyebrow">Workspace</span><h1>Profiles</h1></div><Button variant="outline" isDisabled>Create profile</Button></div><Empty icon="profiles" title="Protected profiles unavailable">A protected store is required to create or open a profile. Private browsing is available in a separate session.</Empty><Button className="primary" isDisabled={!connected || inPrivate} onPress={() => void createTab()}>Start private session</Button></div>}
        {section === 'Settings' && <div className="panel settings-panel"><span className="eyebrow">Preferences</span><h1>Settings</h1><div className="settings-layout"><nav aria-label="Settings sections">{settingSections.map((item) => <Button key={item} variant="ghost" aria-current={settings === item ? 'page' : undefined} onPress={() => setSettings(item)}>{item}</Button>)}</nav>
          <div className="setting-content"><h2>{settings}</h2>
          {settings === 'Appearance' ? <><p className="muted">Choose how Vezham looks on this Mac.</p><div className="theme-options">{(['system', 'light', 'dark'] as Appearance[]).map((item) => <Button key={item} variant={item === theme ? 'primary' : 'outline'} aria-pressed={item === theme} isDisabled={!connected} onPress={() => void send({ type: 'appearance', value: item })}>{item}</Button>)}</div></>
            : settings === 'Keyboard shortcuts' ? <dl className="key-list">{shortcutList.map(([name, key]) => <div key={key}><dt>{name}</dt><dd><kbd>{key}</kbd></dd></div>)}</dl>
            : <p className="muted">{settings === 'Search' ? 'Search uses DuckDuckGo. Suggestions are generated locally.' : settings === 'Privacy' ? 'Private tabs use a nonpersistent website store. No browser history or backups are created.' : settings === 'Website permissions' ? 'Permission management is unavailable. Native permission rules remain in effect.' : 'Additional controls for this section are unavailable in this build.'}</p>}
          </div></div></div>}
      </main>
    </div>
    <footer className="status" aria-live="polite">
      <span>{notice || (connected ? active?.loading ? 'Loading page…' : inPrivate ? 'Session data is temporary' : 'Ready for a private session' : 'Connecting to native browser…')}</span>
      <Button variant="ghost" size="sm" onPress={openPalette}><Icon name="command" size={14}/> Commands <kbd>⌘K</kbd></Button>
    </footer>
    {palette && <div className="palette-layer" onPointerDown={(event) => { if (event.target === event.currentTarget) closePalette(); }}><dialog open aria-modal="true" aria-label="Browser commands" className="palette" onKeyDown={paletteKey}>
      <div className="palette-search"><Icon name="search"/><Input ref={commands} value={query} aria-label="Find a command" placeholder="Find a command…" onChange={(event) => setQuery(event.target.value)}/><Tool icon="close" label="Close commands" action={closePalette}/></div>
      <div className="palette-items">{paletteActions.map((item) => <Button key={item.name} variant="ghost" isDisabled={'disabled' in item && item.disabled}
        onPress={() => { closePalette(); void item.run(); }}>{item.name}{item.key && <kbd>{item.key}</kbd>}</Button>)}{!paletteActions.length && <p>No commands found.</p>}</div>
    </dialog></div>}
  </div>;
}
