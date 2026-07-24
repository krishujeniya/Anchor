#!/bin/bash

# Draft Commit: Release v1.1.0 to GitHub
# Stages all the new features (Chaos Daemon, Context Compaction, Auto Revert),
# commits them to history, and pushes to origin main.

set -e

echo "Staging files..."
git add .

echo "Committing v1.1.0 release..."
git commit -m "feat: release v1.1.0 (Chaos Daemon, Context Compaction, Auto-Revert)"

echo "Pushing to GitHub..."
git push origin main

echo "Push complete."
