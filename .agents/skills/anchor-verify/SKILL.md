---
name: anchor-verify
description: >
  Runs as a separate context from whatever wrote the code — maker never grades
  its own work. Deterministic checks (typecheck, lint, tests) run first and are
  the primary gate. Browser subagent / LLM judgment used only for what can't be
  asserted deterministically (visual UI, UX flow). Ends with a quiz-me gate.
---

# anchor-verify

You are the verifier. You did not write the code you are about to check. You operate as a **genuinely separate evaluation pass** — you read only the goal, the spec, and the artifact. You do not read your own reasoning from the IMPLEMENT phase. You do not carry over "why I made this choice" context from the builder.

## Before you start

1. Read the **goal** — what was requested (from the checkpoint header or CURRENT.md).
2. Read the **spec** — what was planned (from the Implementation Plan artifact or the PLAN gate checkpoint entry).
3. Read the **artifact** — what was actually built (the files on disk).
4. Do NOT read the builder's reasoning, conversation history, or process notes.

## Step 1 — Deterministic checks (always first, always primary)

Run every applicable check for the project's stack. Record each command and its full output.

### For ANCHOR's own codebase (markdown + JSON + bash):

```bash
# Run the verify script:
bash .agents/skills/anchor-verify/scripts/verify.sh

# If ANCHOR skills (.agents/skills/* or bin/*) were modified, also run the eval harness to check for historical regressions:
bash bin/eval.sh
```

The script checks:
- JSON syntax validation (all `.json` files via `jq`)
- Bash syntax validation (all `.sh` files via `bash -n`)
- SKILL.md frontmatter validation (required `name` and `description` fields)
- State schema validation (`state.json` required fields)
- File structure validation (expected directories exist)

### For JavaScript/TypeScript projects:

```bash
# TypeScript type checking (if tsconfig.json exists):
npx tsc --noEmit

# Linting (if eslint config exists):
npx eslint . --max-warnings 0

# Tests:
npm test
```

### For Python projects:

```bash
# Type checking (if mypy is available):
mypy . --ignore-missing-imports

# Linting:
ruff check .

# Tests:
pytest -v
```

### Stack detection

If you're unsure what checks to run, detect the stack:
```bash
# What's in the project?
ls package.json tsconfig.json pyproject.toml setup.py Cargo.toml go.mod 2>/dev/null
```

Run whatever checks are available. If NO deterministic checks exist for the stack, say so explicitly and note that the verification is judgment-based only (this is rare and should be flagged).

## Step 2 — Handle failures

- Any deterministic check **failure** → verdict is **REJECT**.
- Send specific, actionable feedback to the IMPLEMENT gate: what failed, why, and what to fix.
- IMPLEMENT retries once. If the second attempt also fails → **halt and surface to human**.

## Step 3 — Invariant check

If `context-graph.json` has invariants, check each one:

```bash
# Example: "rules/ files never reference specific frameworks"
grep -rn "React\|Angular\|Vue\|Express\|Django" .agents/rules/ 2>/dev/null
# Expected: no output. Any output = invariant violation.
```

Record each invariant checked and its result.

## Step 4 — Browser verification (UI work only)

Only if:
- The milestone involves user-visible UI changes, AND
- No deterministic check covers the visual requirement.

Then invoke Antigravity's browser subagent to:
1. Navigate to the relevant page.
2. Take a screenshot.
3. Record a short interaction video.
4. Produce a Browser Recording artifact.

**Label this as judgment-based verification.** Browser verification APPROVE is provisional — it does not stand alone for production deployment (AGENTS.md rule 4).

## Step 5 — Quiz-me gate

Generate exactly **three** questions for the human:

1. **Design decision**: "Why was X chosen over Y?" — tests that the human understands the architectural choice, not just that something works.
2. **Edge case**: "What happens when Z?" — tests awareness of boundary conditions, failure modes, or unusual inputs.
3. **Change impact**: "What else in the codebase does this affect?" — tests understanding of ripple effects beyond the immediate change.

Present all three questions. Wait for the human to answer.

### Evaluating answers

- Human answers all three → proceed to verdict.
- Human cannot answer one or more → verdict is **UNCERTAIN**. The milestone stays open. Record which question(s) were unanswered and why.
- "I don't know" or equivalent is a valid signal that the PLAN gate was underspecified — feed that back.

## Step 6 — Record verdict

Append a verify block to the checkpoint:

```markdown
## verify · <timestamp>
- deterministic checks:
  - <check-name>: PASS | FAIL (command: `...`, output: `...`)
  - <check-name>: PASS | FAIL (command: `...`, output: `...`)
- invariant checks:
  - "<invariant text>": PASS | FAIL
- browser verification: N/A | PASS | FAIL (provisional)
- quiz-me:
  - Q1 (design decision): <question> → <answer>
  - Q2 (edge case): <question> → <answer>
  - Q3 (change impact): <question> → <answer>
- verdict: APPROVE | REJECT | UNCERTAIN
- rationale: <one-line explanation>
```

## Verdict meanings

| Verdict | What happens next |
|---------|-------------------|
| **APPROVE** | Milestone is marked complete. Walkthrough artifact is generated. |
| **REJECT** | Returns to IMPLEMENT with specific feedback. One retry allowed. |
| **UNCERTAIN** | Milestone stays open. Human must resolve the open question(s) before re-running VERIFY. |

## Rules

1. **You are not the builder.** Do not defend the implementation. Do not explain why choices were made. Evaluate the artifact against the spec.
2. **Deterministic checks are not optional.** If they exist for the stack, they run. Skipping a deterministic check to get to a "pass" is itself a failure.
3. **Record everything.** Every command, every output, every verdict reasoning. An unrecorded check is an unrun check (AGENTS.md rule 1).
4. **Never approve what you haven't checked.** "Looks good to me" is not a verify result. It is a verify skip.
