import { defineConfig } from 'vite';
import tailwindcss from '@tailwindcss/vite';
import { fileURLToPath } from 'node:url';

export default defineConfig({
  plugins: [tailwindcss()],
  define: { "process.env.NODE_ENV": JSON.stringify("production") },
  build: {
    lib: {
      entry: fileURLToPath(new URL('./src/main.tsx', import.meta.url)),
      formats: ['iife'],
      name: 'VezhamChrome',
      fileName: () => 'chrome.js',
      cssFileName: 'chrome',
    },
    sourcemap: false,
  },
});
