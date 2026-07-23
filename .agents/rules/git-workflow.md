# Git Workflow Rules

These rules govern git operations in any project using ANCHOR.

---

## Commits

1. **Commits are atomic.** One logical change per commit. Not a day's work in one commit, not half a feature and a bug fix in the same commit. If you can't describe the commit in one short sentence, it's too big.

2. **Commit messages follow `type: subject` format.** Types: `feat`, `fix`, `refactor`, `test`, `docs`, `chore`, `ci`. Subject is lowercase, imperative mood, no trailing period. Example: `feat: add token expiry validation`. Not: `Fixed stuff` or `WIP`.

3. **Never commit generated files, build artifacts, node_modules, or IDE configuration.** These belong in `.gitignore`. If they appear in a diff, the commit is rejected.

## Branches

4. **Branch from main for all feature work.** Branch name format: `type/short-description` (e.g., `feat/auth-flow`, `fix/token-expiry`). No spaces, no uppercase.

5. **Merge via pull request with at least one review** for any production-bound change. Direct pushes to main are only acceptable for emergency hotfixes, and those still get a post-merge review within 24 hours.

## Dangerous operations

6. **Force-push, branch deletion, and history rewriting require the draft-commit pattern.** Per AGENTS.md rule 8: draft the operation as an artifact, get explicit human approval, then execute as a separate step. Never force-push in a single action.

7. **Never rebase or amend commits that have been pushed to a shared branch.** Rewriting shared history breaks other people's work. Rebase is for local, unpushed commits only.

## Hygiene

8. **Pull before pushing.** Always fetch and integrate upstream changes before pushing to avoid unnecessary merge conflicts.

9. **Tag releases with semantic versioning.** Format: `v<major>.<minor>.<patch>`. Tags are the canonical reference for what's deployed; commit SHAs are not human-readable enough for incident response.
