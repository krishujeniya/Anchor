#!/usr/bin/env bash
# verify.sh — Deterministic verification checks for ANCHOR projects
# Usage: bash verify.sh [project-root]
# Exit code: 0 = all checks pass, 1 = one or more checks failed
#
# Checks:
#   1. JSON syntax validation (all .json files via jq)
#   2. Bash syntax validation (all .sh files via bash -n)
#   3. SKILL.md frontmatter validation (name + description required)
#   4. state.json schema validation (required fields present)
#   5. File structure validation (expected dirs exist)
#   6. Checkpoint consistency (completed milestones have VERIFY entries)
#
# Zero external dependencies beyond jq (standard on most systems).

set -uo pipefail

ROOT="${1:-.}"
ROOT=$(cd "$ROOT" && pwd)

# Helper: find files only within ANCHOR-relevant paths
# (project root files + .agents/ tree). Skips sibling reference repos.
anchor_find() {
  local pattern="$1"
  # Search .agents/ tree and root-level files only, excluding .git and node_modules
  find "$ROOT/.agents" -type f -name "$pattern" ! -path '*/.git/*' ! -path '*/node_modules/*' 2>/dev/null | sort
  find "$ROOT" -maxdepth 1 -type f -name "$pattern" 2>/dev/null | sort
}

PASS=0
FAIL=0
TOTAL=0

check() {
  local name="$1"
  local result="$2"  # 0 = pass, nonzero = fail
  local detail="$3"
  TOTAL=$((TOTAL + 1))
  if [ "$result" -eq 0 ]; then
    PASS=$((PASS + 1))
    echo "  PASS: $name"
  else
    FAIL=$((FAIL + 1))
    echo "  FAIL: $name — $detail"
  fi
}

echo "=== ANCHOR Verification Checks ==="
echo "Project root: $ROOT"
echo ""

# --- CHECK 1: JSON syntax validation ---
echo "--- Check 1: JSON syntax ---"
json_fail=0
json_detail=""
while IFS= read -r jsonfile; do
  relpath="${jsonfile#"$ROOT"/}"
  if ! jq . "$jsonfile" > /dev/null 2>&1; then
    json_fail=1
    json_detail="$json_detail $relpath"
  else
    echo "  valid: $relpath"
  fi
done < <(anchor_find "*.json")
check "JSON syntax (all .json files)" "$json_fail" "invalid files:$json_detail"

echo ""

# --- CHECK 2: Bash syntax validation ---
echo "--- Check 2: Bash syntax ---"
sh_fail=0
sh_detail=""
while IFS= read -r shfile; do
  relpath="${shfile#"$ROOT"/}"
  if ! bash -n "$shfile" 2>/dev/null; then
    sh_fail=1
    sh_detail="$sh_detail $relpath"
  else
    echo "  valid: $relpath"
  fi
done < <(anchor_find "*.sh")

if [ -z "$(anchor_find "*.sh")" ]; then
  echo "  (no .sh files found — skipping)"
  check "Bash syntax (all .sh files)" 0 ""
else
  check "Bash syntax (all .sh files)" "$sh_fail" "invalid files:$sh_detail"
fi

echo ""

# --- CHECK 3: SKILL.md frontmatter validation ---
echo "--- Check 3: SKILL.md frontmatter ---"
skill_fail=0
skill_detail=""
while IFS= read -r skillfile; do
  relpath="${skillfile#"$ROOT"/}"
  # Check for YAML frontmatter with name and description
  has_frontmatter=$(head -1 "$skillfile" | grep -c "^---" || true)
  has_name=$(grep -c "^name:" "$skillfile" || true)
  has_desc=$(grep -c "^description:" "$skillfile" || true)

  if [ "$has_frontmatter" -eq 0 ]; then
    skill_fail=1
    skill_detail="$skill_detail $relpath(no-frontmatter)"
  elif [ "$has_name" -eq 0 ]; then
    skill_fail=1
    skill_detail="$skill_detail $relpath(no-name)"
  elif [ "$has_desc" -eq 0 ]; then
    skill_fail=1
    skill_detail="$skill_detail $relpath(no-description)"
  else
    echo "  valid: $relpath"
  fi
done < <(find "$ROOT/.agents/skills" -name "SKILL.md" -type f 2>/dev/null | sort)
check "SKILL.md frontmatter (name + description)" "$skill_fail" "invalid:$skill_detail"

echo ""

# --- CHECK 4: state.json schema validation ---
echo "--- Check 4: state.json schema ---"
STATE_FILE="$ROOT/.agents/state/state.json"
if [ -f "$STATE_FILE" ]; then
  schema_fail=0
  schema_detail=""

  # Required fields
  for field in project current_gate current_milestone iteration iteration_cap token_budget tokens_used no_progress_strikes hitl_approvals last_updated; do
    if ! jq -e "has(\"$field\")" "$STATE_FILE" > /dev/null 2>&1; then
      schema_fail=1
      schema_detail="$schema_detail missing:$field"
    fi
  done

  # Type checks
  iter=$(jq -r '.iteration' "$STATE_FILE" 2>/dev/null)
  if ! [[ "$iter" =~ ^[0-9]+$ ]]; then
    schema_fail=1
    schema_detail="$schema_detail iteration-not-integer"
  fi

  cap=$(jq -r '.iteration_cap' "$STATE_FILE" 2>/dev/null)
  if ! [[ "$cap" =~ ^[0-9]+$ ]]; then
    schema_fail=1
    schema_detail="$schema_detail iteration_cap-not-integer"
  fi

  if [ "$schema_fail" -eq 0 ]; then
    echo "  all required fields present with correct types"
  fi
  check "state.json schema" "$schema_fail" "$schema_detail"
else
  check "state.json schema" 1 "state.json not found"
fi

echo ""

# --- CHECK 5: File structure validation ---
echo "--- Check 5: File structure ---"
struct_fail=0
struct_detail=""
for dir in ".agents/state" ".agents/state/checkpoints" ".agents/state/decisions" ".agents/skills"; do
  if [ -d "$ROOT/$dir" ]; then
    echo "  exists: $dir/"
  else
    struct_fail=1
    struct_detail="$struct_detail missing:$dir/"
  fi
done
for file in "AGENTS.md" ".agents/state/state.json" ".agents/state/CURRENT.md" ".agents/state/context-graph.json"; do
  if [ -f "$ROOT/$file" ]; then
    echo "  exists: $file"
  else
    struct_fail=1
    struct_detail="$struct_detail missing:$file"
  fi
done
check "File structure (expected dirs + files)" "$struct_fail" "$struct_detail"

echo ""

# --- CHECK 6: Checkpoint consistency ---
echo "--- Check 6: Checkpoint consistency ---"
cp_fail=0
cp_detail=""
# Check that completed milestones (those with "COMPLETE" in checkpoint) have a verify entry
while IFS= read -r cpfile; do
  relpath="${cpfile#"$ROOT"/}"
  if grep -q "COMPLETE" "$cpfile" 2>/dev/null; then
    if ! grep -qi "verify\|APPROVE" "$cpfile" 2>/dev/null; then
      cp_fail=1
      cp_detail="$cp_detail $relpath(complete-but-no-verify)"
    else
      echo "  consistent: $relpath"
    fi
  else
    echo "  in-progress: $relpath"
  fi
done < <(find "$ROOT/.agents/state/checkpoints" -name "*.md" ! -name ".gitkeep" -type f 2>/dev/null | sort)

if [ -z "$(find "$ROOT/.agents/state/checkpoints" -name "*.md" ! -name ".gitkeep" -type f 2>/dev/null)" ]; then
  echo "  (no checkpoints found — skipping)"
fi
check "Checkpoint consistency" "$cp_fail" "$cp_detail"

echo ""

# --- Summary ---
echo "=== Summary ==="
echo "Total: $TOTAL checks, $PASS passed, $FAIL failed"
echo ""

if [ "$FAIL" -gt 0 ]; then
  echo "RESULT: FAIL"
  exit 1
else
  echo "RESULT: PASS"
  exit 0
fi
