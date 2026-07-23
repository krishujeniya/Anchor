#!/usr/bin/env bash
# scan-security.sh — ANCHOR Security Scanner
# Scans the project for hardcoded secrets, API keys, and vulnerabilities.
# Usage: bash scan-security.sh [project-root]
# Exit code: 0 = clean, 1 = secrets found

set -uo pipefail

ROOT="${1:-.}"
ROOT=$(cd "$ROOT" && pwd)

echo "🛡️ Starting ANCHOR Security Scan in $ROOT"

# Fallback to gitleaks if present
if command -v gitleaks >/dev/null 2>&1; then
  echo "  (gitleaks detected, delegating scan...)"
  if gitleaks detect --source "$ROOT" -v; then
    echo "RESULT: PASS (gitleaks found no secrets)"
    exit 0
  else
    echo "RESULT: FAIL (gitleaks found secrets)"
    exit 1
  fi
fi

# Fallback to trufflehog if present
if command -v trufflehog >/dev/null 2>&1; then
  echo "  (trufflehog detected, delegating scan...)"
  if trufflehog filesystem "$ROOT" --fail; then
    echo "RESULT: PASS (trufflehog found no secrets)"
    exit 0
  else
    echo "RESULT: FAIL (trufflehog found secrets)"
    exit 1
  fi
fi

echo "  (No dedicated scanner found, using built-in grep patterns...)"

# Define grep patterns for common secrets
patterns=(
  "AWS Access Key" "(A3T[A-Z0-9]|AKIA|AGPA|AIDA|AROA|AIPA|ANPA|ANVA|ASIA)[A-Z0-9]{16}"
  "Stripe Secret Key" "sk_(live|test)_[0-9a-zA-Z]{24,34}"
  "GitHub Token" "gh[pousr]_[A-Za-z0-9_]{36,255}"
  "Slack Token" "xox[baprs]-[0-9]{10,13}-[a-zA-Z0-9]{24,34}"
  "Generic Private Key" "-----BEGIN (RSA |EC |DSA |OPENSSH )?PRIVATE KEY-----"
  "Bearer Token Pattern" "Bearer [A-Za-z0-9\-\._~\+\/]{16,}="
)

FAIL=0

LINKED_REPOS=$(jq -r '.linked_repos[]?' "$ROOT/.agents/config.json" 2>/dev/null || echo "")

search_files() {
  for target_dir in "$ROOT" $LINKED_REPOS; do
    if [ -d "$target_dir" ]; then
      find "$target_dir" -type f \
        ! -path '*/\.git/*' \
        ! -path '*/node_modules/*' \
        ! -path '*/\.venv/*' \
        ! -path '*/venv/*' \
        ! -path '*/\.agents/state/checkpoints/archive/*' \
        ! -name "*.jpg" ! -name "*.png" ! -name "*.pdf" ! -name "*.zip" -print0
    fi
  done
}

len=${#patterns[@]}
for (( i=0; i<len; i+=2 )); do
  name="${patterns[$i]}"
  regex="${patterns[$i+1]}"
  
  if search_files | xargs -0 grep -EnI -e "$regex" > /tmp/anchor_scan_tmp 2>/dev/null; then
    echo "  ❌ Found potential $name:"
    cat /tmp/anchor_scan_tmp | sed 's/^/    /'
    FAIL=1
  fi
done

rm -f /tmp/anchor_scan_tmp

echo ""
if [ "$FAIL" -gt 0 ]; then
  echo "RESULT: FAIL (Secrets found)"
  exit 1
else
  echo "RESULT: PASS (No secrets found)"
  exit 0
fi
