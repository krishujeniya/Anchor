#!/usr/bin/env bash

# ANCHOR Project Initialization Script
# This script resets the ANCHOR state to a clean slate, removing all development
# history, checkpoints, and graph data so you can start a fresh project.

set -e

PROJECT_ROOT=$(cd "$(dirname "$0")/.." && pwd)
AGENTS_DIR="${PROJECT_ROOT}/.agents"

echo "⚓ Initializing fresh ANCHOR project..."

# 1. Reset state.json
cat << EOF > "${AGENTS_DIR}/state/state.json"
{
  "project": "New ANCHOR Project",
  "current_gate": null,
  "current_milestone": null,
  "iteration": 0,
  "iteration_cap": 10,
  "token_budget": 50000,
  "tokens_used": 0,
  "no_progress_strikes": 0,
  "hitl_approvals": {},
  "last_updated": "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
}
EOF
echo "  - Reset state.json"

# 2. Reset CURRENT.md
cat << 'EOF' > "${AGENTS_DIR}/state/CURRENT.md"
# CURRENT
- active_gate: IDLE
- target: none
- iteration: 0/10
- last_gate_result: Project initialized
- last_action: reset state to idle
- next_action: wait for new task
- open_questions: none
EOF
echo "  - Reset CURRENT.md"

# 3. Archive Checkpoints (but keep .gitkeep)
TIMESTAMP=$(date -u +%Y%m%d%H%M%S)
ARCHIVE_DIR="${AGENTS_DIR}/state/checkpoints/archive/${TIMESTAMP}"
if [ -n "$(find "${AGENTS_DIR}/state/checkpoints" -maxdepth 1 -name '*.md' -print -quit)" ]; then
  mkdir -p "$ARCHIVE_DIR"
  mv "${AGENTS_DIR}/state/checkpoints/"*.md "$ARCHIVE_DIR/"
  echo "  - Archived checkpoints to archive/${TIMESTAMP}/"
else
  echo "  - No checkpoints to archive"
fi

# 4. Clear Decisions / Drafts
find "${AGENTS_DIR}/state/decisions" -type f -name "*.sh" -delete
find "${AGENTS_DIR}/state/decisions" -type f -name "*.md" -delete
echo "  - Cleared decisions/"

# 5. Clear Context Graph
echo '{"nodes": [], "edges": [], "invariants": []}' > "${AGENTS_DIR}/state/context-graph.json"
echo "  - Cleared context-graph.json"

echo ""
echo "✅ ANCHOR is ready. You have a clean slate!"
