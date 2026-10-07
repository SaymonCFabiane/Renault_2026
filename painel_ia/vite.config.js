import react from '@vitejs/plugin-react'
import { defineConfig } from 'vite'

// Porta fixa: a API libera esta origem no CORS (TRACEPRO_CORS_ORIGENS).
export default defineConfig({
  plugins: [react()],
  server: { port: 5174, strictPort: true },
  preview: { port: 5174, strictPort: true },
})
