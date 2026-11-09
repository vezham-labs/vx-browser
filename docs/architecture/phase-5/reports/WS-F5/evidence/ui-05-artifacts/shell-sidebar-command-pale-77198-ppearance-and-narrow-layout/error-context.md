# Instructions

- Following Playwright test failed.
- Explain why, be concise, respect Playwright best practices.
- Provide a snippet of code with the fix, if possible.

# Test info

- Name: shell.spec.ts >> sidebar, command palette focus, appearance and narrow layout
- Location: tests/shell.spec.ts:83:5

# Error details

```
Test timeout of 15000ms exceeded.
```

```
Error: expect(locator).toBeVisible() failed

Locator: getByRole('heading', { name: 'Settings', exact: true })
Expected: visible
Error: Test timeout of 15000ms exceeded.

Call log:
  - Expect "toBeVisible" getByRole('heading', { name: 'Settings', exact: true }) with timeout 5000ms
  - waiting for getByRole('heading', { name: 'Settings', exact: true })
  - Test timeout of 15000ms exceeded.

```

# Page snapshot

```yaml
- generic [ref=e3]:
  - banner [ref=e4]:
    - generic [ref=e5]:
      - button "Hide sidebar" [ref=e6] [cursor=pointer]
      - button "Go back" [disabled]
      - button "Go forward" [disabled]
      - button "Reload" [disabled]
      - generic [ref=e9]:
        - generic "Connection information unavailable" [ref=e10]
        - textbox "Address and search" [disabled]:
          - /placeholder: Start a private session to browse
        - generic [ref=e14]: ⌘L
      - button "Add split" [disabled]
      - button "Open command palette" [ref=e15] [cursor=pointer]
      - button "Navigation actions" [ref=e17] [cursor=pointer]
      - generic [ref=e18]: Workspace
  - generic [ref=e20]:
    - complementary "Workspace sidebar" [ref=e21]:
      - generic [ref=e22]:
        - strong [ref=e26]: Vezham
        - button "Workspace actions" [ref=e27] [cursor=pointer]
      - generic "Spaces" [ref=e28]:
        - button "Switch to Personal" [pressed] [ref=e29] [cursor=pointer]:
          - generic [ref=e30]: "1"
          - text: Personal
        - button "Create Space" [disabled]
      - generic [ref=e31]:
        - strong [ref=e32]: Personal
        - button "Space actions" [disabled]
      - button "Start private session ⌘T" [ref=e33] [cursor=pointer]:
        - text: Start private session
        - generic [ref=e34]: ⌘T
      - tablist "Browser tabs" [ref=e35]:
        - generic [ref=e36]: Today
      - generic [ref=e37]:
        - button "Bookmarks" [ref=e38] [cursor=pointer]
        - button "History" [ref=e39] [cursor=pointer]
        - button "Downloads" [ref=e40] [cursor=pointer]
        - button "Profiles" [ref=e41] [cursor=pointer]
        - button "Settings" [ref=e42] [cursor=pointer]
      - generic [ref=e43]: No active profile
      - separator "Resize sidebar" [ref=e48]
    - main "Browser workspace" [ref=e50]:
      - generic [ref=e51]:
        - generic [ref=e52]: Preferences
        - heading "Settings" [level=1] [ref=e53]
        - generic [ref=e54]:
          - navigation "Settings sections" [ref=e55]:
            - button "General" [ref=e56] [cursor=pointer]
            - button "Appearance" [ref=e57] [cursor=pointer]
            - button "Tabs" [ref=e58] [cursor=pointer]
            - button "Search" [ref=e59] [cursor=pointer]
            - button "Privacy" [ref=e60] [cursor=pointer]
            - button "Website permissions" [ref=e61] [cursor=pointer]
            - button "Downloads" [ref=e62] [cursor=pointer]
            - button "Profiles" [ref=e63] [cursor=pointer]
            - button "Keyboard shortcuts" [ref=e64] [cursor=pointer]
            - button "Advanced" [ref=e65] [cursor=pointer]
          - generic [ref=e66]:
            - heading "Appearance" [level=2] [ref=e67]
            - paragraph [ref=e68]: Choose how Vezham looks on this Mac.
            - generic [ref=e69]:
              - button "system" [pressed] [ref=e70] [cursor=pointer]
              - button "light" [ref=e71] [cursor=pointer]
              - button "dark" [ref=e72] [cursor=pointer]
  - contentinfo [ref=e73]:
    - generic [ref=e74]: Ready for a private session
    - button "Commands ⌘K" [ref=e75] [cursor=pointer]:
      - text: Commands
      - generic [ref=e76]: ⌘K
```

# Test source

```ts
  1   | import { test, expect } from '@playwright/test';
  2   | import type { Page } from '@playwright/test';
  3   | import type { Appearance, BrowserState, Command, Tab } from '../src/bridge';
  4   | 
  5   | async function hostStandIn(page: Page) {
  6   |   await page.addInitScript(() => {
  7   |     const state: BrowserState = { revision: 0, session: 'inactive', profile: 'unavailable', tabs: [], appearance: 'system', spaces: [{ id:'personal', name:'Personal' }], activeSpace:'personal', groups: [], split: [], splitCompact:false, mini:false };
  8   |     let sequence = 0;
  9   |     const addTab = () => {
  10  |       const next: Tab = { id: 'test-' + ++sequence, title: 'New tab', space:state.activeSpace, pinned:false, loading: false, progress: 0, back: false, forward: false, connection: 'unknown' };
  11  |       state.tabs.push(next);
  12  |       state.selected = next.id;
  13  |       return next;
  14  |     };
  15  |     Object.defineProperty(window, 'webkit', { value: { messageHandlers: { browserChrome: { postMessage(command: Command & { id: string }) {
  16  |       const target = 'tab' in command ? state.tabs.find((item) => item.id === command.tab) : undefined;
  17  |       switch (command.type) {
  18  |         case 'startPrivate': state.session = 'private'; state.sessionID = 'private-' + sequence; addTab(); break;
  19  |         case 'newTab': addTab(); break;
  20  |         case 'endPrivate': state.session = 'inactive'; state.sessionID = undefined; state.tabs = []; state.selected = undefined; break;
  21  |         case 'close':
  22  |           state.tabs = state.tabs.filter((tab) => tab !== target);
  23  |           state.selected = state.tabs.at(-1)?.id;
  24  |           if (!state.tabs.length) { state.session = 'inactive'; state.sessionID = undefined; }
  25  |           break;
  26  |         case 'activate': state.selected = target?.id; break;
  27  |         case 'navigate':
  28  |           if (target) { target.url = command.url; target.title = 'Fixture page'; target.back = true; }
  29  |           break;
  30  |         case 'duplicate': {
  31  |           const tab = addTab();
  32  |           if (target) { tab.url = target.url; tab.title = target.title; }
  33  |           break;
  34  |         }
  35  |         case 'spaceCreate': {
  36  |           const next = {id:'space-' + ++sequence, name:command.name};
  37  |           state.spaces.push(next); state.activeSpace=next.id; state.selected=undefined;
  38  |           break;
  39  |         }
  40  |         case 'spaceSwitch': state.activeSpace=command.target; state.selected=state.tabs.find(tab=>tab.space===command.target)?.id; state.split=[]; break;
  41  |         case 'spaceRename': { const space=state.spaces.find(space=>space.id===command.target); if(space) space.name=command.name; break; }
  42  |         case 'spaceDelete': state.spaces=state.spaces.filter(space=>space.id!==command.target); state.activeSpace=state.spaces[0].id; break;
  43  |         case 'groupCreate': state.groups.push({id:'group-'+ ++sequence,space:state.activeSpace,name:command.name,collapsed:false}); break;
  44  |         case 'groupToggle': { const group=state.groups.find(group=>group.id===command.target); if(group) group.collapsed=!group.collapsed; break; }
  45  |         case 'groupRename': { const group=state.groups.find(group=>group.id===command.target); if(group) group.name=command.name; break; }
  46  |         case 'tabGroup': if(target) {target.group=command.target;target.pinned=false;} break;
  47  |         case 'tabSpace': if(target) {target.space=command.target;target.group=undefined;} break;
  48  |         case 'pin': if (target) target.pinned = !target.pinned; break;
  49  |         case 'split': if (target && state.selected) state.split = [state.selected, target.id]; break;
  50  |         case 'unsplit': state.split = []; break;
  51  |         case 'appearance': state.appearance = command.value as Appearance; break;
  52  |       }
  53  |       state.revision++;
  54  |       return Promise.resolve({ id: command.id, state: structuredClone(state) });
  55  |     } } } } });
  56  |   });
  57  |   await page.goto('/');
  58  | }
  59  | 
  60  | test.beforeEach(({ page }) => { page.on('pageerror', (error) => console.error(error.message)); });
  61  | 
  62  | test('missing bridge leaves actions unavailable', async ({ page }) => {
  63  |   await page.goto('/');
  64  |   await expect(page.getByRole('heading', { name: 'Your next idea.' })).toBeVisible();
  65  |   await expect(page.getByRole('button', { name: 'Start private session' }).last()).toBeDisabled();
  66  | });
  67  | 
  68  | test('starts private browsing, submits address, duplicates and closes tabs', async ({ page }) => {
  69  |   await hostStandIn(page);
  70  |   await page.getByRole('button', { name: 'Start private session' }).last().click();
  71  |   await expect(page.getByRole('heading', { name: 'Where to?' })).toBeVisible();
  72  |   await page.getByRole('textbox', { name: 'New tab search' }).fill('example.com');
  73  |   await page.getByRole('button', { name: 'Go', exact: true }).click();
  74  |   await expect(page.getByRole('tab', { name: 'Fixture page' })).toBeVisible();
  75  |   await expect(page.getByRole('textbox', { name: 'Address and search' })).toHaveValue('https://example.com/');
  76  |   await page.getByRole('tab', { name: 'Fixture page' }).click({ button: 'right' });
  77  |   await page.getByRole('button', { name: 'Duplicate tab' }).click();
  78  |   await expect(page.getByRole('tab', { name: 'Fixture page' })).toHaveCount(2);
  79  |   await page.getByRole('button', { name: 'Close Fixture page' }).last().click();
  80  |   await expect(page.getByRole('tab', { name: 'Fixture page' })).toHaveCount(1);
  81  | });
  82  | 
  83  | test('sidebar, command palette focus, appearance and narrow layout', async ({ page }) => {
  84  |   await hostStandIn(page);
  85  |   await page.keyboard.press('Meta+k');
  86  |   const palette = page.getByRole('dialog', { name: 'Browser commands' });
  87  |   await expect(palette.getByRole('textbox')).toBeFocused();
  88  |   await palette.getByRole('textbox').fill('settings');
  89  |   await palette.getByRole('button', { name: 'Open settings' }).click();
> 90  |   await expect(page.getByRole('heading', { name: 'Settings', exact: true })).toBeVisible();
      |                                                                              ^ Error: expect(locator).toBeVisible() failed
  91  |   await page.getByRole('button', { name: 'dark', exact: true }).click();
  92  |   await expect(page.locator('html')).toHaveAttribute('data-theme', 'dark');
  93  |   await page.setViewportSize({ width: 660, height: 470 });
  94  |   await expect(page.getByRole('main')).toBeVisible();
  95  |   expect(await page.locator('.omnibox').evaluate((element) => element.getBoundingClientRect().width)).toBeGreaterThan(110);
  96  |   await page.getByRole('button', { name: 'Hide sidebar' }).click();
  97  |   await expect(page.getByRole('complementary')).toHaveCount(0);
  98  |   await expect(page.getByRole('button', { name: 'Show sidebar' })).toBeVisible();
  99  | });
  100 | 
  101 | test('temporary bookmarks clear at session end; profiles and history stay unavailable', async ({ page }) => {
  102 |   await hostStandIn(page);
  103 |   await page.getByRole('button', { name: 'Start private session' }).last().click();
  104 |   await page.getByRole('button', { name: 'Bookmarks', exact: true }).click();
  105 |   await page.getByRole('button', { name: 'Add bookmark' }).click();
  106 |   await page.getByRole('textbox', { name: 'Bookmark name' }).fill('Reference');
  107 |   await page.getByRole('textbox', { name: 'Bookmark address' }).fill('example.com');
  108 |   await page.getByRole('textbox', { name: 'Bookmark folder' }).fill('Reading');
  109 |   await page.getByRole('button', { name: 'Save bookmark' }).click();
  110 |   await expect(page.getByRole('heading', { name: 'Reading' })).toBeVisible();
  111 |   await page.getByRole('button', { name: 'End session' }).click();
  112 |   await page.getByRole('button', { name: 'Bookmarks', exact: true }).click();
  113 |   await expect(page.getByRole('button', { name: 'Reference', exact: true })).toHaveCount(0);
  114 |   await page.getByRole('button', { name: 'History', exact: true }).click();
  115 |   await expect(page.getByRole('button', { name: 'Clear history' })).toBeDisabled();
  116 |   await page.getByRole('button', { name: 'Profiles', exact: true }).click();
  117 |   await expect(page.getByRole('button', { name: 'Create profile' })).toBeDisabled();
  118 | });
  119 | 
  120 | 
  121 | test('vertical tab pinning, group creation, collapse and contextual assignment', async ({ page }) => {
  122 |   await hostStandIn(page);
  123 |   await page.getByRole('button', { name: 'Start private session' }).last().click();
  124 |   await page.getByRole('button', { name: 'Actions for New tab', exact:true }).click();
  125 |   await page.getByRole('button', { name: 'Pin tab', exact:true }).click();
  126 |   await expect(page.locator('.vertical-tabs .sidebar-label').first()).toHaveText('Pinned');
  127 |   await page.getByRole('button', { name:'Workspace actions' }).click();
  128 |   await page.getByRole('button', { name:'Create tab group',exact:true }).click();
  129 |   await page.getByRole('textbox', { name:'Name',exact:true }).fill('Reading');
  130 |   await page.getByRole('button', {name:'Save',exact:true}).click();
  131 |   await page.getByRole('button', {name:'Actions for New tab',exact:true}).click();
  132 |   await page.getByRole('button', {name:'Move to Reading',exact:true}).click();
  133 |   await expect(page.locator('.tab-group .vertical-tab')).toHaveCount(1);
  134 |   await page.locator('.group-heading > button').first().click();
  135 |   await expect(page.locator('.tab-group .vertical-tab')).toHaveCount(0);
  136 | });
  137 | 
  138 | test('Spaces keep tab organization distinct and empty Spaces can be deleted', async ({ page }) => {
  139 |   await hostStandIn(page);
  140 |   await page.getByRole('button', { name: 'Start private session' }).last().click();
  141 |   await page.getByRole('button', {name:'Create Space',exact:true}).click();
  142 |   await page.getByRole('textbox', {name:'Name',exact:true}).fill('Research');
  143 |   await page.getByRole('button', {name:'Save',exact:true}).click();
  144 |   await expect(page.getByRole('tab')).toHaveCount(0);
  145 |   await page.getByRole('button', {name:'Switch to Personal'}).click();
  146 |   await expect(page.getByRole('tab')).toHaveCount(1);
  147 |   await page.getByRole('button', {name:'Switch to Research'}).click();
  148 |   await page.getByRole('button', {name:'Space actions',exact:true}).click();
  149 |   await page.getByRole('button', {name:'Delete empty Space'}).click();
  150 |   await expect(page.getByRole('button', {name:'Switch to Research'})).toHaveCount(0);
  151 | });
  152 | 
  153 | test('Split commands expose pane controls and command bar searches open tabs', async ({ page }) => {
  154 |   await hostStandIn(page);
  155 |   await page.getByRole('button', { name: 'Start private session' }).last().click();
  156 |   await page.getByRole('button', {name:'Open command palette'}).click();
  157 |   await page.getByRole('dialog').getByRole('button', {name:/^New tab/}).click();
  158 |   await expect(page.getByRole('tab')).toHaveCount(2);
  159 |   await page.getByRole('button', {name:'Add split',exact:true}).click();
  160 |   await expect(page.getByLabel('Split Screen panes')).toBeVisible();
  161 |   await page.getByRole('button', {name:'Exit split',exact:true}).last().click();
  162 |   await expect(page.getByLabel('Split Screen panes')).toHaveCount(0);
  163 |   await page.getByRole('button', {name:'Open command palette'}).click();
  164 |   await page.getByRole('textbox', {name:'Find a command'}).fill('Tab ·');
  165 |   await expect(page.getByRole('dialog').getByRole('button', {name:'Tab · New tab',exact:true})).toHaveCount(2);
  166 | });
  167 | 
  168 | 
  169 | test('tab arrows advance real focus through the rendered tab order', async ({ page }) => {
  170 |   await hostStandIn(page);
  171 |   await page.getByRole('button', { name: 'Start private session' }).last().click();
  172 |   for (let n = 0; n < 2; n++) {
  173 |     await page.getByRole('button', { name: 'Open command palette' }).click();
  174 |     await page.getByRole('dialog', { name: 'Browser commands' }).getByRole('button', { name: /^New tab/ }).click();
  175 |   }
  176 |   const tabs = page.getByRole('tab');
  177 |   await tabs.first().focus();
  178 |   await page.keyboard.press('ArrowDown');
  179 |   await expect(tabs.nth(1)).toBeFocused();
  180 |   await page.keyboard.press('ArrowDown');
  181 |   await expect(tabs.nth(2)).toBeFocused();
  182 | });
  183 | 
  184 | test('workspace editor and action dialog contain focus and cancel with Escape', async ({ page }) => {
  185 |   await hostStandIn(page);
  186 |   await page.getByRole('button', { name: 'Start private session' }).last().click();
  187 |   await page.getByRole('button', { name: 'Workspace actions', exact: true }).click();
  188 |   const actions = page.getByRole('dialog', { name: 'Workspace actions', exact: true });
  189 |   await expect(actions.getByRole('button').first()).toBeFocused();
  190 |   await page.keyboard.press('Escape');
```