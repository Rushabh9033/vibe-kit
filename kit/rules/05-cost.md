---
paths:
  - "**/*"
---

# Cost awareness — every model call is spend

## Per-call tagging (mandatory for production)

Every model call must carry metadata for cost attribution:

- `user_id` / `session_id` / `feature`
- `subsystem` (e.g., `search`, `summarize`, `code-review`)
- `model`, `model_version`
- `prompt_template_version`
- `tokens_in`, `tokens_out`, `cost_usd`
- `latency_ms`
- `ai_assisted=true|false`
- `finish_reason`

## Budgets (default; raise per project ADR)

| Bucket | Weekly cap | Alert at | Action on overflow |
|---|---|---|---|
| Total spend | $50 | $40 | Switch to cheaper tier / pause |
| Per-task spend | $5 | $4 | Escalate to human |
| Per-developer | $25 | $20 | Investigate misuse |
| Per-PR | $10 | $8 | Refactor spec |

## Cost caps (hard limits)

- Hard cap per user/session: HTTP 429 if exceeded.
- Soft cap per tenant/day/month: alert at 80%, throttle at 100%.
- Global cap per month: hard stop beyond.
- Per-feature spend cap with auto-disable on breach.

## When cost dominates the decision

- Use the cheapest tier that meets the accuracy bar (Haiku-class for boilerplate; Sonnet-class for business logic; Opus-class for architecture review).
- Cache aggressively. Deduplicate identical prompts within a session.
- Rate-limit AI retries; runaway retries are the most common cost spike.

## Cost dashboards (minimum)

- Real-time spend per feature per hour.
- Top 10 users by spend; top 10 prompts by spend.
- Trend vs 7-day rolling average; alert on > 30% daily deviation.
- Per-PR cost attribution; review at PR time, not after the fact.

## Reconciliation

Weekly: reconcile usage feed against provider invoice; track drift. Quarterly: review budget table vs actuals; raise or lower caps.
