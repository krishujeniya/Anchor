# ANCHOR ⚓

![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)
![Build Status](https://img.shields.io/badge/build-passing-brightgreen.svg)

**A production-grade agentic development spine for Google Antigravity IDE.**

ANCHOR is a thin, self-contained layer of skills and state files that turns an agent-first IDE into a disciplined, self-verifying, audit-trailed development system. It acts as the "weight" that keeps AI autonomy grounded in verifiable state and computed gates.

## What it solves
AI coding agents often drift, rubber-stamp their own work, or get lost in long-running tasks. ANCHOR solves this by enforcing:
1. **Durable state** that survives context resets and cold sessions.
2. **Hard gates** so "done" is a computed verdict, not a claimed one.
3. **Maker/checker separation** so no agent grades its own work.
4. **Strict execution discipline** using the Draft-Commit pattern for dangerous operations.

## The 5-Gate Workflow
ANCHOR routes every multi-step development task through a strict pipeline:
1. **UNDERSTAND**: Explores intent and gathers requirements. (Outputs an artifact, requires human approval).
2. **ANALYZE**: Evaluates feasibility, risk, and scope. (Requires human approval).
3. **PLAN**: Builds architecture and the implementation plan. (Requires human approval).
4. **IMPLEMENT**: Writes code and tests autonomously. No human in the loop.
5. **VERIFY**: Proves the work is correct via deterministic checks (tests, linting) and a human Quiz-Me gate.

## Getting Started

**Setup steps (accurate, current as of Antigravity v1.20.3+, March 2026 update):**

1. Open your project in Antigravity.
2. Pick autonomy profile: **Review-driven development** — balanced, checkpoints, best default for most users, matches ANCHOR's own HITL table almost exactly.
3. Antigravity read `AGENTS.md` AND `GEMINI.md` at session start. Catch: **`GEMINI.md` win on conflict, `AGENTS.md` lose.** If a `GEMINI.md` already exist in project, add one line to it pointing at AGENTS.md so no silent override happen. If no `GEMINI.md` exist, skip this, no conflict.
4. Paste ANCHOR's install prompt (below) into agent chat once. Done — after that it run itself.

**Why "invisible" is doable**: the gate language (UNDERSTAND/ANALYZE/PLAN/etc) is internal bookkeeping, not something you must expose to user. Add one instruction line telling agent to narrate progress in plain human words ("looking into it… built a plan… implementing… testing now…") instead of naming gates out loud. Discipline stay enforced, user just see normal update.

**The one prompt** (paste as-is into Antigravity chat, once, in project root):

```text
I want to use the ANCHOR framework for this project, but keep it invisible to me day-to-day.

1. Download the framework from https://github.com/krishujeniya/Anchor and extract AGENTS.md and the .agents/ folder into the root of this project.
2. If a GEMINI.md already exists here, add a line to it: "See AGENTS.md for standing engineering rules — do not override its gates." If no GEMINI.md exists, skip this step.
3. Read AGENTS.md and strictly enforce the 5-Gate Workflow (Understand → Analyze → Plan → Implement → Verify) for every task from now on, with these adjustments:
   - Never say gate names, skill names, or internal jargon to me. Narrate progress in plain language only ("looking into requirements", "drafted a plan", "building it", "testing now", "done, here's what changed").
   - Only interrupt me for the things AGENTS.md actually requires a human for: requirements confirmation, scope/architecture approval, production deployment, anything legal/financial/personal-data, or a dangerous op (delete/migrate/force-push). Everything else, just do it and tell me what you did afterward.
   - Before claiming anything is "done," actually run the real check (test, lint, build) and show me the real output if I ask — don't just say it works.
   - If you ever detect drift, a stale milestone, or a failed check, tell me plainly what's wrong and what you recommend, don't bury it in status jargon.
4. Confirm setup by running bin/init.sh once, then tell me in one plain sentence that you're ready.
```

That's it. One-time paste, then normal conversation from there — ANCHOR run underneath, gates stay real, but nobody see the machinery unless they ask.

### 3. Local Web Dashboard
ANCHOR comes with a beautiful local web dashboard to visualize your agent's state, history, and telemetry in real-time. To launch it:
```bash
bash bin/dashboard.sh
```
Then open `http://localhost:8080/dashboard/` in your browser.

## Architecture
ANCHOR lives entirely inside the `.agents/` folder of your project. It requires zero third-party packages to operate its core spine, relying purely on native OS tools (`bash`, `jq`, `grep`, `python3`).
- `AGENTS.md` - The strict constitutional rules.
- `.agents/state/` - Where the active JSON and Markdown state lives.
- `.agents/skills/` - The isolated, targeted skills that enforce the gates.
- `dashboard/` - The premium visualizer for ANCHOR's state.
