import { fileURLToPath } from 'node:url'
import { defineConfig, mergeConfig } from 'vite'
import sharedConfig from './vite.config.ts'

// Separate entry/build until the team integrates its shared application shell.
export default mergeConfig(sharedConfig, defineConfig({
  build: {
    outDir: 'dist/catalogue',
    rollupOptions: {
      input: fileURLToPath(new URL('./catalogue.html', import.meta.url)),
    },
  },
}))
