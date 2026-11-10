import tailwindcss from '@tailwindcss/vite'
import { fileURLToPath } from 'node:url'
import { defineConfig } from 'vite'

export default defineConfig({
  plugins: [tailwindcss()],
  define: { 'process.env.NODE_ENV': JSON.stringify('production') },
  // vx-bot/NOTE: The bundled shell uses production React even when Nx inherits NODE_ENV=development.
  oxc: { jsx: { development: false } },
  build: {
    lib: {
      entry: fileURLToPath(new URL('./src/main.tsx', import.meta.url)),
      formats: ['iife'],
      name: 'VezhamChrome',
      fileName: () => 'chrome.js',
      cssFileName: 'chrome'
    },
    sourcemap: false
  }
})
