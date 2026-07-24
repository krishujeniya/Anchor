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

# Phase 3: Behavioral Script Testing
echo ""
echo "▶️ Phase 3: Behavioral Script Testing"

# 1. verify.sh on corrupt state MUST FAIL
echo -n "  - verify.sh catches corrupt state... "
if bash "${AGENTS_DIR}/skills/anchor-verify/scripts/verify.sh" "${PROJECT_ROOT}/.agents/eval_fixtures/corrupt_state" > /dev/null 2>&1; then
  echo "❌ FAIL (Did not catch corruption)"
  FAIL=$((FAIL + 1))
else
  echo "✅ PASS"
fi

# 2. scan-security.sh on leaked secret MUST FAIL
echo -n "  - scan-security.sh catches leaked secret... "
if bash "${AGENTS_DIR}/skills/anchor-scout/scripts/scan-security.sh" "${PROJECT_ROOT}/.agents/eval_fixtures/leaked_secret" > /dev/null 2>&1; then
  echo "❌ FAIL (Did not catch secret)"
  FAIL=$((FAIL + 1))
else
  echo "✅ PASS"
fi

# 3. scan-security.sh on clean project MUST PASS
echo -n "  - scan-security.sh passes clean project... "
if bash "${AGENTS_DIR}/skills/anchor-scout/scripts/scan-security.sh" "${PROJECT_ROOT}/.agents/eval_fixtures/clean_secret" > /dev/null 2>&1; then
  echo "✅ PASS"
else
  echo "❌ FAIL (False positive)"
  FAIL=$((FAIL + 1))
fi

# 4. scan.sh parses quote_in_filename cleanly
echo -n "  - scan.sh handles escaped quotes... "
if bash "${AGENTS_DIR}/skills/anchor-graph/scripts/scan.sh" "${PROJECT_ROOT}/.agents/eval_fixtures/adversarial/quote_in_filename" | jq . > /dev/null 2>&1; then
  echo "✅ PASS"
else
  echo "❌ FAIL (JSON parsing broke)"
  FAIL=$((FAIL + 1))
fi

# 5. verify.sh on malformed_skill MUST FAIL
echo -n "  - verify.sh catches malformed skills... "
if bash "${AGENTS_DIR}/skills/anchor-verify/scripts/verify.sh" "${PROJECT_ROOT}/.agents/eval_fixtures/adversarial/malformed_skill" > /dev/null 2>&1; then
  echo "❌ FAIL (Did not catch malformed skill)"
  FAIL=$((FAIL + 1))
else
  echo "✅ PASS"
fi

# 6. drift-check.sh on untracked file MUST FAIL
echo -n "  - drift-check.sh catches untracked files... "
touch "${PROJECT_ROOT}/drift_mock.tmp"
if bash "${PROJECT_ROOT}/bin/drift-check.sh" > /dev/null 2>&1; then
  echo "❌ FAIL (Did not catch untracked file)"
  FAIL=$((FAIL + 1))
else
  echo "✅ PASS"
fi
rm -f "${PROJECT_ROOT}/drift_mock.tmp"

# 7. drift-check.sh on stale commit MUST FAIL
echo -n "  - drift-check.sh blocks stale/detached state... "
STATE_FILE="${PROJECT_ROOT}/.agents/state/state.json"
cp "$STATE_FILE" "${STATE_FILE}.bak"
jq '.last_known_commit = "fakehash123"' "$STATE_FILE" > "${STATE_FILE}.tmp" && mv "${STATE_FILE}.tmp" "$STATE_FILE"
if bash "${PROJECT_ROOT}/bin/drift-check.sh" > /dev/null 2>&1; then
  echo "❌ FAIL (Did not block detached state)"
  FAIL=$((FAIL + 1))
else
  echo "✅ PASS"
fi
mv "${STATE_FILE}.bak" "$STATE_FILE"


echo ""
echo "=== Eval Summary ==="
if [ "$FAIL" -gt 0 ]; then
  echo "RESULT: FAIL ($FAIL historical regressions)"
  exit 1
else
  echo "RESULT: PASS (0 regressions)"
  exit 0
fi
