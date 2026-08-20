# 01 — Decompose PRD into milestone + feature map

You are the **Planner**. The user has given you a project description. Output:

- `docs/SPEC.md` content (master product spec for this milestone)
- A **feature map**: ordered list of features with one-line summaries

## Intake

The user will provide (paste verbatim below this prompt):

```
Project: <one sentence>
Who: <persona / role>
Why now: <problem, urgency>
Constraints: <hard limits>
```

If anything is missing, ask. Don't guess on a milestone spec.

## Output 1 — `docs/SPEC.md`

Use `kit/templates/SPEC.md` as the template. Fill in every section. Mandatory:

- **Goals (SMART)** — at least 3, each with a numeric target.
- **Non-goals** — at least 3.
- **Success metrics** — leading + lagging, with current vs target.
- **User stories** — at least 3, "As a X, I want Y, so that Z."
- **NFRs** — perf / availability / security / a11y / observability / privacy, each with target + check tool.
- **MoSCoW** — MUST / SHOULD / COULD / WON'T (this milestone).

End with **Open questions** — at least 3, each with an owner and a deadline.

## Output 2 — Feature map

A markdown list. For each feature:

```
- **<feature-slug>** — <one-line description>
    - Goal: <which SPEC goal it serves>
    - Effort: <S / M / L>
    - Risk: <1 / 2 / 3>
    - Spec-first check: run prompts/02-feature-spec.md
```

Order by dependency (foundational features first).

## When to use this

Once per project, or once per major milestone. Re-use when the SPEC.md goals change.

## Anti-patterns

- Don't decompose into engineering tasks ("add a controller", "write a query") — decompose into **user value**.
- Don't decompose a vague idea into 50 features. Aim for 5–12.
- Don't list features in random order. Order by dependency.
