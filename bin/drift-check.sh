#!/usr/bin/env bash
# drift-check.sh — ANCHOR Drift Detector
# Compares the repository working tree against the last_known_commit
# to detect out-of-band edits by humans.

set -euo pipefail

PROJECT_ROOT=$(cd "$(dirname "$0")/.." && pwd)
STATE_FILE="${PROJECT_ROOT}/.agents/state/state.json"

echo "🔍 Starting ANCHOR Drift Detection..."

if [ ! -f "$STATE_FILE" ]; then
  echo "  No state.json found. Cannot detect drift."
  exit 0
fi

LAST_COMMIT=$(jq -r '.last_known_commit // empty' "$STATE_FILE" 2>/dev/null || echo "")

if [ -z "$LAST_COMMIT" ]; then
  echo "  No last_known_commit found in state.json. Assuming no drift."
  exit 0
fi

# We want to know if there are changes between LAST_COMMIT and the working tree.
# Note: Since the orchestrator itself might have created new files (like artifacts)
# that are untracked, we should primarily check for modifications to tracked files
# or changes that were explicitly committed.
# The simplest approach:
# `git diff $LAST_COMMIT --name-only` shows differences between that commit and working tree.

if ! git -C "$PROJECT_ROOT" cat-file -t "$LAST_COMMIT" >/dev/null 2>&1; then
  echo "  ⚠️ Warning: last_known_commit ($LAST_COMMIT) is not a valid git object."
  echo "     This might happen if the repo was rebased or squashed. Drift check skipped."
  exit 0
fi

CHANGES=$( { git -C "$PROJECT_ROOT" diff "$LAST_COMMIT" --name-only || true; git -C "$PROJECT_ROOT" ls-files --others --exclude-standard || true; } | grep -v '^\.agents/state/' | sed '/^$/d' || true )

if [ -n "$CHANGES" ]; then
  echo "  ⚠️ DRIFT DETECTED!"
  echo "  The following files have changed since ANCHOR last completed a milestone:"
  echo ""
  echo "$CHANGES" | sed 's/^/    - /'
  echo ""
  echo "RESULT: FAIL (Drift occurred)"
  # We return 1 so scripts like preflight can catch it
  exit 1
else
  echo "  ✅ Working tree is perfectly synced with ANCHOR state."
  echo "RESULT: PASS (No drift)"
  exit 0
fi
