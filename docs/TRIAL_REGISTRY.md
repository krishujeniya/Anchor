# ANCHOR Trial Registry

This document serves as the immutable audit log for all ANCHOR Chaos Trials. It tracks hypotheses, evidence, and framework evolution decisions.

## Trial Overview

| Trial ID | Status | Target | Framework Version | Date |
|----------|--------|--------|-------------------|------|
| CT-001 | Complete | LFIM (Greenfield Node.js CLI) | v1.0 | 2026-07-24 |
| CT-002 | Planned | Papermill (Python) | v1.0 | TBD |
| CT-003 | Planned | TBD (Adversarial Environment) | v1.0 | TBD |

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

### CT-002: Legacy Codebase Context Navigation (Planned)

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
- **Pre-Registered Scorecard Template**:
  - *Governance*: Gates completed, Gates skipped, Human interventions, Resume events, Drift events
  - *Context*: Files analyzed, Files planned, Files modified, Planning precision, Context expansion, Scope expansions
  - *Engineering*: Tests passed, VERIFY failures, False VERIFY passes, Rework iterations, Token usage
  - *Evidence*: Framework defects discovered, Candidate improvements, Improvements promoted, Opinions rejected
- **Record**: *Awaiting Execution*

---

### CT-003: Adversarial Robustness (Planned)

- **Target Repository**: TBD
- **Hypotheses**: TBD
- **Record**: *Awaiting Execution*
