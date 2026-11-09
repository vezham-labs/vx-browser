import { test, expect } from '@playwright/test';
import type { Page } from '@playwright/test';
import type { Appearance, BrowserState, Command, Tab } from '../src/bridge';

async function hostStandIn(page: Page) {
  await page.addInitScript(() => {
    const state: BrowserState = { revision: 0, session: 'inactive', profile: 'unavailable', tabs: [], appearance: 'system' };
    let sequence = 0;
    const addTab = () => {
      const next: Tab = { id: 'test-' + ++sequence, title: 'New tab', loading: false, progress: 0, back: false, forward: false, connection: 'unknown' };
      state.tabs.push(next);
      state.selected = next.id;
      return next;
    };
    Object.defineProperty(window, 'webkit', { value: { messageHandlers: { browserChrome: { postMessage(command: Command & { id: string }) {
      const target = 'tab' in command ? state.tabs.find((item) => item.id === command.tab) : undefined;
      switch (command.type) {
        case 'startPrivate': state.session = 'private'; state.sessionID = 'private-' + sequence; addTab(); break;
        case 'newTab': addTab(); break;
        case 'endPrivate': state.session = 'inactive'; state.sessionID = undefined; state.tabs = []; state.selected = undefined; break;
        case 'close':
          state.tabs = state.tabs.filter((tab) => tab !== target);
          state.selected = state.tabs.at(-1)?.id;
          if (!state.tabs.length) { state.session = 'inactive'; state.sessionID = undefined; }
          break;
        case 'activate': state.selected = target?.id; break;
        case 'navigate':
          if (target) { target.url = command.url; target.title = 'Fixture page'; target.back = true; }
          break;
        case 'duplicate': {
          const tab = addTab();
          if (target) { tab.url = target.url; tab.title = target.title; }
          break;
        }
        case 'appearance': state.appearance = command.value as Appearance; break;
      }
      state.revision++;
      return Promise.resolve({ id: command.id, state: structuredClone(state) });
    } } } } });
  });
  await page.goto('/');
}

test.beforeEach(({ page }) => { page.on('pageerror', (error) => console.error(error.message)); });

test('missing bridge leaves actions unavailable', async ({ page }) => {
  await page.goto('/');
  await expect(page.getByRole('heading', { name: 'A little room to explore.' })).toBeVisible();
  await expect(page.getByRole('button', { name: 'Start private session' }).last()).toBeDisabled();
});

test('starts private browsing, submits address, duplicates and closes tabs', async ({ page }) => {
  await hostStandIn(page);
  await page.getByRole('button', { name: 'Start private session' }).last().click();
  await expect(page.getByRole('heading', { name: 'Where to?' })).toBeVisible();
  await page.getByRole('textbox', { name: 'New tab search' }).fill('example.com');
  await page.getByRole('button', { name: 'Go', exact: true }).click();
  await expect(page.getByRole('tab', { name: 'Fixture page' })).toBeVisible();
  await expect(page.getByRole('textbox', { name: 'Address and search' })).toHaveValue('https://example.com/');
  await page.getByRole('tab', { name: 'Fixture page' }).click({ button: 'right' });
  await page.getByRole('button', { name: 'Duplicate tab' }).click();
  await expect(page.getByRole('tab', { name: 'Fixture page' })).toHaveCount(2);
  await page.getByRole('button', { name: 'Close Fixture page' }).last().click();
  await expect(page.getByRole('tab', { name: 'Fixture page' })).toHaveCount(1);
});

test('sidebar, command palette focus, appearance and narrow layout', async ({ page }) => {
  await hostStandIn(page);
  await page.keyboard.press('Meta+k');
  const palette = page.getByRole('dialog', { name: 'Browser commands' });
  await expect(palette.getByRole('textbox')).toBeFocused();
  await palette.getByRole('textbox').fill('settings');
  await palette.getByRole('button', { name: 'Open settings' }).click();
  await expect(page.getByRole('heading', { name: 'Settings', exact: true })).toBeVisible();
  await page.getByRole('button', { name: 'dark', exact: true }).click();
  await expect(page.locator('html')).toHaveAttribute('data-theme', 'dark');
  await page.setViewportSize({ width: 660, height: 470 });
  await expect(page.getByRole('main')).toBeVisible();
  expect(await page.locator('.omnibox').evaluate((element) => element.getBoundingClientRect().width)).toBeGreaterThan(220);
  await page.getByRole('button', { name: 'Hide sidebar' }).click();
  await expect(page.getByRole('complementary')).toHaveCount(0);
  await expect(page.getByRole('button', { name: 'Show sidebar' })).toBeVisible();
});

test('temporary bookmarks clear at session end; profiles and history stay unavailable', async ({ page }) => {
  await hostStandIn(page);
  await page.getByRole('button', { name: 'Start private session' }).last().click();
  await page.getByRole('button', { name: 'Bookmarks', exact: true }).click();
  await page.getByRole('button', { name: 'Add bookmark' }).click();
  await page.getByRole('textbox', { name: 'Bookmark name' }).fill('Reference');
  await page.getByRole('textbox', { name: 'Bookmark address' }).fill('example.com');
  await page.getByRole('textbox', { name: 'Bookmark folder' }).fill('Reading');
  await page.getByRole('button', { name: 'Save bookmark' }).click();
  await expect(page.getByRole('heading', { name: 'Reading' })).toBeVisible();
  await page.getByRole('button', { name: 'End session' }).click();
  await page.getByRole('button', { name: 'Bookmarks', exact: true }).click();
  await expect(page.getByRole('button', { name: 'Reference', exact: true })).toHaveCount(0);
  await page.getByRole('button', { name: 'History', exact: true }).click();
  await expect(page.getByRole('button', { name: 'Clear history' })).toBeDisabled();
  await page.getByRole('button', { name: 'Profiles', exact: true }).click();
  await expect(page.getByRole('button', { name: 'Create profile' })).toBeDisabled();
});
