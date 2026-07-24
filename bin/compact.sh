#!/bin/bash

# ANCHOR Context Compactor (COMPACT gate)
# Generates a fresh CURRENT.md skeleton for the agent to populate before IMPLEMENT.

set -e

STATE_DIR=".agents/state"
CURRENT_FILE="$STATE_DIR/CURRENT.md"
GRAPH_FILE="$STATE_DIR/context-graph.json"

mkdir -p "$STATE_DIR"

if [ ! -f "$GRAPH_FILE" ]; then
    echo "Warning: No context-graph.json found. Creating a minimal skeleton."
    NODES="None"
else
    # Extract nodes if possible using jq
    if command -v jq >/dev/null 2>&1; then
        NODES=$(jq -r '.nodes[].id' "$GRAPH_FILE" 2>/dev/null || echo "Failed to parse context graph.")
    else
        NODES="jq not installed, cannot parse context graph."
    fi
fi

cat <<EOF > "$CURRENT_FILE"
# COMPACT Gate: Current State

## 1. Active Goal
*(Agent: Summarize the current approved implementation plan here in 1-2 paragraphs)*

## 2. Context Graph Summary
*(Agent: Note any significant architectural dependencies relevant to the plan)*
**Tracked Modules:**
$NODES

## 3. Pending Tasks
*(Agent: Summarize the remaining implementation steps)*

## 4. Risks & Invariants
*(Agent: Note any constraints or invariant rules that must be respected during IMPLEMENT)*

EOF

echo "Generated compact skeleton at $CURRENT_FILE"
