#!/usr/bin/env bash
# eval.sh — ANCHOR Evaluation Harness
# Evaluates skills integrity and backwards-compatibility against archived milestones.

set -euo pipefail

PROJECT_ROOT=$(cd "$(dirname "$0")/.." && pwd)
AGENTS_DIR="${PROJECT_ROOT}/.agents"

echo "🧪 Starting ANCHOR Eval Harness..."

# Phase 1: Current State
echo ""
echo "▶️ Phase 1: Current State Verification"
if bash "${AGENTS_DIR}/skills/anchor-verify/scripts/verify.sh" "$PROJECT_ROOT" > /dev/null; then
  echo "  ✅ Current state and skills pass verify.sh"
else
  echo "  ❌ Current state failed verify.sh checks."
  # Run again without swallowing output so the user sees the error
  bash "${AGENTS_DIR}/skills/anchor-verify/scripts/verify.sh" "$PROJECT_ROOT"
  exit 1
fi

# Phase 2: Historical Archive Regression (Checkpoints)
echo ""
echo "▶️ Phase 2: Historical Checkpoint Regression"
ARCHIVE_DIR="${AGENTS_DIR}/state/checkpoints/archive"
FAIL=0
TOTAL=0

if [ -d "$ARCHIVE_DIR" ]; then
  while IFS= read -r cpfile; do
    relpath="${cpfile#"$PROJECT_ROOT"/}"
    TOTAL=$((TOTAL + 1))
    
    # Checkpoint schema validation:
    # Must have Goal:, ## Gate:, and either HALT or COMPLETE
    has_goal=$(grep -c "^Goal:" "$cpfile" || true)
    has_gate=$(grep -c "^## Gate:" "$cpfile" || true)
    has_result=$(grep -ci "halt\|complete" "$cpfile" || true)

    if [ "$has_goal" -eq 0 ] || [ "$has_gate" -eq 0 ] || [ "$has_result" -eq 0 ]; then
      echo "  ❌ FAIL: $relpath (schema mismatch)"
      FAIL=$((FAIL + 1))
    else
      echo "  ✅ PASS: $relpath (schema valid)"
    fi
  done < <(find "$ARCHIVE_DIR" -type f -name "*.md" | sort)
fi

if [ "$TOTAL" -eq 0 ]; then
  echo "  (No archived checkpoints found to test)"
fi

echo ""
echo "=== Eval Summary ==="
if [ "$FAIL" -gt 0 ]; then
  echo "RESULT: FAIL ($FAIL historical regressions)"
  exit 1
else
  echo "RESULT: PASS (0 regressions)"
  exit 0
fi
