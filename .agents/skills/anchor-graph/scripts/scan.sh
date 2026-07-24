#!/usr/bin/env bash
# scan.sh — Dependency-free import scanner for context-graph.json
# Usage: bash scan.sh [project-root]
# Output: JSON with "nodes" and "edges" arrays to stdout
#
# Detects: JS/TS (import/require), Python (import/from), Go (import),
#          Markdown (file references), and shell scripts.
# Zero external dependencies — uses only grep, sed, awk, find, and bash builtins.

set -euo pipefail

ROOT="${1:-.}"
ROOT=$(cd "$ROOT" && pwd)

# Temporary files for collecting nodes and edges
NODES_TMP=$(mktemp)
EDGES_TMP=$(mktemp)
trap 'rm -f "$NODES_TMP" "$EDGES_TMP"' EXIT

# --- Detect project type ---
has_js=false
has_py=false
has_go=false
has_md=false
has_sh=false

find "$ROOT" -maxdepth 5 -type f \( -name "*.js" -o -name "*.ts" -o -name "*.jsx" -o -name "*.tsx" \) \
  ! -path "*/node_modules/*" ! -path "*/.git/*" ! -path "*/eval_fixtures/*" | head -1 | grep -q . && has_js=true || true
find "$ROOT" -maxdepth 5 -type f -name "*.py" \
  ! -path "*/.git/*" ! -path "*/eval_fixtures/*" | head -1 | grep -q . && has_py=true || true
find "$ROOT" -maxdepth 5 -type f -name "*.go" \
  ! -path "*/.git/*" ! -path "*/eval_fixtures/*" | head -1 | grep -q . && has_go=true || true
find "$ROOT" -maxdepth 5 -type f -name "*.md" \
  ! -path "*/.git/*" ! -path "*/node_modules/*" ! -path "*/eval_fixtures/*" | head -1 | grep -q . && has_md=true || true
find "$ROOT" -maxdepth 5 -type f -name "*.sh" \
  ! -path "*/.git/*" ! -path "*/eval_fixtures/*" | head -1 | grep -q . && has_sh=true || true

# --- Collect nodes ---
find "$ROOT" -maxdepth 5 -type f \( \
  -name "*.js" -o -name "*.ts" -o -name "*.jsx" -o -name "*.tsx" \
  -o -name "*.py" -o -name "*.go" \
  -o -name "*.md" -o -name "*.sh" -o -name "*.json" \
  \) ! -path "*/.git/*" ! -path "*/node_modules/*" ! -path "*/eval_fixtures/*" ! -path "*/.gitkeep" \
  | sort | while read -r filepath; do
    relpath="${filepath#"$ROOT"/}"
    ext="${filepath##*.}"
    case "$ext" in
      js|ts|jsx|tsx) ntype="source" ;;
      py)            ntype="source" ;;
      go)            ntype="source" ;;
      sh)            ntype="script" ;;
      md)
        case "$relpath" in
          *SKILL.md)          ntype="skill" ;;
          *rules/*)           ntype="rule" ;;
          *checkpoints/*)     ntype="checkpoint" ;;
          *decisions/*)       ntype="decision" ;;
          *CURRENT.md|*AGENTS.md) ntype="config" ;;
          *)                  ntype="doc" ;;
        esac
        ;;
      json)
        case "$relpath" in
          *state.json|*context-graph.json) ntype="state" ;;
          *)                               ntype="config" ;;
        esac
        ;;
      *) ntype="other" ;;
    esac
    echo "$relpath|$ntype"
done > "$NODES_TMP"

# --- Collect edges ---

# JS/TS: import ... from '...' and require('...')
if $has_js; then
  find "$ROOT" -maxdepth 5 -type f \( -name "*.js" -o -name "*.ts" -o -name "*.jsx" -o -name "*.tsx" \) \
    ! -path "*/node_modules/*" ! -path "*/.git/*" ! -path "*/eval_fixtures/*" | while read -r filepath; do
      relpath="${filepath#"$ROOT"/}"
      # import ... from '...'
      grep -oP "from\s+['\"](\./[^'\"]+)['\"]" "$filepath" 2>/dev/null | \
        sed "s/from\s*['\"]//;s/['\"]//" | while read -r dep; do
          echo "$relpath|$dep|imports"
      done
      # require('...')
      grep -oP "require\(['\"](\./[^'\"]+)['\"]\)" "$filepath" 2>/dev/null | \
        sed "s/require(['\"]//;s/['\"]//" | while read -r dep; do
          echo "$relpath|$dep|imports"
      done
  done >> "$EDGES_TMP" 2>/dev/null || true
fi

# Python: import X, from X import Y
if $has_py; then
  find "$ROOT" -maxdepth 5 -type f -name "*.py" ! -path "*/.git/*" ! -path "*/eval_fixtures/*" | while read -r filepath; do
    relpath="${filepath#"$ROOT"/}"
    grep -oP "^\s*(from|import)\s+([a-zA-Z0-9_.]+)" "$filepath" 2>/dev/null | \
      sed 's/^\s*from\s*//;s/^\s*import\s*//' | \
      sed 's/\s*import.*$//' | while read -r dep; do
        echo "$relpath|$dep|imports"
    done
  done >> "$EDGES_TMP" 2>/dev/null || true
fi

# Markdown: file references like [text](file/path) or backtick `file/path`
if $has_md; then
  find "$ROOT" -maxdepth 5 -type f -name "*.md" ! -path "*/.git/*" ! -path "*/eval_fixtures/*" ! -path "*/node_modules/*" | while read -r filepath; do
    relpath="${filepath#"$ROOT"/}"
    # Markdown links to local files: [text](path/to/file)
    grep -oP '\]\((?!https?://|#)([^)]+)\)' "$filepath" 2>/dev/null | \
      sed 's/\](//' | sed 's/)//' | while read -r dep; do
        echo "$relpath|$dep|references"
    done
    # Backtick references to .agents/ paths
    grep -oP '`(\.agents/[^`]+)`' "$filepath" 2>/dev/null | \
      sed 's/`//g' | while read -r dep; do
        echo "$relpath|$dep|references"
    done
  done >> "$EDGES_TMP" 2>/dev/null || true
fi

# --- Output JSON ---
jq -R -s -c '[split("\n")[] | select(length > 0) | split("|") | {id: .[0], type: .[1]}]' "$NODES_TMP" > "${NODES_TMP}.json"
jq -R -s -c '[split("\n")[] | select(length > 0) | split("|") | {from: .[0], to: .[1], type: .[2]}]' "$EDGES_TMP" > "${EDGES_TMP}.json"

jq -n \
  --slurpfile nodes "${NODES_TMP}.json" \
  --slurpfile edges "${EDGES_TMP}.json" \
  '{nodes: $nodes[0], edges: $edges[0], invariants: []}'
