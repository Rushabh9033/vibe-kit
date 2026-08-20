---
paths:
  - "**/*"
---

# Verification floors — don't ship under these ranks

| Rank | Check | When | Tool |
|---|---|---|---|
| 1 | lint + format | every edit | prettier/ruff/gofmt |
| 1 | typecheck | every edit | tsc/mypy |
| 2 | unit tests | every feature | framework-native |
| 2 | AC list vs tests | every feature | manual map (see plan.md) |
| 3 | integration / contract | every API | testcontainers/Pact |
| 4 | mutation testing | production code | mutmut/Stryker/PIT |
| 5 | E2E | customer-facing | Playwright/Cypress |
| 6 | perf / load | production, regulated | k6/Gatling |
| 7 | security / pen-test | production, regulated | OSWAP/mutation |

## Default floor by work maturity

- Toy / prototype → Rank 1 only (manual smoke).
- MVP → Rank 2 mandatory.
- Production → Rank 4 mandatory; Rank 5 for customer-facing.
- Regulated → Rank 7 mandatory.

## Test naming

Each test name echoes its AC: `test_AC1_upload_5MB_returns_200_with_variants`. Don't rename; the AC trace is the AI's audit.

## When the agent says "tests pass"

Run mutation testing. If mutation score < 70% on changed code, "tests pass" is theater — block ship.

## Tests-as-documentation

Each acceptance criterion is a green test, full stop. If an AC has no test, the spec is incomplete.
