# Ceremony Levels

Not every change deserves the full Planner → Spec → Plan → Coder → Verify → Ship ritual. Match the ceremony to the change. Over-process kills velocity; under-process kills quality.

## The four levels

| Level | When | Pipeline |
|---|---|---|
| **Tiny** | Typo, comment fix, config tweak, ≤ ~10 lines, no behavior change | Edit → `/vibe-handoff` |
| **Normal** | Single feature, ≤ 2 ACs, no NFRs, no auth, no migration | `/vibe-spec` → user review → Coder → `/vibe-verify` → `/vibe-ship` |
| **Large** | Multi-AC feature, has NFRs, no auth/migration | `/vibe-spec` → user review → `/vibe-plan` → Coder → `/vibe-verify` → `/vibe-ship` |
| **Critical** | Auth, billing, schema, public API, anything irreversible | `/vibe-spec` → user review → `/vibe-plan` → `/vibe-decide` for any irreversible choice → Coder → `/vibe-verify` + mutation testing → `/vibe-ship` |

## How to pick

Ask these three questions:

1. **Does it touch auth, billing, migrations, or public APIs?**
   - Yes → **Critical**.
   - No → next.

2. **Does it have > 2 acceptance criteria or any NFRs (perf / a11y / security / observability)?**
   - Yes → **Large**.
   - No → next.

3. **Does it change observable behavior (UI, API response, DB write)?**
   - Yes → **Normal**.
   - No (typo, comment, internal refactor) → **Tiny**.

## What each level skips

| Step | Tiny | Normal | Large | Critical |
|---|---|---|---|---|
| Discovery interview | optional | required | required | required |
| `docs/requirements/<slug>/spec.md` | no | yes | yes | yes |
| User approval gate | no | **required** | **required** | **required** |
| `docs/requirements/<slug>/plan.md` | no | optional | yes | yes |
| ADR for irreversible choices | no | no | optional | **required** |
| `/vibe-verify` | no | yes | yes | yes |
| Mutation testing (rank 4) | no | no | optional | **required** |
| `/vibe-ship` (CHANGELOG + handoff) | no | yes | yes | yes |

## Examples

- **"Fix the typo on the homepage hero."** → Tiny. Edit the file, commit.
- **"Add a 'forgot password' link to the login form."** → Normal. 1 AC, no NFRs, no auth change (the auth flow is unchanged; you're just adding a link).
- **"Build the OAuth login flow."** → Critical. Auth, multiple ACs, NFRs (CSRF, rate limiting, observability), requires ADR for token storage choice.
- **"Refactor the user model into a separate package."** → Large. No observable behavior change but the diff is large and risky.
- **"Add `ai_assisted` tags to all model calls."** → Normal. Multi-AC but observability only.

## Anti-patterns

- **Tiny work getting the full Normal pipeline.** "I just fixed a typo but I wrote a 200-line spec." Stop.
- **Critical work treated as Normal.** "I added a new auth provider real quick." This is how production breaks.
- **Defaulting to Large "just to be safe."** Pick the smallest ceremony that still catches the real risks. Save the heavy ritual for the work that needs it.

## Why this exists

The kit is a **speed multiplier**, not process overhead. A 1-line change shouldn't require six artifacts. A production auth change shouldn't ship without three. Ceremony levels make the kit adapt to the work — not the other way around.
