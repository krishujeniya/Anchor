# Error Handling Rules

These rules govern how errors are handled in any project using ANCHOR.

---

## Catching errors

1. **No bare `catch {}` or `catch (e) {}` blocks.** Every catch must either log the error with context, re-throw with additional context, or handle the error in a way that is visible and traceable. A catch that swallows an error silently is a bug, not a handler.

2. **Catch the narrowest exception type possible.** Catching `Exception` or `Error` at the top level hides bugs in code that was never expected to fail. Catch what you know how to handle; let everything else propagate.

3. **Never use exceptions for control flow.** Exceptions are for exceptional conditions. A user entering an invalid email is not an exception — it is a validation result. Use return values, result types, or explicit status codes for expected outcomes.

## Error content

4. **Errors include enough context to diagnose without reproducing.** Every logged error should answer: what operation was being attempted, what input triggered it, and what state the system was in. `"Error: failed"` is not an error message — it is a suppressed error message.

5. **Error messages are written for the person reading them, not the person writing them.** `"ENOENT: no such file or directory, open '/data/config.json'"` is useful. `"Error 17"` is not.

## Failing behavior

6. **Fail loudly on unexpected state.** If a function receives input it was not designed to handle, it must error immediately — not return a default, not silently skip, not log a warning and continue. Silent failures hide bugs and create cascading errors that are impossible to trace.

7. **External call failures are always handled explicitly.** API calls, file I/O, database queries, and subprocess executions can fail. Every one of these must have explicit error handling — never assume success. The handling may be a retry, a fallback, or a surfaced error, but it must be a conscious decision, not an omission.

## Cleanup

8. **Resources acquired in a try block are released in a finally block** (or equivalent: `defer`, `using`, `with`, RAII). A database connection opened in a try that only closes on the happy path leaks connections on every error.

9. **Retries have a cap and a backoff.** Never retry in a tight loop with no limit. Specify max retries, backoff strategy (linear or exponential), and what happens when all retries are exhausted. Log each retry attempt.
