// vite.config.ts
import { defineConfig } from 'vite'
import RubyPlugin from 'vite-plugin-ruby'
import vue from '@vitejs/plugin-vue' // Add this

export default defineConfig({
  plugins: [
    RubyPlugin(),
    vue(), // Add this
  ],
})
