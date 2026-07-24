#!/usr/bin/env bash
# health-check.sh — Periodic health check for ANCHOR projects
# Usage: bash health-check.sh [project-root]
#
# Reports only. Never auto-fixes. Output is designed to be read by a human
# or captured as an Antigravity artifact.
#
# Checks:
#   1. All verify.sh checks (delegates to verify.sh)
#   2. Stale state detection (milestone open too long without progress)
#   3. Context graph invariant violations
#   4. Orphaned checkpoints (checkpoint exists but milestone not in state)
#   5. Uncommitted state drift (state files modified but not checkpointed)
#
# To schedule in Antigravity, use a cron-style scheduled task that runs:
#   bash .agents/skills/anchor-verify/scripts/health-check.sh /path/to/project

set -uo pipefail

ROOT="${1:-.}"
ROOT=$(cd "$ROOT" && pwd)

ISSUES=0

report() {
  local severity="$1"  # INFO, WARN, ALERT
  local message="$2"
  echo "[$severity] $message"
  if [ "$severity" = "WARN" ] || [ "$severity" = "ALERT" ]; then
    ISSUES=$((ISSUES + 1))
  fi
}

echo "============================================"
echo "  ANCHOR Health Check Report"
echo "  Project: $ROOT"
echo "  Time: $(date -u +%Y-%m-%dT%H:%M:%SZ)"
echo "============================================"
echo ""

# --- CHECK 1: Delegate to verify.sh ---
echo "--- 1. Structural Integrity (via verify.sh) ---"
VERIFY_SCRIPT="$ROOT/.agents/skills/anchor-verify/scripts/verify.sh"
if [ -f "$VERIFY_SCRIPT" ]; then
  verify_output=$(bash "$VERIFY_SCRIPT" "$ROOT" 2>&1)
  verify_exit=$?
  if [ $verify_exit -eq 0 ]; then
    report "INFO" "verify.sh: all checks passed"
  else
    report "ALERT" "verify.sh: one or more checks FAILED"
    echo "$verify_output" | grep "FAIL" | while read -r line; do
      report "ALERT" "  $line"
    done
  fi
else
  report "WARN" "verify.sh not found at $VERIFY_SCRIPT"
fi
echo ""

# --- CHECK 2: Stale state detection ---
echo "--- 2. Stale State Detection ---"
STATE_FILE="$ROOT/.agents/state/state.json"
if [ -f "$STATE_FILE" ]; then
  current_gate=$(jq -r '.current_gate // "null"' "$STATE_FILE" 2>/dev/null)
  current_milestone=$(jq -r '.current_milestone // "null"' "$STATE_FILE" 2>/dev/null)
  last_updated=$(jq -r '.last_updated // "null"' "$STATE_FILE" 2>/dev/null)
  no_progress=$(jq -r '.no_progress_strikes // 0' "$STATE_FILE" 2>/dev/null)

  if [ "$current_gate" != "null" ] && [ "$current_milestone" != "null" ]; then
    report "INFO" "Active milestone: $current_milestone at gate $current_gate"
    report "INFO" "Last updated: $last_updated"

    # Check if last_updated is more than 24 hours ago
    if [ "$last_updated" != "null" ]; then
      last_epoch=$(date -d "$last_updated" +%s 2>/dev/null || echo "0")
      now_epoch=$(date +%s)
      hours_ago=$(( (now_epoch - last_epoch) / 3600 ))
      if [ "$hours_ago" -gt 24 ]; then
        report "WARN" "Milestone $current_milestone has been stale for ${hours_ago}h (last updated: $last_updated)"
      fi
    fi

    # Check no-progress strikes
    if [ "$no_progress" -ge 2 ]; then
      report "WARN" "No-progress strikes at $no_progress/3 — close to halt threshold"
    fi
  else
    report "INFO" "No active milestone — system idle"
  fi
else
  report "ALERT" "state.json not found"
fi
echo ""

# --- CHECK 3: Context graph invariant violations ---
echo "--- 3. Invariant Check ---"
GRAPH_FILE="$ROOT/.agents/state/context-graph.json"
if [ -f "$GRAPH_FILE" ]; then
  invariant_count=$(jq '.invariants | length' "$GRAPH_FILE" 2>/dev/null || echo "0")
  if [ "$invariant_count" -eq 0 ]; then
    report "INFO" "No invariants defined yet (human should add 2-3 after running anchor-graph)"
  else
    report "INFO" "Checking $invariant_count invariant(s)..."
    # Read each invariant and attempt to check it
    # Invariants are human-written text; we can grep for obvious violations
    jq -r '.invariants[]' "$GRAPH_FILE" 2>/dev/null | while read -r invariant; do
      report "INFO" "  Invariant: \"$invariant\" — (manual check required)"
    done
  fi
else
  report "WARN" "context-graph.json not found"
fi
echo ""

# --- CHECK 4: Orphaned checkpoints ---
echo "--- 4. Orphaned Checkpoint Check ---"
CP_DIR="$ROOT/.agents/state/checkpoints"
if [ -d "$CP_DIR" ]; then
  while IFS= read -r cpfile; do
    cpname=$(basename "$cpfile" .md)
    # Check if this is a completed milestone that still shows as current
    if grep -q "COMPLETE" "$cpfile" 2>/dev/null; then
      if [ "$current_milestone" = "$cpname" ]; then
        report "WARN" "Milestone $cpname is marked COMPLETE in checkpoint but still shows as current_milestone in state.json"
      else
        report "INFO" "Completed: $cpname"
      fi
    else
      if [ "$current_milestone" != "$cpname" ]; then
        report "WARN" "Checkpoint $cpname exists but is not the current milestone and not marked COMPLETE — possibly orphaned"
      else
        report "INFO" "In progress: $cpname"
      fi
    fi
  done < <(find "$CP_DIR" -maxdepth 1 -name "*.md" ! -name ".gitkeep" -type f 2>/dev/null | sort)
fi
echo ""

# --- CHECK 5: CURRENT.md staleness ---
echo "--- 5. CURRENT.md Consistency ---"
CURRENT_FILE="$ROOT/.agents/state/CURRENT.md"
if [ -f "$CURRENT_FILE" ]; then
  current_md_gate=$(grep "active_gate:" "$CURRENT_FILE" 2>/dev/null | sed 's/.*active_gate:\s*//' | tr -d '[:space:]')
  if [ "$current_gate" != "null" ] && [ -n "$current_md_gate" ] && [ "$current_md_gate" != "$current_gate" ]; then
    report "WARN" "CURRENT.md shows gate '$current_md_gate' but state.json shows gate '$current_gate' — out of sync"
  else
    report "INFO" "CURRENT.md and state.json are consistent"
  fi
else
  report "ALERT" "CURRENT.md not found"
fi
echo ""

# --- Summary ---
echo "============================================"
if [ "$ISSUES" -eq 0 ]; then
  echo "  Health: GOOD — no issues found"
else
  echo "  Health: $ISSUES issue(s) found — review above"
fi
echo "============================================"

exit "$ISSUES"
