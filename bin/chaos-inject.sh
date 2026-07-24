#!/bin/bash

# ANCHOR Chaos Daemon (Single-shot injector)
# Usage: ./chaos-inject.sh --mode [drift|state|git]

set -e

MODE=""

while [[ "$#" -gt 0 ]]; do
    case $1 in
        --mode) MODE="$2"; shift ;;
        *) echo "Unknown parameter passed: $1"; exit 1 ;;
    esac
    shift
done

if [ -z "$MODE" ]; then
    echo "Usage: $0 --mode [drift|state|git]"
    exit 1
fi

echo "[Chaos Daemon] Initiating sabotage in mode: $MODE"

case $MODE in
    drift)
        # Find a random source file to mutate
        TARGET=$(find . -type f \( -name "*.py" -o -name "*.js" -o -name "*.ts" \) -not -path "*/node_modules/*" -not -path "*/venv/*" | shuf -n 1)
        if [ -z "$TARGET" ]; then
            TARGET=$(find . -type f -name "*.md" -not -path "*/node_modules/*" | shuf -n 1)
        fi
        
        if [ -n "$TARGET" ]; then
            echo "// CHAOS INJECTED: SYNTAX DRIFT" >> "$TARGET"
            echo "def _chaos_drift(): pass # chaos" >> "$TARGET"
            echo "[Chaos Daemon] Injected drift into $TARGET"
        else
            echo "[Chaos Daemon] No valid files found for drift injection."
        fi
        ;;
        
    state)
        # Target .agents/state
        if [ -d ".agents/state" ]; then
            if [ -f ".agents/state/context-graph.json" ]; then
                rm ".agents/state/context-graph.json"
                echo "[Chaos Daemon] Deleted .agents/state/context-graph.json"
            elif [ -f ".agents/state/state.json" ]; then
                echo "{ \"corrupted\": true }" > ".agents/state/state.json"
                echo "[Chaos Daemon] Corrupted .agents/state/state.json"
            else
                echo "[Chaos Daemon] No state files found to corrupt."
            fi
        else
            echo "[Chaos Daemon] No .agents/state directory found."
        fi
        ;;
        
    git)
        # Git disruption
        if [ -d ".git" ]; then
            CURRENT_BRANCH=$(git branch --show-current)
            if [ -z "$CURRENT_BRANCH" ]; then
                CURRENT_BRANCH="main"
            fi
            
            # Create a conflicting branch
            git checkout -b chaos-disrupt-$(date +%s)
            
            # Modify a random file
            TARGET=$(find . -type f \( -name "*.md" -o -name "*.py" -o -name "*.js" -o -name "*.ts" \) -not -path "*/.git/*" | shuf -n 1)
            if [ -n "$TARGET" ]; then
                echo "<!-- CHAOS GIT CONFLICT -->" >> "$TARGET"
                git add "$TARGET"
                git commit -m "Chaos Daemon: upstream conflict injection"
                
                # Switch back to the original branch
                git checkout $CURRENT_BRANCH
                
                echo "<!-- CHAOS LOCAL CONFLICT -->" >> "$TARGET"
                
                echo "[Chaos Daemon] Created git conflict condition on $TARGET"
            else
                echo "[Chaos Daemon] No files found for git disruption."
            fi
        else
            echo "[Chaos Daemon] Not a git repository."
        fi
        ;;
        
    *)
        echo "[Chaos Daemon] Unknown mode: $MODE"
        exit 1
        ;;
esac

echo "[Chaos Daemon] Injection complete."
