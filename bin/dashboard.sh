#!/usr/bin/env bash

# dashboard.sh — Launches the ANCHOR Web Dashboard

PROJECT_ROOT=$(cd "$(dirname "$0")/.." && pwd)

if ! command -v python3 >/dev/null 2>&1; then
  echo "Error: python3 is required to run the local dashboard server."
  exit 1
fi

echo "⚓ Starting ANCHOR Dashboard Server..."
echo "👉 Open http://localhost:8080/dashboard/ in your browser."
echo "Press Ctrl+C to stop."

cd "$PROJECT_ROOT"
python3 -m http.server 8080 > /dev/null 2>&1
