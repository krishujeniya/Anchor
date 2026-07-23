#!/usr/bin/env bash
# rollback.sh — ANCHOR Rollback Mechanism
# Reverts the repository to the last_known_commit, destroying any
# half-finished agent work. Refuses to run if human drift is detected.

set -euo pipefail

PROJECT_ROOT=$(cd "$(dirname "$0")/.." && pwd)
STATE_FILE="${PROJECT_ROOT}/.agents/state/state.json"
CURRENT_FILE="${PROJECT_ROOT}/.agents/state/CURRENT.md"

echo "⏪ Starting ANCHOR Rollback..."

if [ ! -f "$STATE_FILE" ]; then
  echo "❌ No state.json found. Cannot rollback."
  exit 1
fi

LAST_COMMIT=$(jq -r '.last_known_commit // empty' "$STATE_FILE" 2>/dev/null || echo "")

if [ -z "$LAST_COMMIT" ]; then
  echo "❌ No last_known_commit found in state.json. Cannot rollback safely."
  exit 1
fi

if ! git -C "$PROJECT_ROOT" cat-file -t "$LAST_COMMIT" >/dev/null 2>&1; then
  echo "❌ last_known_commit ($LAST_COMMIT) is not a valid git object."
  exit 1
fi

# Step 1: Safety Check via drift-check.sh
echo "  - Checking for out-of-band human drift..."
if ! bash "${PROJECT_ROOT}/bin/drift-check.sh" > /dev/null 2>&1; then
  echo "❌ ROLLBACK ABORTED: Human drift detected."
  echo "   Modifications have been made since the last milestone completed."
  echo "   Rolling back would destroy that work. Please resolve manually."
  exit 1
fi

# Step 2: Rollback
echo "  - Drift check passed. No human edits detected."
echo "  - Reverting repository to $LAST_COMMIT..."
git -C "$PROJECT_ROOT" reset --hard "$LAST_COMMIT" > /dev/null
git -C "$PROJECT_ROOT" clean -fd > /dev/null
echo "  - Repository restored."

# Step 3: State Reset
echo "  - Resetting ANCHOR state to IDLE..."
jq '.current_gate = null | .current_milestone = null | .iteration = 0 | .tokens_used = 0 | .no_progress_strikes = 0' "$STATE_FILE" > "$STATE_FILE.tmp"
mv "$STATE_FILE.tmp" "$STATE_FILE"

cat << 'EOF' > "$CURRENT_FILE"
# CURRENT
- active_gate: IDLE
- target: none
- iteration: 0/10
- last_gate_result: Milestone rolled back
- last_action: rollback
- next_action: wait for new task
- open_questions: none
EOF

echo "✅ Rollback complete. ANCHOR is back to a clean slate."
