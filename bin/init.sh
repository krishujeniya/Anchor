#!/usr/bin/env bash

# ANCHOR Project Initialization Script
# This script resets the ANCHOR state to a clean slate, removing all development
# history, checkpoints, and graph data so you can start a fresh project.

set -e

PROJECT_ROOT=$(cd "$(dirname "$0")/.." && pwd)
AGENTS_DIR="${PROJECT_ROOT}/.agents"

echo "⚓ Initializing fresh ANCHOR project..."

if ! command -v jq >/dev/null 2>&1; then
  echo "❌ Error: 'jq' is not installed. ANCHOR requires jq to parse state."
  exit 1
fi

# 0. Ensure config.json exists
if [ ! -f "${AGENTS_DIR}/config.json" ]; then
  cat << EOF > "${AGENTS_DIR}/config.json"
{
  "linked_repos": []
}
EOF
  echo "  - Created default config.json"
else
  echo "  - Preserved existing config.json"
fi

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
  "last_updated": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "last_known_commit": "$(git rev-parse HEAD 2>/dev/null || echo '')"
}
EOF

# 1.5 Extract Skill Versions
SKILL_VERSIONS="{}"
for skill_md in "${AGENTS_DIR}/skills"/*/SKILL.md; do
  if [ -f "$skill_md" ]; then
    skill_name=$(awk '/^name:/{print $2; exit}' "$skill_md")
    skill_version=$(awk '/^version:/{print $2; exit}' "$skill_md")
    if [ -n "$skill_name" ] && [ -n "$skill_version" ]; then
      SKILL_VERSIONS=$(echo "$SKILL_VERSIONS" | jq --arg k "$skill_name" --arg v "$skill_version" '.[$k] = $v')
    fi
  fi
done
jq --argjson sv "$SKILL_VERSIONS" '.skill_versions = $sv' "${AGENTS_DIR}/state/state.json" > "${AGENTS_DIR}/state/state.json.tmp"
mv "${AGENTS_DIR}/state/state.json.tmp" "${AGENTS_DIR}/state/state.json"

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

# 4. Archive Decisions / Drafts
DECISIONS_ARCHIVE="${AGENTS_DIR}/state/decisions/archive/${TIMESTAMP}"
if [ -n "$(find "${AGENTS_DIR}/state/decisions" -maxdepth 1 -type f -print -quit)" ]; then
  mkdir -p "$DECISIONS_ARCHIVE"
  find "${AGENTS_DIR}/state/decisions" -maxdepth 1 -type f -exec mv {} "$DECISIONS_ARCHIVE/" \;
  echo "  - Archived decisions to decisions/archive/${TIMESTAMP}/"
else
  echo "  - No decisions to archive"
fi
mkdir -p "${AGENTS_DIR}/state/decisions"
touch "${AGENTS_DIR}/state/decisions/.gitkeep"

# 5. Clear Context Graph
echo '{"nodes": [], "edges": [], "invariants": []}' > "${AGENTS_DIR}/state/context-graph.json"
echo "  - Cleared context-graph.json"

# 6. Archive Telemetry
TELEMETRY_ARCHIVE="${AGENTS_DIR}/state/telemetry/archive/${TIMESTAMP}"
mkdir -p "$TELEMETRY_ARCHIVE"

if [ -f "${AGENTS_DIR}/state/telemetry.jsonl" ]; then
  cp "${AGENTS_DIR}/state/telemetry.jsonl" "${TELEMETRY_ARCHIVE}/" || true
  rm "${AGENTS_DIR}/state/telemetry.jsonl"
  echo "  - Archived telemetry to telemetry/archive/${TIMESTAMP}/"
else
  echo "  - No telemetry to archive"
fi
touch "${AGENTS_DIR}/state/telemetry.jsonl"
echo "  - Reset telemetry.jsonl"

echo ""
echo "✅ ANCHOR is ready. You have a clean slate!"
