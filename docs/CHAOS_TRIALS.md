# ANCHOR Chaos Trials Methodology

This document outlines the evaluation methodology for the ANCHOR framework. It is a governance document for humans and reviewers, completely separate from `AGENTS.md` (which defines runtime execution rules).

## 1. Purpose
Chaos Trials exist to validate whether the ANCHOR framework remains resilient under stress. The framework evolves strictly through gathered evidence, not intuition or hypothetical friction. Chaos Trials bridge the gap between framework *development* and framework *validation*, ensuring that rules and skills hold up in real, messy engineering environments.

## 2. Trial Lifecycle
Every trial must follow this standard sequence:
1. **Pre-register hypotheses**: Define expectations and metrics before touching code.
2. **Define quantitative metrics**: Setup scorecards to capture the data.
3. **Freeze ANCHOR**: No framework development is allowed during the trial.
4. **Execute the trial**: Perform the engineering tasks strictly following ANCHOR's gates.
5. **Record observations**: Document what worked and what failed.
6. **Classify findings**: Organize evidence into strengths, defects, or opinions.
7. **Decide graduation**: Evaluate whether the evidence justifies promoting an improvement into framework policy.

## 3. Pre-registered Hypotheses (Required)
Before starting, reviewers must record:
- **Hypotheses**: What behavior is being tested?
- **Expected strengths**: Where should the framework succeed?
- **Expected weaknesses**: Where might the framework fail?
- **Success criteria**: What constitutes a clear win?
- **Failure criteria**: What constitutes a critical breakdown?
- **Metrics**: Exactly what will be measured?
*(Note: These criteria must not be changed once the trial begins.)*

## 4. Trial Types
Each trial type answers distinct questions about the framework's capability:
- **Trial #1 – Greenfield**: Workflow validation. Can the 5-gate pipeline be followed end-to-end?
- **Trial #2 – Legacy**: Context management and navigation. Can the framework index and operate within an unfamiliar, structurally complex codebase without ballooning context?
- **Trial #3 – Adversarial**: Robustness and recovery. Can the framework detect and recover from manual drift, broken tests, merge conflicts, and extreme context switching?

*Selection Guidelines*: Target repositories must feature sufficient architectural complexity, realistic maintenance tasks, and multiple interacting modules. Arbitrary language or LOC constraints are less important than the presence of genuine technical debt and history.

## 5. Required Metrics
During trials, the following quantitative metrics must be captured to allow comparison:
- Gates completed / Gates skipped
- Initial context graph coverage
- Context graph growth (targeted vs bloated)
- Files analyzed vs. files modified
- Resume accuracy (recovering from state without re-analysis)
- Drift events detected
- False dependency discoveries
- Human corrections required
- False VERIFY passes

## 6. Evidence Classification
Every finding from a trial must be strictly classified:
- **Verified Strength**: Proven capability backed by execution logs.
- **Verified Defect**: Identifiable failure backed by execution logs.
- **Candidate Improvement**: A solution proposed to address a verified defect.
- **Opinion / Hypothesis**: Intuition-based ideas that lack trial evidence.

## 7. Promotion Policy
Improvements graduate into the framework based on this scale:
- **Promote**: Observed in at least 2 independent trials with consistent evidence.
- **Investigate**: Observed once, or the evidence is mixed/inconclusive.
- **Reject**: Unsupported by evidence or contradicted by later trials.

## 8. Threats to Validity
To maintain credible conclusions, record any factors that could have biased the trial outcome:
- Was the framework modified mid-trial?
- Did the reviewer already possess deep knowledge of the test codebase?
- Were the tasks artificially simple?
- Were interruption/recovery scenarios skipped?
- Was the repository too small to test context scaling?
- Were manual fixes applied out-of-band but not recorded in checkpoints?
- Were the pre-registered success criteria altered mid-trial?
