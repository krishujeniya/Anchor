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
  - ANCHOR can build and maintain an accurate context graph for an unfamiliar legacy repository.
  - The 5-gate workflow scales without excessive friction on an existing codebase.
  - Quiz-Me remains effective when implementation spans dozens of files.
  - Resume quality remains high after long interruptions and context switches.
  - H5: ANCHOR should analyze only the code necessary to complete the assigned task, rather than attempting to understand the entire repository.
- **Record**: *Awaiting Execution*

---

### CT-003: Adversarial Robustness (Planned)

- **Target Repository**: TBD
- **Hypotheses**: TBD
- **Record**: *Awaiting Execution*
