# Performance Rules

These rules govern performance-aware development in any project using ANCHOR.

---

## Blocking and concurrency

1. **No synchronous blocking operations in async contexts.** A synchronous file read or network call in an async handler blocks the entire event loop (Node.js) or thread pool (Python). Use the async equivalent or offload to a worker.

2. **Parallelize independent operations.** If three API calls don't depend on each other, run them concurrently (`Promise.all`, `asyncio.gather`, parallel subagents) — not sequentially. Sequential-by-default is the single largest unnecessary performance cost in agent-written code.

## Data loading

3. **Prefer lazy loading over eager loading.** Do not pre-load data, files, or modules until they are actually needed. This mirrors AGENTS.md rule 6 (context is just-in-time, not pre-loaded) and applies equally to application code.

4. **Large file reads use streaming or pagination, not full in-memory loading.** A 500MB log file loaded into memory for a grep is a crash waiting to happen. Stream line-by-line or paginate.

5. **Database queries specify only the columns and rows actually needed.** `SELECT *` is almost never correct in production code. Fetch what you use; index what you filter on.

## Measurement

6. **Performance claims require measurement.** "This is faster" without a benchmark is not a gate pass — it is an opinion. Measure before and after, report the numbers, note the conditions. This mirrors AGENTS.md rule 2 (computed, not narrated).

7. **Do not optimize without evidence of a problem.** Premature optimization adds complexity for no proven gain. Profile first, identify the bottleneck, optimize the bottleneck, measure the improvement. If there is no measurable improvement, revert the change.

## Resource management

8. **Close connections, handles, and streams when done.** An open database connection pool that grows without bound will exhaust available connections under load. Set pool size limits and close idle connections.

9. **Cache deliberately, not accidentally.** Every cache must have an explicit invalidation strategy (TTL, event-driven, or manual). A cache without invalidation is a stale-data source. Document what is cached, why, and how it expires.
