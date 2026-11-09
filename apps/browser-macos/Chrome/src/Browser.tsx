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
  const [sideWidth, setSideWidth] = useState(236);
  const [editor, setEditor] = useState<{ type: 'spaceCreate' | 'spaceRename' | 'groupCreate' | 'groupRename'; target?: string; name: string }>();
  const [tabFilter, setTabFilter] = useState('');
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
  const paletteDialog = useRef<HTMLDialogElement>(null);
  const editorDialog = useRef<HTMLDialogElement>(null);
  const contextDialog = useRef<HTMLDialogElement>(null);
  const editorTrigger = useRef<HTMLElement | null>(null);
  const skipFocusRestore = useRef(false);
  const content = useRef<HTMLElement>(null);
  const dragged = useRef<string>(undefined);
  const active = browser.tabs.find((tab) => tab.id === browser.selected);
  const inPrivate = browser.session === 'private';
  const isWeb = !browser.recovery && section === 'Tabs' && Boolean(active?.url && !active.failure) && !palette && !menu && !editing && !editor;
  const theme = browser.appearance;
  const spaceTabs = browser.tabs.filter((tab) => tab.space === browser.activeSpace);
  const spaceGroups = browser.groups.filter((group) => group.space === browser.activeSpace);
  const currentSpace = browser.spaces.find((space) => space.id === browser.activeSpace);
  const splitTabs = browser.split.map((id) => browser.tabs.find((tab) => tab.id === id)).filter((tab): tab is Tab => Boolean(tab));
  const renderedTabs = [...spaceTabs.filter(tab => tab.pinned), ...spaceGroups.filter(group => !group.collapsed).flatMap(group => spaceTabs.filter(tab => !tab.pinned && tab.group === group.id)), ...spaceTabs.filter(tab => !tab.pinned && !tab.group)].filter(tab => !tabFilter || tab.title.toLowerCase().includes(tabFilter.toLowerCase()));
  const keyboardTab = renderedTabs.find(tab => tab.id === browser.selected) ?? renderedTabs[0];
  const canSplit = !browser.mini && spaceTabs.some((tab) => tab.id !== active?.id);

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
    setEditing(false);
    setSection('Tabs');
  }, [browser.selected]);

  useEffect(() => {
    document.documentElement.dataset.theme = theme;
  }, [theme]);

  useEffect(() => {
    if (!browser.recovery) return;
    setPalette(false); setMenu(undefined); setEditor(undefined); setEditing(false); setDraft('');
  }, [browser.recovery]);

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
  }, [connected, isWeb, sidebar, sideWidth, section, browser.split.length, browser.mini]);

  useEffect(() => {
    const dialog = palette ? paletteDialog.current : editor ? editorDialog.current : menu ? contextDialog.current : null;
    if (!dialog) return;
    const previous = editor ? editorTrigger.current : document.activeElement instanceof HTMLElement ? document.activeElement : null;
    if (!dialog.open) dialog.showModal();
    dialog.querySelector<HTMLElement>('input, button:not([disabled])')?.focus();
    return () => {
      dialog.close();
      if (skipFocusRestore.current) { skipFocusRestore.current = false; return; }
      requestAnimationFrame(() => {
        if (previous?.isConnected) previous.focus();
        else document.querySelector<HTMLElement>('[aria-label="Workspace actions"], [aria-label="Address and search"]')?.focus();
      });
    };
  }, [palette, Boolean(editor), menu]);

  function openEditor(value: NonNullable<typeof editor>) {
    editorTrigger.current = document.activeElement instanceof HTMLElement ? document.activeElement : null;
    setEditor(value);
  }
  function containModalFocus(event: KeyboardEvent<HTMLDialogElement>) {
    if (event.key !== 'Tab') return;
    const items = Array.from(event.currentTarget.querySelectorAll<HTMLElement>('input, button:not([disabled])'));
    const edge = event.shiftKey ? items[0] : items.at(-1);
    if (items.length && document.activeElement === edge) {
      event.preventDefault(); (event.shiftKey ? items.at(-1) : items[0])?.focus();
    }
  }
  function choose(value: Section) { setSection(value); setMenu(undefined); }
  function focusAddress() {
    if (palette || menu || editor) skipFocusRestore.current = true;
    choose('Tabs');
    setDraft(active?.url ?? '');
    setEditing(true);
    requestAnimationFrame(() => { address.current?.focus(); address.current?.select(); });
  }
  function openPalette() {
    setQuery(''); setMenu(undefined); setPalette(true);
  }
  function closePalette() {
    setPalette(false);
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
      case 't': openPalette(); break;
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
    { name: 'Create Space', key: '', run: () => openEditor({ type: 'spaceCreate', name: '' }), disabled: !inPrivate },
    { name: 'Create tab group', key: '', run: () => openEditor({ type: 'groupCreate', name: '' }), disabled: !inPrivate },
    { name: 'Add Split Screen', key: '', run: () => {
      const other = spaceTabs.find((tab) => tab.id !== active?.id);
      if (other) void send({ type: 'split', tab: other.id });
    }, disabled: !canSplit },
    { name: 'Exit Split Screen', key: '', run: () => void send({ type: 'unsplit' }), disabled: !browser.split.length },
    { name: 'Open in Vezham Mini', key: '', run: () => active && void send({ type: 'miniOpen', tab: active.id }), disabled: !active?.url || browser.mini },
    { name: 'Close active tab', key: '⌘W', run: () => tabAction('close'), disabled: !active },
    ...browser.tabs.map((tab) => ({ id: 'tab:' + tab.id, name: 'Tab · ' + tab.title, key: '', run: () => selectTab(tab) })),
    ...browser.spaces.map((space) => ({ id: 'space:' + space.id, name: 'Space · ' + space.name, key: '', run: () => { choose('Tabs'); void send({ type: 'spaceSwitch', target: space.id }); } })),
    ...(query.trim() && inPrivate ? [{ name: 'Go to · ' + query.trim(), key: '↵', run: async () => {
      let target = active;
      if (!target) {
        const result = await send({ type: 'newTab' });
        target = result.state.tabs.find((tab) => tab.id === result.state.selected);
      }
      const url = destination(query);
      if (target && url) { choose('Tabs'); void send({ type: 'navigate', tab: target.id, url }); }
    } }] : []),
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
      <Button variant="ghost" size="sm" onPress={() => { void send({ type: 'pin', tab: tab.id }); setMenu(undefined); }}>{tab.pinned ? 'Unpin tab' : 'Pin tab'}</Button>
      <Button variant="ghost" size="sm" isDisabled={!active || active.id === tab.id} onPress={() => { void send({ type: 'split', tab: tab.id }); setMenu(undefined); }}>Open in split</Button>
      <Button variant="ghost" size="sm" isDisabled={!tab.url} onPress={() => { void send({ type: 'miniOpen', tab: tab.id }); setMenu(undefined); }}>Open in Vezham Mini</Button>
      <Button variant="ghost" size="sm" isDisabled={!tab.url} onPress={() => tabAction('reload', tab)}>Reload</Button>
      <Button variant="ghost" size="sm" onPress={() => tabAction('duplicate', tab)}>Duplicate tab</Button>
      <Button variant="ghost" size="sm" onPress={() => { void send({ type: 'move', tab: tab.id, offset: -1 }); setMenu(undefined); }}>Move up</Button>
      <Button variant="ghost" size="sm" onPress={() => { void send({ type: 'move', tab: tab.id, offset: 1 }); setMenu(undefined); }}>Move down</Button>
      <Button variant="ghost" size="sm" isDisabled={!tab.url} onPress={() => tabAction('copy', tab)}>Copy address</Button>
      {spaceGroups.map((group) => <Button variant="ghost" size="sm" key={group.id} onPress={() => { void send({ type: 'tabGroup', tab: tab.id, target: group.id }); setMenu(undefined); }}>Move to {group.name}</Button>)}
      {tab.group && <Button variant="ghost" size="sm" onPress={() => { void send({ type: 'tabGroup', tab: tab.id }); setMenu(undefined); }}>Remove from group</Button>}
      {browser.spaces.filter((space) => space.id !== tab.space).map((space) => <Button variant="ghost" size="sm" key={space.id} onPress={() => { void send({ type: 'tabSpace', tab: tab.id, target: space.id }); setMenu(undefined); }}>Move to {space.name}</Button>)}
      <Button variant="ghost" size="sm" onPress={() => tabAction('close', tab)}>Close tab</Button>
    </div>;
  }

  function verticalTab(tab: Tab) {
    if (tabFilter && !tab.title.toLowerCase().includes(tabFilter.toLowerCase())) return null;
    return <div key={tab.id} className={tab.id === browser.selected ? 'vertical-tab current' : 'vertical-tab'}
      onContextMenu={(event) => { event.preventDefault(); setMenu(tab.id); }}
      onDragOver={(event) => { event.preventDefault(); event.dataTransfer.dropEffect = 'move'; }}
      onDrop={(event) => {
        event.preventDefault();
        const from = browser.tabs.findIndex((item) => item.id === dragged.current);
        if (from >= 0 && browser.tabs[from].id !== tab.id) {
          void send({ type: 'move', tab: browser.tabs[from].id, offset: browser.tabs.indexOf(tab) - from });
        }
        dragged.current = undefined;
      }}>
      <button className="tab" role="tab" aria-selected={tab.id === browser.selected} tabIndex={tab.id === keyboardTab?.id ? 0 : -1} draggable
        onDragStart={(event) => { dragged.current = tab.id; event.dataTransfer.effectAllowed = 'move'; event.dataTransfer.setData('application/x-vezham-tab', tab.id); }}
        onDragEnd={() => { dragged.current = undefined; }}
        onKeyDown={(event) => {
          if (event.key === 'ContextMenu' || (event.shiftKey && event.key === 'F10')) { event.preventDefault(); setMenu(tab.id); }
          if (event.key === 'ArrowUp' || event.key === 'ArrowDown') {
            const rendered = Array.from(event.currentTarget.closest('[role="tablist"]')?.querySelectorAll<HTMLButtonElement>('[role="tab"]') ?? []);
            const next = rendered[(rendered.indexOf(event.currentTarget) + (event.key === 'ArrowUp' ? rendered.length - 1 : 1)) % rendered.length];
            if (next) { event.preventDefault(); next.focus(); next.click(); }
          }
        }} onClick={() => selectTab(tab)}>
        {tab.loading ? <span className="spinner" aria-label="Loading"/> : tab.favicon ? <img className="favicon" src={tab.favicon} alt=""/> : <Icon name={tab.failure ? 'info' : tab.pinned ? 'pin' : tab.url ? 'globe' : 'logo'} size={16}/>}
        <span>{tab.title || 'New tab'}</span>
      </button>
      <Tool icon="menu" label={'Actions for ' + tab.title} action={() => setMenu(menu === tab.id ? undefined : tab.id)}/>
      <Tool icon="close" label={'Close ' + tab.title} action={() => tabAction('close', tab)}/>
    </div>;
  }

  function miniView() {
    return <div className="mini-browser">
      <header className="mini-toolbar">
        <span className="mini-brand"><Icon name="logo" size={18}/><strong>Mini</strong></span>
        <Tool icon="back" label="Go back" disabled={!active?.back} action={() => tabAction('back')}/>
        <Tool icon="forward" label="Go forward" disabled={!active?.forward} action={() => tabAction('forward')}/>
        <Tool icon={active?.loading ? 'stop' : 'reload'} label={active?.loading ? 'Stop loading' : 'Reload'} disabled={!active?.url} action={() => tabAction(active?.loading ? 'stop' : 'reload')}/>
        <form className="mini-address" onSubmit={handleAddress}><Input aria-label="Mini address" value={editing ? draft : active?.url ?? ''} onFocus={() => { setDraft(active?.url ?? ''); setEditing(true); }} onBlur={() => setEditing(false)} onChange={(event) => setDraft(event.target.value)}/></form>
      </header>
      <div className="mini-actions"><span><Icon name="shield" size={13}/> Private · separate session</span><Button size="sm" variant="ghost" onPress={() => void send({ type: 'miniTransfer' })} isDisabled={!active?.url}>Open in workspace <Icon name="arrow" size={14}/></Button></div>
      <main ref={content} className="mini-content" aria-label="Mini page">
        {active?.failure && <Empty icon="globe" title="This page couldn’t load">Enter another address or reload.</Empty>}
      </main>
      <footer className="status"><span>{notice || (active?.loading ? 'Loading…' : active?.title || 'Vezham Mini')}</span><span>Private</span></footer>
    </div>;
  }

  if (browser.recovery) {
    const ready = browser.recovery === 'ready';
    const failed = browser.recovery === 'failed';
    const title = failed ? 'Private workspace unavailable' : 'Web content stopped';
    const description = ready
      ? 'Restore your workspace layout in a fresh private session. Pages will start blank.'
      : failed ? 'The browser could not safely finish recovery. Close this window to continue.'
        : browser.recovery === 'rebuilding' ? 'Opening a fresh private session…' : 'Closing the stopped private session…';
    return <main className="content" aria-label="Private workspace recovery">
      <div className="panel">
        <div role="status"><Empty icon="globe" title={title}>{description}</Empty></div>
        {ready && <Button variant="primary" onPress={() => void send({ type: 'recoverPrivate' })}>Restore private workspace</Button>}
      </div>
    </main>;
  }

  if (browser.mini) return miniView();

  return <div className="browser arc-workspace" style={{ '--sidebar-width': sidebar ? sideWidth + 'px' : '0px' } as React.CSSProperties}
    onKeyDown={(event) => { if (event.key === 'Escape') { if (editor) setEditor(undefined); else if (menu) setMenu(undefined); } }}>
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
        <Tool icon="split" label={browser.split.length ? 'Exit split' : 'Add split'} disabled={!canSplit && !browser.split.length} action={() => {
          if (browser.split.length) void send({ type: 'unsplit' });
          else { const other = spaceTabs.find((tab) => tab.id !== active?.id); if (other) void send({ type: 'split', tab: other.id }); }
        }}/>
        <Tool icon="command" label="Open command palette" action={openPalette}/>
        <div className="nav-menu">
          <Tool icon="menu" label="Navigation actions" action={() => setMenu(menu === 'navigation' ? undefined : 'navigation')}/>
        </div>
        <span className={inPrivate ? 'session-tag private' : 'session-tag'}><span className="session-dot"/>{inPrivate ? 'Private session' : 'Workspace'}</span>
      </div>

      {active?.loading && <div className="progress" role="progressbar" aria-label="Page loading" aria-valuenow={Math.round(active.progress * 100)}><span style={{ width: active.progress * 100 + '%' }}/></div>}
    </header>
    <div className="workspace">
      {sidebar && <aside className="sidebar" aria-label="Workspace sidebar">
        <div className="wordmark"><span className="brandmark"><Icon name="logo" size={20}/></span><strong>Vezham</strong><Tool icon="menu" label="Workspace actions" action={() => setMenu(menu === 'workspace' ? undefined : 'workspace')}/></div>
        <div className="spaces" aria-label="Spaces">{browser.spaces.map((space, index) => <button key={space.id} aria-label={'Switch to ' + space.name} aria-pressed={space.id === browser.activeSpace}
          onDragOver={(event) => { event.preventDefault(); event.dataTransfer.dropEffect = 'move'; }}
          onDrop={(event) => { event.preventDefault(); if (dragged.current) void send({ type: 'tabSpace', tab: dragged.current, target: space.id }); dragged.current = undefined; }}
          onContextMenu={(event) => { event.preventDefault(); setMenu('space:' + space.id); }}
          onClick={() => { choose('Tabs'); void send({ type: 'spaceSwitch', target: space.id }); }}><span>{index + 1}</span>{space.name}</button>)}
          <Tool icon="plus" label="Create Space" disabled={!inPrivate} action={() => openEditor({ type: 'spaceCreate', name: '' })}/>
        </div>
        <div className="space-heading"><strong>{currentSpace?.name || 'Your workspace'}</strong>
          <Tool icon="menu" label="Space actions" disabled={!inPrivate} action={() => setMenu('space:' + browser.activeSpace)}/></div>
        <Button variant="ghost" className="new-tab-action" isDisabled={!connected} onPress={() => inPrivate ? openPalette() : void createTab()}><Icon name="plus" size={17}/>{inPrivate ? 'New tab' : 'Start private session'}<kbd>⌘T</kbd></Button>
        {inPrivate && <Input className="tab-filter" aria-label="Filter tabs" value={tabFilter} placeholder="Filter tabs" onChange={(event) => setTabFilter(event.target.value)}/>}
        <div className="vertical-tabs" role="tablist" aria-label="Browser tabs" aria-orientation="vertical">
          {spaceTabs.some((tab) => tab.pinned) && <><div className="sidebar-label">Pinned</div>{spaceTabs.filter((tab) => tab.pinned).map(verticalTab)}</>}
          {spaceGroups.map((group) => <div className="tab-group" key={group.id}>
            <div className="group-heading" onDragOver={(event) => { event.preventDefault(); event.dataTransfer.dropEffect = 'move'; }}
              onDrop={(event) => { event.preventDefault(); if (dragged.current) void send({ type: 'tabGroup', tab: dragged.current, target: group.id }); dragged.current = undefined; }}
              onContextMenu={(event) => { event.preventDefault(); setMenu('group:' + group.id); }}>
              <Button variant="ghost" size="sm" aria-expanded={!group.collapsed} onPress={() => void send({ type: 'groupToggle', target: group.id })}><Icon name={group.collapsed ? 'forward' : 'down'} size={14}/>{group.name}<span>{spaceTabs.filter((tab) => tab.group === group.id && !tab.pinned).length}</span></Button>
              <Tool icon="menu" label={'Actions for group ' + group.name} action={() => setMenu('group:' + group.id)}/>
            </div>
            {!group.collapsed && spaceTabs.filter((tab) => !tab.pinned && tab.group === group.id).map(verticalTab)}
          </div>)}
          <div className="sidebar-label">Today</div>{spaceTabs.filter((tab) => !tab.pinned && !tab.group).map(verticalTab)}
          {inPrivate && !spaceTabs.length && <p className="side-empty">A clear space. Open a tab to begin.</p>}
        </div>
        {spaceTabs.length > 1 && <div className="sidebar-split-target" onDragOver={(event) => { event.preventDefault(); event.dataTransfer.dropEffect = 'move'; }} onDrop={(event) => {
          event.preventDefault(); if (dragged.current && dragged.current !== active?.id) void send({ type: 'split', tab: dragged.current }); dragged.current = undefined;
        }}><Icon name="split" size={14}/> Drop a tab to split</div>}
        <div className="library-links">{sections.slice(1).map((item) => <Button variant="ghost" size="sm" key={item} aria-current={section === item ? 'page' : undefined} onPress={() => choose(item)}><Icon name={item.toLowerCase()} size={15}/>{item}</Button>)}</div>
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
      <div className="page-column">
        {splitTabs.length === 2 && <div className="splitbar" aria-label="Split Screen panes">
          {splitTabs.map((tab) => <div key={tab.id}><Button size="sm" variant="ghost" aria-pressed={tab.id === active?.id} onPress={() => selectTab(tab)}>{tab.title}</Button><Tool icon="close" label={'Close pane ' + tab.title} action={() => tabAction('close', tab)}/></div>)}
          <Button size="sm" variant="ghost" onPress={() => void send({ type: 'unsplit' })}>{browser.splitCompact ? 'Narrow view · exit split' : 'Exit split'}</Button>
        </div>}
        <main className="content" ref={content} aria-label="Browser workspace">
        {section === 'Tabs' && !active?.url && !active?.failure && <section className="welcome">

          <div className="welcome-inner">
            <span className="eyebrow"><Icon name={inPrivate ? 'shield' : 'logo'} size={17}/>{inPrivate ? 'Private browsing' : 'Vezham browser'}</span>
            <h1>{inPrivate ? 'Where to?' : 'Your next idea.'}</h1>
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
          {settings === 'Tabs' && <><Button variant="outline" onPress={() => setSidebar(!sidebar)}>{sidebar ? 'Hide sidebar' : 'Show sidebar'}</Button><p className="muted">Spaces, groups and pins are kept for this private session.</p></>}
          {settings === 'Appearance' ? <><p className="muted">Choose how Vezham looks on this Mac.</p><div className="theme-options">{(['system', 'light', 'dark'] as Appearance[]).map((item) => <Button key={item} variant={item === theme ? 'primary' : 'outline'} aria-pressed={item === theme} isDisabled={!connected} onPress={() => void send({ type: 'appearance', value: item })}>{item}</Button>)}</div></>
            : settings === 'Keyboard shortcuts' ? <dl className="key-list">{shortcutList.map(([name, key]) => <div key={key}><dt>{name}</dt><dd><kbd>{key}</kbd></dd></div>)}</dl>
            : <p className="muted">{settings === 'Search' ? 'Search uses DuckDuckGo. Suggestions are generated locally.' : settings === 'Privacy' ? 'Private tabs use a nonpersistent website store. No browser history or backups are created.' : settings === 'Website permissions' ? 'Permission management is unavailable. Native permission rules remain in effect.' : 'Additional controls for this section are unavailable in this build.'}</p>}
          </div></div></div>}
      </main>
      </div>
    </div>
    {menu && <div className="context-shade" onPointerDown={(event) => { if (event.target === event.currentTarget) setMenu(undefined); }}>
      <dialog ref={contextDialog} className="workspace-context" aria-label="Workspace actions" onKeyDown={containModalFocus} onCancel={() => setMenu(undefined)}>
        {menu === 'navigation' && <div className="popover">
          <Button size="sm" variant="ghost" isDisabled={!active?.url} onPress={() => tabAction('copy')}>Copy address</Button>
          <Button size="sm" variant="ghost" isDisabled={!active} onPress={() => tabAction('paste')}>Paste and navigate</Button>
          <Button size="sm" variant="ghost" onPress={() => choose('Settings')}>Settings</Button>
        </div>}
        {browser.tabs.filter((tab) => tab.id === menu).map((tab) => <div key={tab.id}>{tabMenu(tab)}</div>)}
        {menu.startsWith('space:') && <div className="popover"><Button variant="ghost" onPress={() => { openEditor({ type: 'spaceRename', target: menu.slice(6), name: browser.spaces.find((space) => space.id === menu.slice(6))?.name ?? '' }); setMenu(undefined); }}>Rename Space</Button><Button variant="ghost" isDisabled={browser.spaces.length <= 1 || browser.tabs.some((tab) => tab.space === menu.slice(6))} onPress={() => { void send({ type: 'spaceDelete', target: menu.slice(6) }); setMenu(undefined); }}>Delete empty Space</Button></div>}
        {menu.startsWith('group:') && <div className="popover">
          <Button variant="ghost" onPress={() => { openEditor({ type: 'groupRename', target: menu.slice(6), name: browser.groups.find((group) => group.id === menu.slice(6))?.name ?? '' }); setMenu(undefined); }}>Rename group</Button>
          <Button variant="ghost" onPress={() => { void send({ type: 'groupMove', target: menu.slice(6), offset: -1 }); setMenu(undefined); }}>Move group up</Button>
          <Button variant="ghost" onPress={() => { void send({ type: 'groupMove', target: menu.slice(6), offset: 1 }); setMenu(undefined); }}>Move group down</Button>
          <Button variant="ghost" onPress={() => { void send({ type: 'groupDelete', target: menu.slice(6) }); setMenu(undefined); }}>Ungroup tabs</Button>
        </div>}
        {menu === 'workspace' && <div className="popover"><Button variant="ghost" isDisabled={!inPrivate} onPress={() => { openEditor({ type: 'spaceCreate', name: '' }); setMenu(undefined); }}>Create Space</Button><Button variant="ghost" isDisabled={!inPrivate} onPress={() => { openEditor({ type: 'groupCreate', name: '' }); setMenu(undefined); }}>Create tab group</Button><Button variant="ghost" onPress={() => { choose('Settings'); setMenu(undefined); }}>Settings</Button></div>}
      </dialog>
    </div>}
    {editor && <div className="palette-layer"><dialog ref={editorDialog} className="palette" aria-label="Organize workspace" onKeyDown={containModalFocus} onCancel={() => setEditor(undefined)}><form className="organization-editor" onSubmit={(event) => {
      event.preventDefault();
      const command = editor.target ? { type: editor.type as 'spaceRename' | 'groupRename', target: editor.target, name: editor.name } : { type: editor.type as 'spaceCreate' | 'groupCreate', name: editor.name };
      void send(command).then((result) => { if (!result.error) setEditor(undefined); });
    }}><h2>{editor.type.includes('Rename') ? 'Rename' : 'Create'} {editor.type.startsWith('space') ? 'Space' : 'tab group'}</h2><Input autoFocus aria-label="Name" value={editor.name} maxLength={40} onChange={(event) => setEditor({ ...editor, name: event.target.value })}/><div className="row-actions"><Button type="submit" isDisabled={!editor.name.trim()}>Save</Button><Button variant="ghost" onPress={() => setEditor(undefined)}>Cancel</Button></div></form></dialog></div>}
    <footer className="status" aria-live="polite">
      <span>{notice || (connected ? active?.loading ? 'Loading page…' : inPrivate ? 'Session data is temporary' : 'Ready for a private session' : 'Connecting to native browser…')}</span>
      <Button variant="ghost" size="sm" onPress={openPalette}><Icon name="command" size={14}/> Commands <kbd>⌘K</kbd></Button>
    </footer>
    {palette && <div className="palette-layer" onPointerDown={(event) => { if (event.target === event.currentTarget) closePalette(); }}><dialog ref={paletteDialog} aria-label="Browser commands" className="palette" onCancel={() => closePalette()} onKeyDown={paletteKey}>
      <div className="palette-search"><Icon name="search"/><Input ref={commands} value={query} aria-label="Find a command" placeholder="Find a command…" onChange={(event) => setQuery(event.target.value)}/><Tool icon="close" label="Close commands" action={closePalette}/></div>
      <div className="palette-items">{paletteActions.map((item) => <Button key={'id' in item && typeof item.id === 'string' ? item.id : item.name} variant="ghost" isDisabled={'disabled' in item && item.disabled}
        onPress={() => { closePalette(); void item.run(); }}>{item.name}{item.key && <kbd>{item.key}</kbd>}</Button>)}{!paletteActions.length && <p>No commands found.</p>}</div>
    </dialog></div>}
  </div>;
}
