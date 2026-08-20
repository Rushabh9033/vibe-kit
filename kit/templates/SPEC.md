# Product Spec

Status: draft | active | shipped
Owner: @handle
Last updated: YYYY-MM-DD
Milestone: <version or release name>

## Problem
<Who hurts. How much. Why now.>

## Goals (SMART)
- G1. <Specific, Measurable, Achievable, Relevant, Time-bound>
- G2.

## Non-goals
- NG1. <Explicitly NOT doing>
- NG2.

## Users
- Primary: <persona; what they need>
- Secondary: ...

## Success metrics
| Metric | Current | Target | Source |
|---|---|---|---|
| <leading> | X | Y | <measurement> |
| <lagging> | X | Y | <measurement> |

## User stories (high-level)
- As a <X>, I want <Y>, so that <Z>.

## Non-functional requirements
| Category | Requirement | Target | Measurement |
|---|---|---|---|
| Performance | P95 latency on /search | < 200 ms | k6 |
| Availability | Uptime | 99.9% | monitor |
| Security | All requests authenticated | 100% | SAST |
| Accessibility | WCAG 2.1 AA | All public | axe-core CI |
| Observability | Structured logs / traces | 100% | lint rule |
| Privacy | PII encrypted at rest | 100% | schema check |

## MoSCoW scope (this milestone)
- MUST: ...
- SHOULD: ...
- COULD: ...
- WON'T (this milestone): ...

## Out of scope
- ...

## Open questions
- [ ] Q1. <Owner? By when?>

## Links
- Per-feature specs: `docs/requirements/`
- ADRs: `docs/decisions/`
