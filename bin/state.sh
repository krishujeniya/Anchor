#!/usr/bin/env bash
# state.sh — ANCHOR State Access Abstraction Layer
# Exposes helper functions to read and write state.json.

STATE_FILE="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/.agents/state/state.json"

# anchor_state_get <key> [default_value]
# Returns the value of the key from state.json, or default_value if missing/null.
anchor_state_get() {
  local key="$1"
  local default_val="${2:-}"
  
  if [ ! -f "$STATE_FILE" ]; then
    echo "$default_val"
    return 0
  fi
  
  local val
  val=$(jq -r --arg k "$key" '.[$k] // empty' "$STATE_FILE" 2>/dev/null || echo "")
  
  if [ -z "$val" ]; then
    echo "$default_val"
  else
    echo "$val"
  fi
}

# anchor_state_set <key> <value> [<type>]
# Updates a key in state.json. Use type="number" for integers.
anchor_state_set() {
  local key="$1"
  local val="$2"
  local type="${3:-string}"
  
  if [ ! -f "$STATE_FILE" ]; then
    echo "Error: state.json not found." >&2
    return 1
  fi
  
  if [ "$type" = "number" ]; then
    jq --arg k "$key" --argjson v "$val" '.[$k] = $v' "$STATE_FILE" > "${STATE_FILE}.tmp" && mv "${STATE_FILE}.tmp" "$STATE_FILE"
  else
    jq --arg k "$key" --arg v "$val" '.[$k] = $v' "$STATE_FILE" > "${STATE_FILE}.tmp" && mv "${STATE_FILE}.tmp" "$STATE_FILE"
  fi
}
