---
description: Run verification ranks against current changes
---

Run verification ranks against current changes (or against the spec's AC list).

## Default ranks (raise per project ADR)

- **Rank 1**: lint + format + typecheck — must pass.
- **Rank 2**: unit tests against AC list — every AC must have a green test.
- **Rank 3**: integration / contract tests — if API touched.
- **Rank 4**: mutation score (mutmut/Stryker/PIT) — production code, ≥ 70% killed.
- **Rank 5**: E2E (Playwright/Cypress) — customer-facing flow.
- **Rank 6**: perf / load (k6/Gatling) — if NFR-SLA commits.
- **Rank 7**: security / pen-test — if auth/secret touched.

## Process

1. Read `docs/requirements/<feature>/spec.md` (if present) to know which ranks apply.
2. Run each applicable rank; capture command + brief output.
3. Build a report:

```
verifying feature=<name>
rank 1 (lint + typecheck):       pass  | <cmd> | <output>
rank 2 (unit tests vs AC list):  pass  | 14/14 ACs green
rank 3 (integration):            skip  | no API in this change
rank 4 (mutation):               fail  | score 62% (target 70%)
...
overall: BLOCK  (rank 4 < target)
```

4. **Block ship** if any mandatory rank fails. List the failing ranks.
5. If ranks 4/5/6/7 require tools not installed, **stop** and tell the user which to install before continuing.
