#!/bin/bash

# Draft Commit: Production-Ready Repository Cleanup
# Removes trial artifacts (src, test, package.json) and wipes dirty state logs
# so the repository serves purely as a clean framework template.

set -e

echo "Staging deletions and state resets..."
git add -A

echo "Committing cleanup..."
git commit -m "chore: purge trial artifacts and sanitize internal state for production template"

echo "Pushing to GitHub..."
git push origin main

echo "Cleanup push complete."
