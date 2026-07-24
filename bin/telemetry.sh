#!/usr/bin/env bash
# telemetry.sh — ANCHOR Telemetry Logger
# Appends milestone metrics to an append-only JSONL log.
# Usage: bash bin/telemetry.sh log <STATUS>
# Example: bash bin/telemetry.sh log COMPLETE

set -euo pipefail

if [ "${1:-}" != "log" ] || [ -z "${2:-}" ]; then
  echo "Usage: $0 log <STATUS>"
  exit 1
fi

STATUS="$2"
PROJECT_ROOT=$(cd "$(dirname "$0")/.." && pwd)
STATE_FILE="${PROJECT_ROOT}/.agents/state/state.json"
TELEMETRY_LOG="${PROJECT_ROOT}/.agents/state/telemetry.jsonl"

if [ ! -f "$STATE_FILE" ]; then
  echo "No state.json found. Cannot log telemetry."
  exit 0
fi

# Ensure log file exists
touch "$TELEMETRY_LOG"

# Extract fields
MILESTONE=$(jq -r '.current_milestone // "unknown"' "$STATE_FILE" 2>/dev/null)
ITERATION=$(jq -r '.iteration // 0' "$STATE_FILE" 2>/dev/null)
TOKENS=$(jq -r '.tokens_used // 0' "$STATE_FILE" 2>/dev/null)
STRIKES=$(jq -r '.no_progress_strikes // 0' "$STATE_FILE" 2>/dev/null)
PROJECT=$(jq -r '.project // "unknown"' "$STATE_FILE" 2>/dev/null)
TIMESTAMP=$(date -u +%Y-%m-%dT%H:%M:%SZ)

# Construct JSON payload
PAYLOAD=$(jq -n \
  --arg ts "$TIMESTAMP" \
  --arg proj "$PROJECT" \
  --arg ms "$MILESTONE" \
  --arg stat "$STATUS" \
  --argjson it "$ITERATION" \
  --argjson tok "$TOKENS" \
  --argjson str "$STRIKES" \
  '{timestamp: $ts, project: $proj, milestone: $ms, status: $stat, iterations: $it, tokens_used: $tok, strikes: $str}')

# Append to log
echo "$PAYLOAD" >> "$TELEMETRY_LOG"
echo "📡 Telemetry logged: $STATUS ($TOKENS tokens, $ITERATION iterations)"

# Update last_known_commit upon COMPLETE to establish a new baseline for drift detection
if [ "$STATUS" = "COMPLETE" ]; then
  NEW_COMMIT=$(git -C "$PROJECT_ROOT" rev-parse HEAD 2>/dev/null || echo "")
  if [ -n "$NEW_COMMIT" ]; then
    jq --arg c "$NEW_COMMIT" '.last_known_commit = $c' "$STATE_FILE" > "${STATE_FILE}.tmp" && mv "${STATE_FILE}.tmp" "$STATE_FILE"
  fi
fi
