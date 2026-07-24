#!/usr/bin/env bash
# telemetry.sh — ANCHOR Telemetry Logger & Aggregator
# Appends milestone metrics to an append-only JSONL log.
# Usage:
#   bash bin/telemetry.sh log <STATUS>
#   bash bin/telemetry.sh aggregate
# Example: bash bin/telemetry.sh log COMPLETE

set -euo pipefail

PROJECT_ROOT=$(cd "$(dirname "$0")/.." && pwd)
STATE_FILE="${PROJECT_ROOT}/.agents/state/state.json"
TELEMETRY_LOG="${PROJECT_ROOT}/.agents/state/telemetry.jsonl"

if [ "${1:-}" = "aggregate" ]; then
  if [ ! -f "$TELEMETRY_LOG" ]; then
    echo "No telemetry log found."
    exit 0
  fi
  
  echo "📊 ANCHOR Telemetry Aggregation"
  echo "==============================="
  
  # Use jq to slurp the JSONL and calculate sums/averages
  jq -s '
    length as $total_runs |
    (map(.tokens_used) | add // 0) as $total_tokens |
    (map(.iterations) | add // 0) as $total_iterations |
    {
      total_runs: $total_runs,
      total_tokens: $total_tokens,
      total_iterations: $total_iterations,
      avg_tokens: (if $total_runs > 0 then $total_tokens / $total_runs else 0 end | floor),
      avg_iterations: (if $total_runs > 0 then $total_iterations / $total_runs else 0 end | floor)
    } |
    "Total Runs/Milestones Logged: \(.total_runs)\n" +
    "Total Tokens Burned:          \(.total_tokens)\n" +
    "Total Iterations:             \(.total_iterations)\n" +
    "Average Tokens per Run:       \(.avg_tokens)\n" +
    "Average Iterations per Run:   \(.avg_iterations)"
  ' "$TELEMETRY_LOG" -r
  
  exit 0
fi

if [ "${1:-}" != "log" ] || [ -z "${2:-}" ]; then
  echo "Usage: $0 log <STATUS>"
  echo "       $0 aggregate"
  exit 1
fi

STATUS="$2"

if [ ! -f "$STATE_FILE" ]; then
  echo "No state.json found. Cannot log telemetry."
  exit 0
fi

source "${PROJECT_ROOT}/bin/state.sh"

# Ensure log file exists
touch "$TELEMETRY_LOG"

# Extract fields
MILESTONE=$(anchor_state_get "current_milestone" "unknown")
ITERATION=$(anchor_state_get "iteration" 0)
TOKENS=$(anchor_state_get "tokens_used" 0)
STRIKES=$(anchor_state_get "no_progress_strikes" 0)
PROJECT=$(anchor_state_get "project" "unknown")
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
    anchor_state_set "last_known_commit" "$NEW_COMMIT" "string"
  fi
fi
