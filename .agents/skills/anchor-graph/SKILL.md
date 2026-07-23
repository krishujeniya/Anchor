---
name: anchor-graph
version: 1.0.0
description: >
  Builds and maintains context-graph.json from the codebase's import structure.
  Stores file paths and grep queries, not file contents — retrieval is just-in-time,
  pulled by the agent on demand. Human adds 2-3 invariants by hand after each run.
---

# anchor-graph

You run this skill during the PLAN gate to build or update the project's context graph. The graph captures the structural relationships in the codebase — what depends on what — so the agent can navigate efficiently without pre-loading entire files.

## What the context graph contains

```json
{
  "nodes": [
    {
      "id": "path/to/module",
      "type": "skill | rule | state | source | test | config",
      "grep_query": "a grep pattern to find this module's key exports/definitions"
    }
  ],
  "edges": [
    {
      "from": "path/to/importer",
      "to": "path/to/imported",
      "type": "imports | references | tests | configures"
    }
  ],
  "invariants": [
    "human-written health rule, e.g. 'rules/ files never reference specific frameworks'",
    "human-written health rule, e.g. 'anchor-verify never imports from anchor-orchestrator'"
  ]
}
```

## How to build the graph

### Option A — Use the scan script (recommended for code-heavy projects)

Run the companion script to auto-detect imports:

```bash
bash .agents/skills/anchor-graph/scripts/scan.sh /path/to/project
```

The script:
1. Detects project languages (JS/TS, Python, Go, Rust, or markdown-only).
2. Scans import/require/include statements.
3. Outputs `nodes` and `edges` arrays to stdout as JSON.
4. You merge the output into `.agents/state/context-graph.json`, preserving any existing `invariants`.

### Option B — Manual scan (for small or non-code projects)

For projects that are mostly markdown/config (like ANCHOR itself):

1. List all significant files: `find . -name "*.md" -o -name "*.json" -o -name "*.sh" | grep -v node_modules | grep -v .git | sort`
2. For each file, note what it references (other files, function names, config keys).
3. Build nodes and edges manually.

## After building the graph

1. Write the updated graph to `.agents/state/context-graph.json`.
2. **Ask the human to add 2-3 invariants.** These are health rules that should always be true about the codebase's structure. Examples:
   - `"skill files never import from state/ directly — they instruct the agent to read state"`
   - `"rules/ files are self-contained — no cross-references between rule files"`
   - `"every skill has a SKILL.md with name and description in YAML frontmatter"`
3. The invariants are used by `anchor-verify` to detect structural drift.

## When to re-run

- At every PLAN gate (to catch new files/dependencies since the last milestone).
- After any major refactor.
- The graph is a snapshot — it goes stale. Re-running is cheap.

## Rules

1. **Store paths and queries, not file contents.** The graph is an index, not a cache. Context is just-in-time (AGENTS.md rule 6).
2. **Never invent edges.** Only record relationships you found by scanning actual import statements or explicit file references. If you're guessing, you're wrong.
3. **Invariants are human-written.** The agent proposes, the human writes. Do not auto-generate invariants — that defeats the purpose of having a human encode their architectural intent.
4. **Preserve existing invariants** when updating the graph. Only the human adds or removes invariants.
