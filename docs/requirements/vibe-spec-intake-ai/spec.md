# Feature: vibe-spec-intake --ai mode (AI-assisted intake)

Status: shipped
Owner: @Rushabh9033
Last updated: 2026-08-21
Linked milestone: docs/SPEC.md ## "v0.x weapon suite"

> `vibe-spec-intake` produces a Spec template with 5 generic AC stubs.
> That's "force enumeration," not "AI-assisted." The upgrade: when
> `--ai` is passed, generate intent-specific ACs, constraints, edge
> cases, and non-goals using the user's AI assistant. The template
> remains as the fallback.

## Goal

Add an opt-in `--ai` mode to `vibe-spec-intake` that uses the user's AI
assistant (currently `claude` CLI) to decompose a 1-line intent into a
complete Spec with intent-specific ACs. Default behavior is preserved
— `--ai` is explicit.

## Acceptance Criteria (final)

All ACs shipped; see `tests/weapons/test-spec-intake-ai.sh` (8 assertions).

## Constraints

- Bash 3.2 portable.
- AI invocation is explicit (`--ai`), never default.
- AI failures (no CLI, non-zero exit, output validation fail) fall back
  to template with a warning to stderr. Never silently break.
- The prompt template is part of the kit at `kit/prompts/spec-intake.md`.

## Verification

End-to-end:

```bash
# Logged into claude CLI once.
vibe-spec-intake webhook \
  "send an HMAC-signed POST to a customer URL on order shipped" \
  --ai
# Open docs/requirements/webhook/spec.md; ACs should already name HMAC,
# idempotency, retries, signature verification, etc.
```

## Ship notes

- Prompt template uses `{{INTENT}}`, `{{SLUG}}`, `{{DATE}}` placeholders.
- AI output validated against intent keywords (length ≥ 4); failure → fallback.
- Output of the AI is captured verbatim into `spec.md`. Status is `awaiting-approval`.
