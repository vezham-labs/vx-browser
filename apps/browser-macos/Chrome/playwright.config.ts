import { defineConfig } from '@playwright/test';

export default defineConfig({
  testDir: './tests',
  outputDir: process.env.VEZHAM_UI_EVIDENCE || '../build/playwright',
  testMatch: '*.spec.ts',
  workers: 1,
  timeout: 15000,
  use: { baseURL: 'http://127.0.0.1:17462', viewport: { width: 1080, height: 712 } },
  webServer: {
    command: 'python3 -m http.server 17462 --bind 127.0.0.1 --directory ../build/chrome',
    url: 'http://127.0.0.1:17462',
    reuseExistingServer: false,
  },
});
