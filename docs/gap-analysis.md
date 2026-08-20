# Gap analysis — what vibe-kit is, isn't, and what's missing

> Honesty is the only sustainable selling point.

## What this kit is

A **strong, opinionated synthesis** of public best practice for AI-assisted development as of 2026. Every section draws from Karpathy (vibe coding), Willison (vibe engineering), Cherny (CLAUDE.md compound corrections), Huntley (subagents), Osman (verification loops + .cursorrules), Levels (solo on VPS), and the *spec-coding.dev* / *prompt-driven-development.systems* work.

If you adopt it as written, you'll be in the top 5–10% of AI-assisted workflows.

## What this kit isn't (yet)

### Top 0.001%

Top 0.001% requires:

1. **Empirical validation in your context.** Targets ≠ measurement. Until we've run the pipeline on 3+ real features for 3+ months, the playbook is well-founded but uncalibrated to your stack, team, risk profile.
2. **Tooling actually wired, not paper templates.** Hooks on disk (we have those). Dashboards wired to OpenTelemetry (we describe them; not running). PR bots. Cost feeds (Langfuse, Helicone, Vantage, Portkey). Socket/Dependabot configured. SBOM per release. We described each; none are running.
3. **Calibration by stack, risk, team.** Regulated-medical workflow and solo-indie-SaaS share ~30%. Ours is one size.
4. **A meta-iteration loop.** Quarterly review of which sections pulled weight vs which were unused.
5. **Hard validation from edge cases we haven't seen.** A real hallucinated-package attack that hit prod. A model rollback that broke a flag path. A 50× cost spike from a runaway retry. These produce rules no one writes ahead of time.

### Empirical benchmark

We don't yet have:

- Mutation scores by AI age of code (does the AI-tolerance ratio drop with repo age?)
- Hallucination rate per surface area (we cite ~20%; what's yours?)
- AC-pass-rate per AC category (do AI teams systematically miss certain types of edge case?)
- Cost-per-feature in weeks of feature work (likely correlated with spec quality, not model tier)

## The four highest-ROI gaps

If you only fix four things beyond installing the kit, fix these:

1. **Slopsquatting prevention** — the slopsquatting rule is in `kit/rules/03-no-slopsquatting.md`, but the registry-check on every new dependency needs to be wired into CI (`npm audit`, `osv-scanner`, Socket, Dependabot) and gated.
2. **Mutation testing on AI-written code** — until you've actually run mutmut / Stryker / PIT against AI output, the verification floor in `kit/rules/02-verify.md` is your aspiration, not your state.
3. **Feature flags + canary + rollback** — every AI-built user-visible path should sit behind a flag, defaulting to "off for existing users." Until you have that, you ship without a killswitch.
4. **Per-feature cost tracking with caps** — runaway retries are the most common AI cost spike. Until you've instrumented per-call tokens/cost and set per-feature caps with auto-disable, you're one bad prompt away from a $10K day.

## Comparison matrix

| Capability | vibe-kit (this repo) | Top 0.001% teams |
|---|---|---|
| Spec-first workflow | ✅ Templates + rules | ✅ + measurement dashboard |
| Per-AC verification | ✅ Rank matrix | ✅ + mutation score by AI age |
| Memory / persistence | ✅ global CLAUDE.md + per-project AGENTS.md | ✅ + telemetry: which rules actually fire |
| Compound corrections | ✅ pattern documented | ✅ + automated ticket flow from `@.claude` review tag |
| Slopsquatting | ✅ rule + manual checklist | ✅ + automated registry check in CI on every dep |
| Cost tracking | ✅ budgets in rule | ✅ + per-feature live cap, auto-disable |
| Multi-AI (planner + coder) | ✅ role split + prompts/ | ✅ + measured handoff latency between roles |
| Mutation testing | ✅ rank-4 gate | ✅ + AI-age cohort tracking |
| Feature flags | ✅ in kill list | ✅ + per-AI-feature flag with rollout shadow |
| Incident response | ✅ postmortem template | ✅ + automated model-version correlation in alerts |
| Docs-as-code | ✅ AGENTS.md / CLAUDE.md / specs | ✅ + doc-drift dashboard |
| Adjusted to your context | ❌ (one-size) | ✅ (per stack/team) |

## The path from here to top 0.001%

In order of ROI:

1. **Pick a real feature, run the pipeline end-to-end, measure.** Mutation score, AC pass rate, cost, time. The single thing that takes us from synthesis to validity. 3 weeks.
2. **Wire the hooks + dashboards.** `.claude/settings.json` exists. Add OTel instrumentation, per-PR token/cost tracking. 1 day.
3. **Establish model + provider + budget via ADR.** Stop re-deciding. 1 day.
4. **Stand up dep-quarantine in CI.** Socket / osv-scanner / Phantom Guard. 1 week.
5. **Run mutation testing on first 3 AI-built features.** Surfaces whether the verification ranks are honest.
6. **Run one real AI-PR tabletop on a hostile spec.** Calibrates Rank 5/6/7 honestly. 2 hours.
7. **Quarterly review.** Drop what didn't move a metric; double down on what did.

Past 1% you're paying for telemetry and domain expertise we can't generate from a single window.

## What this file is for

When someone asks "is vibe-kit top 0.001%?", point them at this file. Be honest. The kit is a strong starting point; the rest is run, measure, drop, deepen.

## The principle

> **Top 0.001% is not a destination. It's a discipline.** You don't get there by reading more guides; you get there by running the same guide for months, measuring, and rewriting the parts that didn't move a number.
