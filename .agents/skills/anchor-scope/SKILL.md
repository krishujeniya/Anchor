---
name: anchor-scope
version: 1.0.0
description: >
  Scores task complexity before spawning subagents, and sets least-privilege
  permission scope for the task. Prevents over-parallelizing trivial work and
  over-granting file/shell/network access.
---

# anchor-scope

You run this skill after `anchor-preflight` and before IMPLEMENT begins. Your job is two things:

1. **Score the task complexity** to decide whether it needs a single agent, a small swarm, or a full swarm.
2. **Set the permission scope** for the task — what files, commands, and network access the implementing agent(s) actually need.

## Complexity scoring

Score the task on six dimensions. Each dimension is 0-4 points. Total range: 0-24.

### Dimensions

| Dimension | 0 | 1 | 2 | 3 | 4 |
|-----------|---|---|---|---|---|
| **Files** | 1 file | 2-3 files | 4-7 files | 8-15 files | 16+ files |
| **Cross-refs** | Self-contained | References 1-2 other modules | References 3-5 modules | References 6-10 modules | Touches core abstractions used everywhere |
| **Risk** | Typo/formatting | Logic change, covered by tests | New feature, needs new tests | Security/auth/payments | Data migration or schema change |
| **Novelty** | Pattern exists, copy it | Adapt existing pattern | New pattern in this codebase | New pattern + external API | Greenfield architecture |
| **Verification** | One deterministic check | Multiple deterministic checks | Deterministic + manual check | Deterministic + browser/UI check | Requires production environment to verify |
| **Reversibility** | Fully reversible (git revert) | Reversible with some effort | Partially reversible | Requires rollback plan | Irreversible (deploy/delete/migrate) |

### How to score

For each dimension, pick the column that best matches the task. Record the score.

```
Files:       _/4
Cross-refs:  _/4
Risk:        _/4
Novelty:     _/4
Verification: _/4
Reversibility: _/4
Total:       _/24
```

### Score interpretation

| Score | Category | Agent strategy | Gate process |
|-------|----------|---------------|--------------|
| 1-5 | **Trivial** | Single agent | Skip to IMPLEMENT + lightweight VERIFY (deterministic checks only, no quiz-me). Per AGENTS.md rule 9. |
| 6-9 | **Standard** | Single agent | Full 5-gate process |
| 10-14 | **Complex** | Small swarm (2-3 subagents) | Full 5-gate process. Subagents return 1-2k token summaries (AGENTS.md rule 7). |
| 15-20 | **Major** | Full swarm (4+ subagents) | Full 5-gate process. Consider fresh-context-per-iteration (Ralph pattern). |
| 21-24 | **Critical** | Full swarm + human pairing | Full 5-gate process. Add extra HITL checkpoint mid-IMPLEMENT. |

### Examples

**Trivial (score 3)**: Fix a typo in a rule file.
- Files: 0 (1 file), Cross-refs: 0 (self-contained), Risk: 0 (formatting), Novelty: 0 (copy pattern), Verification: 0 (one check), Reversibility: 0 (git revert). **Total: 0** → but minimum for any tracked milestone is 1, so score is 1.

**Standard (score 8)**: Add a new quality rule file.
- Files: 1 (2-3 files — rule + AGENTS.md update), Cross-refs: 1 (references AGENTS.md), Risk: 1 (logic change), Novelty: 1 (adapt existing rule file pattern), Verification: 2 (deterministic + manual review), Reversibility: 0 (git revert). **Total: 6**.

**Complex (score 13)**: Add auth flow to an existing web app.
- Files: 3 (8-15 files — routes, middleware, models, tests, config), Cross-refs: 3 (touches auth, sessions, database, API layer), Risk: 3 (security/auth), Novelty: 2 (new pattern for this codebase), Verification: 2 (deterministic + manual), Reversibility: 0 (reversible). **Total: 13**.

## Permission scoping

After scoring, define the least-privilege permission scope for the task.

### Scope template

```
Permissions for: <milestone-id>
  files_read:  [list of directories/files the task needs to READ]
  files_write: [list of directories/files the task needs to WRITE]
  commands:    [list of shell commands the task needs to RUN]
  network:     none | [specific domains/APIs needed]
```

### Rules for scoping

1. **Start with nothing, add what's needed.** The default is no access. Each permission must be justified by a specific part of the implementation plan.
2. **Scope to directories, not the whole project.** If the task only changes `.agents/rules/`, don't grant write access to `.agents/skills/` or the project source code.
3. **Command access is specific.** "Run shell commands" is too broad. "Run `bash verify.sh`, `jq`, `find`" is correct.
4. **Network access is exceptional.** Most tasks need no network. If they do, name the specific domain or API (e.g., `api.github.com`, not "internet access").
5. **Document the scope in the checkpoint.** Record what permissions were granted and why, so the audit trail shows the task wasn't over-provisioned.

## Output format

Record in the checkpoint:

```
- scope: complexity <score>/24 (<category>)
  - files: <N>, cross-refs: <N>, risk: <N>, novelty: <N>, verification: <N>, reversibility: <N>
  - agent strategy: single | small swarm (N agents) | full swarm (N agents)
  - gate process: full | lightweight (trivial task, per AGENTS.md rule 9)
  - permissions:
    - read: <paths>
    - write: <paths>
    - commands: <list>
    - network: none | <domains>
```

## Rules

1. **Score before spawning.** Never spawn subagents before knowing the complexity score. Over-parallelizing trivial work wastes tokens and creates coordination overhead.
2. **The scorer does not implement.** You score and scope, then hand off to IMPLEMENT. You do not start writing code.
3. **Subagent summaries are capped.** Any subagent spawned by swarm mode returns a distilled summary of 1,000-2,000 tokens to the lead agent. Never the full trace. This is non-negotiable (AGENTS.md rule 7).
4. **Permission scope is logged.** If it's not in the checkpoint, the scope was not set. An unscoped task is an over-provisioned task.
