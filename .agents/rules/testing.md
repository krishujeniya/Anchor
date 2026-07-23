# Testing Rules

These rules govern how tests are written and maintained in any project using ANCHOR.

---

## What must be tested

1. **Every user-facing behavior gets a test before the milestone leaves IMPLEMENT.** A feature without a test is not implemented — it is a draft. The test is the proof the feature works, not the code.

2. **Bug fixes include a regression test.** The test must fail before the fix and pass after it. If you can't write a test that reproduces the bug, document why in the checkpoint before proceeding.

## How tests are written

3. **Test names describe the scenario, not the function.** Use `"rejects expired token"` or `"returns empty list when no results match"`, not `"test_auth_3"` or `"test_search"`. A failing test name should tell you what broke without reading the test body.

4. **One assertion per test unless the assertions are logically inseparable.** A test that checks five unrelated things fails on the first one and hides the other four. Split them.

5. **Mock external dependencies at the boundary, not internal functions.** Mock the HTTP client, not the function that calls it. Internal mocking creates tests that pass when the code is wrong and fail when the code is refactored correctly.

## Where tests live

6. **Test files live alongside the code they test** (co-location). `auth.ts` and `auth.test.ts` in the same directory, not in a separate `/test` tree. Exception: integration and end-to-end tests that span multiple modules belong in a dedicated `tests/` directory at the project root.

## What is never acceptable

7. **Never delete or skip a failing test to make a build pass.** Fix the code, or update the test with a written rationale for why the expected behavior changed. Skipped tests are tech debt with no tracking — they rot silently.

8. **Never commit a test that depends on execution order, wall-clock time, or network availability.** Tests must be deterministic and runnable offline. Use fixed timestamps, seeded random values, and stubbed network calls.

9. **Never write a test that only asserts "no error was thrown."** That test passes for every possible wrong output. Assert on the actual result.
