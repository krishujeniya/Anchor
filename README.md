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

### 1. New Project Setup
If you have cloned this repository and want to start a completely new project, run the initialization script to wipe the existing development history and start fresh:
```bash
bash bin/init.sh
```

### 2. The Setup Prompts
Depending on how you are starting, copy and paste one of these exact prompts into your AI IDE (like Antigravity, Cursor, or Windsurf) to initialize the agent:

**Option A: For New Projects (You already cloned this repo)**
> *"You are operating within the ANCHOR framework. Please read `AGENTS.md` at the root of this project to understand your constitutional rules. Then, read `.agents/state/state.json` and `.agents/state/CURRENT.md` to see our current status. Strictly enforce the 5-Gate Workflow and never skip a gate."*

**Option B: For Existing Projects (You want the AI to install ANCHOR for you)**
> *"I want to use the ANCHOR framework for this project. Please download the framework from `https://github.com/krishujeniya/Anchor` and extract the `AGENTS.md` file and the `.agents/` folder into the root of my project. Once installed, read `AGENTS.md` and strictly enforce the 5-Gate Workflow going forward."*

## Architecture
ANCHOR lives entirely inside the `.agents/` folder of your project. It requires zero third-party packages to operate its core spine, relying purely on native OS tools (`bash`, `jq`, `grep`).
- `AGENTS.md` - The strict constitutional rules.
- `.agents/state/` - Where the active JSON and Markdown state lives.
- `.agents/skills/` - The isolated, targeted skills that enforce the gates.

<!-- Test 2 Iteration 1 Real Edit -->
<!-- Test 2 Iteration 2 Real Edit -->
<!-- Test 3 Iteration 1 Real Edit -->
<!-- Test 3 Iteration 2 Real Edit -->
