# ANCHOR Trial Registry

This document serves as the immutable audit log for all ANCHOR Chaos Trials. It tracks hypotheses, evidence, and framework evolution decisions.

## Trial Overview

| Trial ID | Status | Target | Framework Version | Date |
|----------|--------|--------|-------------------|------|
| CT-001 | Complete | LFIM (Greenfield Node.js CLI) | v1.0 | 2026-07-24 |
| CT-002 | Complete | Papermill (Python) | v1.0 | 2026-07-24 |
| CT-003 | Complete | Papermill (Adversarial Environment) | v1.0 | 2026-07-24 |

---

## Trial Records

### CT-001: Greenfield Workflow Validation

- **Target Repository**: Local File Integrity Monitor (LFIM) - newly created.
- **Commit SHA**: Initial execution boundary.
- **Hypotheses**: 
  - ANCHOR can execute the 5-gate workflow end-to-end without breaking consistency.
  - TDD discipline integrates effectively with deterministic verification.
- **Success Metrics**: 5/5 gates completed, 0 skipped.
- **Final Scorecard**: 
  - Framework defects discovered: 2
  - Deterministic verification failures: 0 (after implementation)
  - Drift events detected: 1
- **Findings**:
  - The workflow is highly durable, but the Quiz-Me gate lacked portability.
  - Out-of-band state changes trigger hard drift failures, proving preflight works.
- **Framework Changes Proposed**:
  - Centralized state abstraction layer.
  - Evidence-backed Quiz-Me format (inline snippets).
- **Framework Changes Accepted**:
  - State abstraction layer implemented (v1.0.x patch).
  - Quiz-Me format adopted as a methodology upgrade.
- **Links**: `engineering_report.md` (CT-001)

---

### CT-002: Legacy Codebase Context Navigation

- **Target Repository**: Papermill (Python)
- **Selection Criteria**:
  - *Required*: Existing Git history, active tests, multiple modules, 10k-100k LOC, existing bugs/feature requests, clear architecture.
  - *Preferred*: Real users/contributors, CI configured, documentation present.
  - *Avoid*: Tutorial repos, generated code, monoliths with no tests.
- **Hypotheses**: 
  - H1: ANCHOR can build and maintain an accurate context graph for an unfamiliar legacy repository.
  - H2: The 5-gate workflow scales without excessive friction on an existing codebase.
  - H3: Quiz-Me remains effective when implementation spans dozens of files.
  - H4: Resume quality remains high after long interruptions and context switches.
  - H5 (Context Efficiency): ANCHOR analyzes only necessary code. (Measured by Planning Precision = Modified÷Planned and Context Expansion = Planned÷Analyzed).
  - H6 (Scope Stability): Once out of PLAN, implementation does not require major scope expansion unless justified by new evidence.
- **Trial-Specific Rules**:
  - *Strict Context Scoping*: During IMPLEMENT, no reading unrelated files unless justified by new evidence. Every new file opened after PLAN must have a recorded reason (e.g., test failure, newly discovered dependency).
- **Final Scorecard**:
  - *Governance*: 5/5 gates completed, 0 skipped, 1 baseline verification delay (passed).
  - *Context*: 4 files analyzed, 3 files planned, 3 files modified. Planning Precision: 1.0 (100%). Context Expansion: 0.75 (75%). 0 scope expansions.
  - *Engineering*: 548 tests passed. VERIFY failures: 0. False VERIFY passes: 0. Rework iterations: 0.
  - *Evidence*: Validated that targeted structural traversal is far more efficient than global indexing for legacy repos.
- **Findings**:
  - H5 (Context Efficiency) was strongly supported. The framework achieved perfect Planning Precision without over-reading files.
  - H6 (Scope Stability) was validated. The agent accurately ruled out the `engines.py` abstraction and successfully stayed within the 3-file footprint defined in `PLAN`.
  - Enforcing a clean baseline test suite (and waiting for environment setup) creates friction upfront but guarantees clean TDD cycles.
- **Framework Changes Proposed**:
  - Add Environment Readiness metrics (clone-to-test time, manual interventions, dependencies) as a standard trial metric.
  - Add a "Discovery Log" during the `UNDERSTAND` phase.
- **Framework Changes Accepted**:
  - Environment Readiness and Discovery Logs adopted as methodology upgrades.
- **Links**: `CT-002_engineering_report.md`

---

### CT-003: Adversarial Robustness

- **Target Repository**: Papermill (Python)
- **Hypotheses**: 
  - H7 (Drift Recovery): Framework halts if human modifies files mid-IMPLEMENT.
  - H8 (State Resilience): Framework recovers if state is corrupted.
  - H9 (Conflict Resolution): Framework handles unexpected upstream merge conflicts gracefully.
- **Trial Setup**: Implemented a `--global-timeout` feature touching CLI, orchestrator, and engine wrapper, opening vulnerability windows at `PLAN`, `IMPLEMENT`, and `VERIFY`.
- **Final Scorecard**:
  - *Governance*: 5/5 gates completed, 0 skipped.
  - *Chaos Metrics*: 0 injections detected, 0 recovered.
- **Findings**:
  - The Adversary (human investigator) repeatedly approved gates without injecting out-of-band chaos (fast-forwarding).
  - Consequently, hypotheses H7, H8, and H9 remain *untested* in practice.
  - The framework's core 5-gate workflow remains robust under rapid human interaction.
- **Framework Changes Proposed**:
  - Future adversarial trials should use an automated chaos script (e.g., cron jobs that randomly delete files) rather than relying on the human to inject sabotage during HITL checkpoints.
- **Links**: `CT-003_engineering_report.md`
