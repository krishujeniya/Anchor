import { useEffect, useState } from 'react'
import { Activity, Clock, ShieldCheck, Map } from 'lucide-react'
import ReactMarkdown from 'react-markdown'
import './index.css'

function App() {
  const [state, setState] = useState(null)
  const [current, setCurrent] = useState('')
  const [checkpoints, setCheckpoints] = useState([])
  const [graph, setGraph] = useState(null)
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState(null)

  useEffect(() => {
    const fetchData = async () => {
      try {
        const [stateRes, currentRes, cpRes, graphRes] = await Promise.all([
          fetch('/api/state'),
          fetch('/api/current'),
          fetch('/api/checkpoints'),
          fetch('/api/graph')
        ])

        if (!stateRes.ok) throw new Error('API not available. Ensure Vite plugin is configured.')

        const stateData = await stateRes.json()
        const currentData = await currentRes.text()
        const cpData = await cpRes.json()
        const graphData = await graphRes.json()

        setState(stateData)
        setCurrent(currentData)
        setCheckpoints(cpData.sort((a, b) => b.file.localeCompare(a.file)))
        setGraph(graphData)
      } catch (err) {
        setError(err.message)
      } finally {
        setLoading(false)
      }
    }

    fetchData()
    const interval = setInterval(fetchData, 3000) // Poll for real-time updates
    return () => clearInterval(interval)
  }, [])

  if (loading) return <div className="layout" style={{display:'flex', alignItems:'center', justifyContent:'center'}}>Loading ANCHOR state...</div>
  if (error) return <div className="layout" style={{display:'flex', alignItems:'center', justifyContent:'center'}}>Error: {error}</div>

  return (
    <div className="layout">
      <div className="sidebar">
        <div className="glass card">
          <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: '24px' }}>
            <h2>ANCHOR Spine</h2>
            <ShieldCheck size={24} color="var(--success)" />
          </div>
          
          <div style={{ display: 'flex', flexDirection: 'column', gap: '16px' }}>
            <div>
              <div className="text-sm text-secondary">Active Project</div>
              <div style={{ fontSize: '1.25rem', fontWeight: 600 }}>{state.project}</div>
            </div>
            
            <div>
              <div className="text-sm text-secondary">Current Milestone</div>
              <div style={{ display: 'flex', alignItems: 'center', gap: '8px', marginTop: '4px' }}>
                <span className="status-badge">{state.current_milestone || 'IDLE'}</span>
              </div>
            </div>

            <div>
              <div className="text-sm text-secondary">Active Gate</div>
              <div style={{ display: 'flex', alignItems: 'center', gap: '8px', marginTop: '4px' }}>
                <Activity size={16} color="var(--accent)" />
                <span className="status-badge success">{state.current_gate || 'COMPLETED'}</span>
              </div>
            </div>

            <div style={{ display: 'flex', gap: '24px', marginTop: '8px' }}>
              <div>
                <div className="text-sm text-secondary">Iteration</div>
                <div style={{ fontWeight: 600 }}>{state.iteration} / {state.iteration_cap}</div>
              </div>
              <div>
                <div className="text-sm text-secondary">Budget Used</div>
                <div style={{ fontWeight: 600 }}>{state.tokens_used} / {state.token_budget}</div>
              </div>
            </div>
          </div>
        </div>

        <div className="glass card" style={{ flex: 1 }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: '8px', marginBottom: '16px' }}>
            <Clock size={20} color="var(--accent)" />
            <h3>CURRENT.md</h3>
          </div>
          <div className="markdown-body">
            <ReactMarkdown>{current}</ReactMarkdown>
          </div>
        </div>
      </div>

      <div className="main-content">
        <div className="glass card" style={{ flex: 1, overflowY: 'auto' }}>
          <h3>Audit Trail (Checkpoints)</h3>
          <div style={{ marginTop: '24px' }}>
            {checkpoints.length === 0 ? (
              <div className="text-secondary" style={{ textAlign: 'center', padding: '40px 0' }}>
                <div style={{ fontSize: '3rem', marginBottom: '16px' }}>⚓</div>
                <h3>No Checkpoints Yet</h3>
                <p>Start a milestone to see the audit trail here.</p>
              </div>
            ) : (
              checkpoints.map(cp => (
                <div key={cp.file} className="timeline-item">
                  <div style={{ fontWeight: 600, marginBottom: '8px', color: 'var(--accent)' }}>{cp.file}</div>
                  <div className="markdown-body glass" style={{ padding: '16px', background: 'rgba(0,0,0,0.2)' }}>
                    <ReactMarkdown>{cp.content}</ReactMarkdown>
                  </div>
                </div>
              ))
            )}
          </div>
        </div>

        <div className="glass card" style={{ height: '300px', display: 'flex', flexDirection: 'column' }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: '8px', marginBottom: '16px' }}>
            <Map size={20} color="var(--accent)" />
            <h3>Context Graph</h3>
          </div>
          <div style={{ flex: 1, display: 'flex', alignItems: 'center', justifyContent: 'center', border: '1px dashed var(--border-glass)', borderRadius: 'var(--radius)' }}>
            <div className="text-secondary text-sm">
              Graph Visualization: {graph?.nodes?.length || 0} nodes, {graph?.edges?.length || 0} edges
            </div>
          </div>
        </div>
      </div>
    </div>
  )
}

export default App
