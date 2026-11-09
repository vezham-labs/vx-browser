import { expect, test } from '@playwright/test'
import type { Page } from '@playwright/test'

import type { Appearance, BrowserState, Command, Tab } from '../src/bridge'

async function hostStandIn(page: Page, recovery?: BrowserState['recovery']) {
  await page.addInitScript(initialRecovery => {
    const state: BrowserState = {
      revision: 0,
      session: 'inactive',
      recovery: initialRecovery,
      profile: 'unavailable',
      tabs: [],
      appearance: 'system',
      spaces: [{ id: 'personal', name: 'Personal' }],
      activeSpace: 'personal',
      groups: [],
      split: [],
      splitCompact: false,
      mini: false,
      workspaces: [{ id: 'workspace-one', name: 'Personal', empty: true }],
      activeWorkspace: 'workspace-one'
    }
    let sequence = 0
    const addTab = () => {
      const next: Tab = {
        id: 'test-' + ++sequence,
        title: 'New tab',
        space: state.activeSpace,
        pinned: false,
        loading: false,
        progress: 0,
        back: false,
        forward: false,
        connection: 'unknown'
      }
      state.tabs.push(next)
      state.selected = next.id
      return next
    }
    Object.defineProperty(window, 'webkit', {
      value: {
        messageHandlers: {
          browserChrome: {
            postMessage(command: Command & { id: string }) {
              const target =
                'tab' in command
                  ? state.tabs.find(item => item.id === command.tab)
                  : undefined
              switch (command.type) {
                case 'recoverPrivate':
                  if (state.recovery === 'ready') {
                    state.recovery = undefined
                    state.session = 'private'
                    state.sessionID = 'fresh'
                    addTab()
                  }
                  break
                case 'startPrivate':
                  state.session = 'private'
                  state.sessionID = 'private-' + sequence
                  addTab()
                  break
                case 'newTab':
                  addTab()
                  break
                case 'endPrivate':
                  state.session = 'inactive'
                  state.sessionID = undefined
                  state.tabs = []
                  state.selected = undefined
                  break
                case 'close':
                  state.tabs = state.tabs.filter(tab => tab !== target)
                  state.selected = state.tabs.at(-1)?.id
                  if (!state.tabs.length) {
                    state.session = 'inactive'
                    state.sessionID = undefined
                  }
                  break
                case 'activate':
                  state.selected = target?.id
                  break
                case 'navigate':
                  if (target) {
                    target.url = command.url
                    target.title = 'Fixture page'
                    target.back = true
                  }
                  break
                case 'duplicate': {
                  const tab = addTab()
                  if (target) {
                    tab.url = target.url
                    tab.title = target.title
                  }
                  break
                }
                case 'workspaceCreate':
                  state.workspaces?.push({
                    id: 'workspace-' + ++sequence,
                    name: command.name,
                    empty: true
                  })
                  break
                case 'workspaceRename': {
                  const workspace = state.workspaces?.find(
                    item => item.id === command.target
                  )
                  if (workspace) workspace.name = command.name
                  break
                }
                case 'workspaceSwitch':
                  state.activeWorkspace = command.target
                  state.tabs = []
                  state.selected = undefined
                  state.split = []
                  break
                case 'spaceCreate': {
                  const next = { id: 'space-' + ++sequence, name: command.name }
                  state.spaces.push(next)
                  state.activeSpace = next.id
                  state.selected = undefined
                  break
                }
                case 'spaceSwitch':
                  state.activeSpace = command.target
                  state.selected = state.tabs.find(
                    tab => tab.space === command.target
                  )?.id
                  state.split = []
                  break
                case 'spaceRename': {
                  const space = state.spaces.find(
                    space => space.id === command.target
                  )
                  if (space) space.name = command.name
                  break
                }
                case 'spaceDelete':
                  state.spaces = state.spaces.filter(
                    space => space.id !== command.target
                  )
                  state.activeSpace = state.spaces[0].id
                  break
                case 'groupCreate':
                  state.groups.push({
                    id: 'group-' + ++sequence,
                    space: state.activeSpace,
                    name: command.name,
                    collapsed: false
                  })
                  break
                case 'groupToggle': {
                  const group = state.groups.find(
                    group => group.id === command.target
                  )
                  if (group) group.collapsed = !group.collapsed
                  break
                }
                case 'groupRename': {
                  const group = state.groups.find(
                    group => group.id === command.target
                  )
                  if (group) group.name = command.name
                  break
                }
                case 'tabGroup':
                  if (target) {
                    target.group = command.target
                    target.pinned = false
                  }
                  break
                case 'tabSpace':
                  if (target) {
                    target.space = command.target
                    target.group = undefined
                  }
                  break
                case 'pin':
                  if (target) target.pinned = !target.pinned
                  break
                case 'split':
                  if (target && state.selected)
                    state.split = [state.selected, target.id]
                  break
                case 'unsplit':
                  state.split = []
                  break
                case 'appearance':
                  state.appearance = command.value as Appearance
                  break
              }
              state.revision++
              return Promise.resolve({
                id: command.id,
                state: structuredClone(state)
              })
            }
          }
        }
      }
    })
  }, recovery)
  await page.goto('/')
}

test.beforeEach(({ page }) => {
  page.on('pageerror', error => console.error(error.message))
})

test('missing bridge leaves actions unavailable', async ({ page }) => {
  await page.goto('/')
  await expect(
    page.getByRole('heading', { name: 'Your next idea.' })
  ).toBeVisible()
  await expect(
    page.getByRole('button', { name: 'Start private session' }).last()
  ).toBeDisabled()
})

test('starts private browsing, submits address, duplicates and closes tabs', async ({
  page
}) => {
  await hostStandIn(page)
  await page
    .getByRole('button', { name: 'Start private session' })
    .last()
    .click()
  await expect(page.getByRole('heading', { name: 'Where to?' })).toBeVisible()
  await page
    .getByRole('textbox', { name: 'New tab search' })
    .fill('example.com')
  await page.getByRole('button', { name: 'Go', exact: true }).click()
  await expect(page.getByRole('tab', { name: 'Fixture page' })).toBeVisible()
  await expect(
    page.getByRole('textbox', { name: 'Address and search' })
  ).toHaveValue('https://example.com/')
  await page
    .getByRole('tab', { name: 'Fixture page' })
    .click({ button: 'right' })
  await page.getByRole('button', { name: 'Duplicate tab' }).click()
  await expect(page.getByRole('tab', { name: 'Fixture page' })).toHaveCount(2)
  await page.getByRole('button', { name: 'Close Fixture page' }).last().click()
  await expect(page.getByRole('tab', { name: 'Fixture page' })).toHaveCount(1)
})

test('sidebar, command palette focus, appearance and narrow layout', async ({
  page
}) => {
  await hostStandIn(page)
  await page.keyboard.press('Meta+k')
  const palette = page.getByRole('dialog', { name: 'Browser commands' })
  await expect(palette.getByRole('textbox')).toBeFocused()
  await palette.getByRole('textbox').fill('settings')
  await palette.getByRole('button', { name: 'Open settings' }).click()
  await expect(
    page.getByRole('heading', { name: 'Settings', exact: true })
  ).toBeVisible()
  await page.getByRole('button', { name: 'dark', exact: true }).click()
  await expect(page.locator('html')).toHaveAttribute('data-theme', 'dark')
  await page.setViewportSize({ width: 660, height: 470 })
  await expect(page.getByRole('main')).toBeVisible()
  expect(
    await page
      .locator('.omnibox')
      .evaluate(element => element.getBoundingClientRect().width)
  ).toBeGreaterThan(110)
  await page.getByRole('button', { name: 'Hide sidebar' }).click()
  await expect(page.getByRole('complementary')).toHaveCount(0)
  await expect(page.getByRole('button', { name: 'Show sidebar' })).toBeVisible()
})

test('temporary bookmarks clear at session end; profiles and history stay unavailable', async ({
  page
}) => {
  await hostStandIn(page)
  await page
    .getByRole('button', { name: 'Start private session' })
    .last()
    .click()
  await page.getByRole('button', { name: 'Bookmarks', exact: true }).click()
  await page.getByRole('button', { name: 'Add bookmark' }).click()
  await page.getByRole('textbox', { name: 'Bookmark name' }).fill('Reference')
  await page
    .getByRole('textbox', { name: 'Bookmark address' })
    .fill('example.com')
  await page.getByRole('textbox', { name: 'Bookmark folder' }).fill('Reading')
  await page.getByRole('button', { name: 'Save bookmark' }).click()
  await expect(page.getByRole('heading', { name: 'Reading' })).toBeVisible()
  await page.getByRole('button', { name: 'End session' }).click()
  await page.getByRole('button', { name: 'Bookmarks', exact: true }).click()
  await expect(
    page.getByRole('button', { name: 'Reference', exact: true })
  ).toHaveCount(0)
  await page.getByRole('button', { name: 'History', exact: true }).click()
  await expect(
    page.getByRole('button', { name: 'Clear history' })
  ).toBeDisabled()
  await page.getByRole('button', { name: 'Profiles', exact: true }).click()
  await expect(
    page.getByRole('button', { name: 'Create profile' })
  ).toBeDisabled()
})

test('vertical tab pinning, group creation, collapse and contextual assignment', async ({
  page
}) => {
  await hostStandIn(page)
  await page
    .getByRole('button', { name: 'Start private session' })
    .last()
    .click()
  await page
    .getByRole('button', { name: 'Actions for New tab', exact: true })
    .click()
  await page.getByRole('button', { name: 'Pin tab', exact: true }).click()
  await expect(
    page.locator('.vertical-tabs .sidebar-label').first()
  ).toHaveText('Pinned')
  await page.getByRole('button', { name: 'Workspace actions' }).click()
  await page
    .getByRole('button', { name: 'Create tab group', exact: true })
    .click()
  await page.getByRole('textbox', { name: 'Name', exact: true }).fill('Reading')
  await page.getByRole('button', { name: 'Save', exact: true }).click()
  await page
    .getByRole('button', { name: 'Actions for New tab', exact: true })
    .click()
  await page
    .getByRole('button', { name: 'Move to Reading', exact: true })
    .click()
  await expect(page.locator('.tab-group .vertical-tab')).toHaveCount(1)
  await page.locator('.group-heading > button').first().click()
  await expect(page.locator('.tab-group .vertical-tab')).toHaveCount(0)
})

test('Spaces keep tab organization distinct and empty Spaces can be deleted', async ({
  page
}) => {
  await hostStandIn(page)
  await page
    .getByRole('button', { name: 'Start private session' })
    .last()
    .click()
  await page.getByRole('button', { name: 'Create Space', exact: true }).click()
  await page
    .getByRole('textbox', { name: 'Name', exact: true })
    .fill('Research')
  await page.getByRole('button', { name: 'Save', exact: true }).click()
  await expect(page.getByRole('tab')).toHaveCount(0)
  await page.getByRole('button', { name: 'Switch to Personal' }).click()
  await expect(page.getByRole('tab')).toHaveCount(1)
  await page.getByRole('button', { name: 'Switch to Research' }).click()
  await page.getByRole('button', { name: 'Space actions', exact: true }).click()
  await page.getByRole('button', { name: 'Delete empty Space' }).click()
  await expect(
    page.getByRole('button', { name: 'Switch to Research' })
  ).toHaveCount(0)
})

test('Split commands expose pane controls and command bar searches open tabs', async ({
  page
}) => {
  await hostStandIn(page)
  await page
    .getByRole('button', { name: 'Start private session' })
    .last()
    .click()
  await page.getByRole('button', { name: 'Open command palette' }).click()
  await page
    .getByRole('dialog')
    .getByRole('button', { name: /^New tab/ })
    .click()
  await expect(page.getByRole('tab')).toHaveCount(2)
  await page.getByRole('button', { name: 'Add split', exact: true }).click()
  await expect(page.getByLabel('Split Screen panes')).toBeVisible()
  await page
    .getByRole('button', { name: 'Exit split', exact: true })
    .last()
    .click()
  await expect(page.getByLabel('Split Screen panes')).toHaveCount(0)
  await page.getByRole('button', { name: 'Open command palette' }).click()
  await page.getByRole('textbox', { name: 'Find a command' }).fill('Tab ·')
  await expect(
    page
      .getByRole('dialog')
      .getByRole('button', { name: 'Tab · New tab', exact: true })
  ).toHaveCount(2)
})

test('tab arrows advance real focus through the rendered tab order', async ({
  page
}) => {
  await hostStandIn(page)
  await page
    .getByRole('button', { name: 'Start private session' })
    .last()
    .click()
  for (let n = 0; n < 2; n++) {
    await page.getByRole('button', { name: 'Open command palette' }).click()
    await page
      .getByRole('dialog', { name: 'Browser commands' })
      .getByRole('button', { name: /^New tab/ })
      .click()
  }
  const tabs = page.getByRole('tab')
  await tabs.first().focus()
  await page.keyboard.press('ArrowDown')
  await expect(tabs.nth(1)).toBeFocused()
  await page.keyboard.press('ArrowDown')
  await expect(tabs.nth(2)).toBeFocused()
})

test('workspace editor and action dialog contain focus and cancel with Escape', async ({
  page
}) => {
  await hostStandIn(page)
  await page
    .getByRole('button', { name: 'Start private session' })
    .last()
    .click()
  await page
    .getByRole('button', { name: 'Workspace actions', exact: true })
    .click()
  const actions = page.getByRole('dialog', {
    name: 'Workspace actions',
    exact: true
  })
  await expect(actions.getByRole('button').first()).toBeFocused()
  await page.keyboard.press('Escape')
  await expect(actions).toHaveCount(0)
  await expect(
    page.getByRole('button', { name: 'Workspace actions', exact: true })
  ).toBeFocused()
  await page.getByRole('button', { name: 'Create Space', exact: true }).click()
  const editor = page.getByRole('dialog', {
    name: 'Organize workspace',
    exact: true
  })
  await expect(editor.getByRole('textbox')).toBeFocused()
  for (let n = 0; n < 6; n++) {
    await page.keyboard.press('Tab')
    expect(
      await editor.evaluate(el => el.contains(document.activeElement))
    ).toBe(true)
  }
  await page.keyboard.press('Escape')
  await expect(editor).toHaveCount(0)
  await expect(
    page.getByRole('button', { name: 'Create Space', exact: true })
  ).toBeFocused()
})

test('navigation actions stay inside the active dialog', async ({ page }) => {
  await hostStandIn(page)
  await page
    .getByRole('button', { name: 'Start private session' })
    .last()
    .click()
  await page
    .getByRole('button', { name: 'Navigation actions', exact: true })
    .click()
  const dialog = page.getByRole('dialog', {
    name: 'Workspace actions',
    exact: true
  })
  await expect(
    dialog.getByRole('button', { name: 'Settings', exact: true })
  ).toBeVisible()
  await dialog.getByRole('button', { name: 'Settings', exact: true }).click()
  await expect(
    page.getByRole('heading', { name: 'Settings', exact: true })
  ).toBeVisible()
})

test('command focus-address intent survives dialog dismissal', async ({
  page
}) => {
  await hostStandIn(page)
  await page
    .getByRole('button', { name: 'Start private session' })
    .last()
    .click()
  await page
    .getByRole('button', { name: 'Open command palette', exact: true })
    .click()
  await page
    .getByRole('textbox', { name: 'Find a command' })
    .fill('Focus address')
  await page
    .getByRole('dialog')
    .getByRole('button', { name: /^Focus address/ })
    .click()
  await expect(
    page.getByRole('textbox', { name: 'Address and search' })
  ).toBeFocused()
})

test('native-selected tab changes dismiss an unfinished address draft', async ({
  page
}) => {
  await hostStandIn(page)
  await page
    .getByRole('button', { name: 'Start private session' })
    .last()
    .click()
  await page
    .getByRole('textbox', { name: 'Address and search' })
    .fill('unfinished.invalid')
  await page.evaluate(async () => {
    const host = window as Window & {
      webkit: {
        messageHandlers: {
          browserChrome: { postMessage(value: object): Promise<unknown> }
        }
      }
    }
    await host.webkit.messageHandlers.browserChrome.postMessage({
      id: 'external-selection-fixture',
      version: 1,
      type: 'newTab'
    })
  })
  await expect(
    page.getByRole('textbox', { name: 'Address and search' })
  ).toHaveValue('')
})

test('recovery action appears only after the host confirms retirement', async ({
  page
}) => {
  await hostStandIn(page, 'ready')
  await expect(page.getByRole('status')).toContainText('Pages will start blank')
  await page.getByRole('button', { name: 'Restore private workspace' }).click()
  await expect(page.getByRole('tab', { name: 'New tab' })).toBeVisible()
  await expect(
    page.getByRole('button', { name: 'Restore private workspace' })
  ).toHaveCount(0)
})

test('unconfirmed retirement keeps the workspace unavailable', async ({
  page
}) => {
  await hostStandIn(page, 'failed')
  await expect(
    page.getByRole('heading', { name: 'Private workspace unavailable' })
  ).toBeVisible()
  await expect(
    page.getByRole('button', { name: 'Restore private workspace' })
  ).toHaveCount(0)
  await expect(
    page.getByRole('textbox', { name: 'Address and search' })
  ).toHaveCount(0)
})

test('workspace commands create and select a named workspace', async ({
  page
}) => {
  await hostStandIn(page)
  await page.getByRole('button', { name: 'Start private session ⌘T' }).click()
  await page.getByRole('button', { name: 'Open command palette' }).click()
  let palette = page.getByRole('dialog', { name: 'Browser commands' })
  await palette.getByRole('textbox').fill('Create workspace')
  await palette
    .getByRole('button', { name: 'Create workspace', exact: true })
    .click()
  const editor = page.getByRole('dialog', { name: 'Organize workspace' })
  await editor.getByRole('textbox', { name: 'Name' }).fill('Research')
  await editor.getByRole('button', { name: 'Save', exact: true }).click()
  await page.getByRole('button', { name: 'Open command palette' }).click()
  palette = page.getByRole('dialog', { name: 'Browser commands' })
  await palette.getByRole('textbox').fill('Workspace · Research')
  await palette
    .getByRole('button', { name: 'Workspace · Research', exact: true })
    .click()
  await expect(page.locator('.session-tag')).toHaveText('Research')
})

test('Mini requires preview confirmation and exposes a cancelled handoff', async ({
  page
}) => {
  await page.addInitScript(() => {
    let revision = 0
    const calls: object[] = []
    const state = {
      session: 'private',
      profile: 'unavailable',
      sessionID: 'mini',
      mini: true,
      miniEligible: true,
      appearance: 'system',
      spaces: [],
      groups: [],
      activeSpace: '',
      split: [],
      splitCompact: false,
      selected: 'one',
      tabs: [
        {
          id: 'one',
          title: 'Fixture',
          url: 'https://example.com/',
          pinned: false,
          space: '',
          loading: false,
          progress: 1,
          back: false,
          forward: false,
          connection: 'encrypted'
        }
      ]
    }
    Object.defineProperty(window, '__handoffCalls', { value: calls })
    Object.defineProperty(window, 'webkit', {
      value: {
        messageHandlers: {
          browserChrome: {
            postMessage(command: {
              type: string
              id: string
              target?: string
            }) {
              calls.push(command)
              const miniPreview =
                command.type === 'miniTransferPreview'
                  ? {
                      token: 'confirmed-token',
                      url: 'https://example.com/',
                      workspace: 'Research',
                      space: 'Writing'
                    }
                  : undefined
              const error =
                command.type === 'miniTransfer'
                  ? 'transferUnconfirmed'
                  : undefined
              return Promise.resolve({
                id: command.id,
                state: { ...state, revision: ++revision },
                miniPreview,
                error
              })
            }
          }
        }
      }
    })
  })
  await page.goto('/')
  await page.getByRole('button', { name: 'Open in workspace' }).click()
  const preview = page.getByRole('region', {
    name: 'Confirm workspace destination'
  })
  await expect(preview).toContainText('Research / Writing')
  await preview.getByRole('button', { name: 'Cancel', exact: true }).click()
  await expect(preview).toHaveCount(0)
  await page.getByRole('button', { name: 'Open in workspace' }).click()
  await preview.getByRole('button', { name: 'Open link', exact: true }).click()
  await expect(page.locator('.status')).toContainText(
    'The destination did not confirm this page'
  )
  const transfer = await page.evaluate(() =>
    (
      window as Window & { __handoffCalls: { type: string; target?: string }[] }
    ).__handoffCalls.filter(call => call.type === 'miniTransfer')
  )
  expect(transfer).toHaveLength(1)
  expect(transfer[0].target).toBe('confirmed-token')
})
