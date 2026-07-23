import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'
import fs from 'fs'
import path from 'path'

const agentsPath = path.resolve(__dirname, '../.agents')

const anchorApiPlugin = () => ({
  name: 'anchor-api',
  configureServer(server) {
    server.middlewares.use('/api/state', (req, res) => {
      res.setHeader('Content-Type', 'application/json')
      try {
        const state = fs.readFileSync(path.join(agentsPath, 'state/state.json'), 'utf-8')
        res.end(state)
      } catch (e) {
        res.statusCode = 500
        res.end(JSON.stringify({ error: e.message }))
      }
    })
    
    server.middlewares.use('/api/current', (req, res) => {
      res.setHeader('Content-Type', 'text/plain')
      try {
        const current = fs.readFileSync(path.join(agentsPath, 'state/CURRENT.md'), 'utf-8')
        res.end(current)
      } catch (e) {
        res.statusCode = 500
        res.end(e.message)
      }
    })
    
    server.middlewares.use('/api/checkpoints', (req, res) => {
      res.setHeader('Content-Type', 'application/json')
      try {
        const cpPath = path.join(agentsPath, 'state/checkpoints')
        const files = fs.readdirSync(cpPath).filter(f => f.endsWith('.md') && f !== '.gitkeep')
        const checkpoints = files.map(file => {
          const content = fs.readFileSync(path.join(cpPath, file), 'utf-8')
          return { file, content }
        })
        res.end(JSON.stringify(checkpoints))
      } catch (e) {
        res.statusCode = 500
        res.end(JSON.stringify({ error: e.message }))
      }
    })

    server.middlewares.use('/api/graph', (req, res) => {
      res.setHeader('Content-Type', 'application/json')
      try {
        const graph = fs.readFileSync(path.join(agentsPath, 'state/context-graph.json'), 'utf-8')
        res.end(graph)
      } catch (e) {
        res.statusCode = 500
        res.end(JSON.stringify({ error: e.message }))
      }
    })
  }
})

// https://vite.dev/config/
export default defineConfig({
  plugins: [react(), anchorApiPlugin()],
})
