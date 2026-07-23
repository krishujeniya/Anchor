# Contributing to ANCHOR

Thank you for your interest in improving ANCHOR! As a strict, gate-driven agentic framework, we hold contributions to a very high standard.

## How to Contribute

1. **Fork the repository** and create your branch from `main`.
2. **Read the Constitution**: Ensure you have read `AGENTS.md`. No PR will be accepted if it breaks the 5-Gate Workflow or violates the Maker/Checker separation.
3. **Run the Checks**: Before submitting a PR, you must run:
   ```bash
   bash .agents/skills/anchor-verify/scripts/verify.sh .
   ```
4. **Test-Driven**: Following our Strict TDD rule, if you are contributing a new skill, please include the failing test proof in your PR description.
5. **Open a Pull Request**: Provide a clear description of the problem your PR solves.

## Code of Conduct
We expect all community members to act professionally, respectfully, and collaboratively. Any form of harassment or toxic behavior will not be tolerated.
