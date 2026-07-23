---
name: anchor-preflight
version: 1.0.0
description: >
  Runs before any milestone starts. Checks whether the work is already built,
  partially built, or unbuilt by reading state.json, checkpoints, and grepping
  the codebase for the symbols the plan proposes. Never assumes — searches first.
---

# anchor-preflight

You run this skill before IMPLEMENT begins on any milestone. Your job is to determine whether the planned work already exists, partially exists, or needs to be built from scratch. You return one of three verdicts: **UNBUILT**, **PARTIAL**, or **BUILT**.

## When to run

After the PLAN gate is approved and before IMPLEMENT starts. The orchestrator calls you here.

## Inputs you need

1. The **milestone goal** — what is being built (from the checkpoint or CURRENT.md).
2. The **planned deliverables** — the specific files, functions, or components the plan says to create (from the Implementation Plan artifact).

## How to check

For each planned deliverable, run these checks in order:

### Step 0 — Check for out-of-band drift

```bash
# Has a human edited files since ANCHOR last ran?
bash bin/drift-check.sh
```

If drift is detected (script returns non-zero), you MUST read the drifted files to understand what changed before proceeding with your other checks. Do not ignore drift.

### Step 1 — Check state for prior completion

```bash
# Has this milestone already been completed?
grep -l "COMPLETE\|APPROVE" .agents/state/checkpoints/<milestone-id>.md 2>/dev/null
```

If the checkpoint shows a VERIFY APPROVE verdict, the milestone is already done.

### Step 2 — Check for existing files

For each file the plan says to create:

```bash
# Does the file already exist?
test -f <planned-file-path> && echo "EXISTS: <planned-file-path>" || echo "MISSING: <planned-file-path>"
```

### Step 3 — Check for existing symbols

For each function, class, or component the plan says to create:

```bash
# Get linked repos
LINKED=$(jq -r '.linked_repos[]?' .agents/config.json 2>/dev/null || echo "")

# Does the symbol already exist in the codebase or linked repos?
grep -rn "<symbol-name>" --include="*.ts" --include="*.js" --include="*.py" --include="*.md" . $LINKED 2>/dev/null | grep -v node_modules | grep -v .git
```

### Step 4 — Check for partial implementations

```bash
# Are there TODO/FIXME markers in relevant files?
grep -rn "TODO\|FIXME\|PLACEHOLDER\|NOT IMPLEMENTED" <relevant-paths> 2>/dev/null
```

## How to decide the verdict

| Condition | Verdict |
|-----------|---------|
| All planned files exist AND checkpoint shows APPROVE | **BUILT** — halt, tell orchestrator the work is already done, surface the artifact location |
| Some planned files exist OR symbols partially match | **PARTIAL** — tell orchestrator what exists, recommend revising the milestone to "extend/complete X" rather than "build X from scratch" |
| No planned files exist, no matching symbols found | **UNBUILT** — tell orchestrator to proceed with IMPLEMENT as planned |

## Output format

Record your verdict in the checkpoint exactly like this:

```
- preflight: <VERDICT> — checked <N> planned deliverables
  - <file-or-symbol>: EXISTS | MISSING | PARTIAL (reason)
  - <file-or-symbol>: EXISTS | MISSING | PARTIAL (reason)
```

## Rules

1. **Never assume.** Always grep/test. "I think this exists" is not a preflight result.
2. **Check the actual file, not just the path.** A file that exists but is empty or a stub is PARTIAL, not BUILT.
3. **If you find the work is BUILT, do not proceed to IMPLEMENT.** Surface the existing artifact location to the human and the orchestrator. Rebuilding already-done work wastes tokens and risks regression.
4. **Record every check you ran** in the checkpoint. An unrecorded check is an unrun check (AGENTS.md rule 1).
