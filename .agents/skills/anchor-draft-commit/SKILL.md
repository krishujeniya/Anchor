---
name: anchor-draft-commit
version: 1.0.0
description: >
  Draft-commit wrapper for dangerous operations (delete, migrate, force-push, deploy).
  Enforces the rule that one-step irreversible actions are never permitted.
---

# anchor-draft-commit

You must use this skill whenever a plan calls for a **dangerous operation**.

## What is a dangerous operation?

Any action that is irreversible or affects production state:
1. **Destructive Git**: `git push --force`, `git branch -D`, history rewrites.
2. **Data Deletion**: `rm -rf` on critical directories, dropping databases/tables.
3. **Schema Migration**: Altering production database structures.
4. **Deployment**: Pushing code to production or staging environments.
5. **Infrastructure**: Modifying cloud resources via Terraform, AWS CLI, etc.

## The Draft-Commit Pattern

You must NEVER execute a dangerous operation directly in a single step. You must use the draft-commit pattern.

### Step 1: Draft

1. Write the exact command(s) to a bash script in `.agents/state/decisions/drafts/`.
   - Name format: `YYYYMMDD-HHMMSS-<slug>.sh`
   - Include a comment at the top explaining exactly what the script does and why.
2. Present the drafted script to the human.
3. Wait for explicit human approval (HITL gate).

### Step 2: Commit

Only after the human explicitly replies with approval (e.g., "approved", "go ahead", "run it"):
1. Execute the drafted script.
2. Record the execution and its output in the milestone checkpoint.
3. Move the executed script from `drafts/` to `.agents/state/decisions/executed/` to maintain an audit trail.

## Example

**Human request**: "Force push my local changes to overwrite the broken main branch."

**Agent action (Draft)**:
1. I write `.agents/state/decisions/drafts/20260723-143000-force-push-main.sh` containing `git push origin main --force`.
2. I say: "I have drafted the force-push command. Please review the script at `...` and confirm if I should execute it."
3. I stop and wait.

**Human response**: "approved"

**Agent action (Commit)**:
1. I run `bash .agents/state/decisions/drafts/20260723-143000-force-push-main.sh`.
2. I log the success.
3. I move it to `executed/`.

## Rules

1. **No circumvention.** Do not try to bypass this by running the commands directly in a tool call. AGENTS.md rule 8 is absolute.
2. **One script per logical action.** Do not bundle unrelated destructive actions into a single draft.
3. **Always verifiable.** The draft script must be complete and syntactically valid bash.
