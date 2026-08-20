# Feature: vibe-verify (AC↔test contract checker)

Status: in-progress
Owner: @Rushabh9033
Last updated: 2026-08-20
Linked milestone: vibe-kit v0.2 — make vibe-verify a real contract checker

## Scope

Replace the 34-line stub markdown `/vibe-verify` slash command with a real
bash script that parses the feature's spec.md, extracts acceptance criteria,
checks the git diff for keyword matches per AC, runs the detected test suite,
and emits a structured PASS/BLOCK report.

## Not in scope

- Mutation testing (rank 4). The v0.2 verifier is keyword-based; mutation
  comes later.
- Multi-spec batch verification. The v0.2 script runs one spec at a time.
- Cross-repo / monorepo features.

## User-facing behavior

The user runs `kit/bin/vibe-verify` (or `/vibe-verify` in Claude Code) on
their feature branch. They get a stdout report like:

```
verifying feature=<slug>
spec=docs/requirements/<slug>/spec.md

AC contract:
  ✓ AC1. <text>           implemented: src/foo.ts
  ✗ AC2. <text>           NOT IMPLEMENTED in current diff
  ...

summary: N/M ACs have implementation in the diff
test runner: <cmd>
  ✓ tests pass | ✗ tests FAIL

scope creep check: <files>
overall: PASS | BLOCK
```

Exit codes: 0 = PASS, 1 = BLOCK (missing ACs or failing tests), 2 = usage
error (no spec, no git).

## Acceptance criteria (each = one test)

- [ ] AC1. vibe-verify bash script lives at `kit/bin/vibe-verify` and is executable
- [ ] AC2. script extracts acceptance criteria from `docs/requirements/<feature>/spec.md`
- [ ] AC3. for each AC, script greps the git diff for stem-form keyword matches
- [ ] AC4. script auto-detects test runner (jest / vitest / mocha / pytest / go test / cargo test)
- [ ] AC5. script runs detected tests and surfaces tail of failure log
- [ ] AC6. script emits structured PASS/BLOCK report and exits with the correct code
- [ ] AC7. slash command `/vibe-verify` documents usage and output format

## Verification plan

- Run `kit/bin/vibe-verify` against a fake feature repo (one AC implemented,
  one not) — confirm correct PASS/BLOCK output.
- Run `kit/bin/vibe-verify` against this very spec — confirm self-verification.

## Risks

| ID | Risk | L | I | Mitigation |
|---|---|---|---|---|
| R1 | Keyword matching has false positives | 3 | 2 | Document the limit in the slash command; eyeball each match |
| R2 | Keyword matching has false negatives (e.g. AC about "uploads" matching file "upload.ts" via stem-form) | 3 | 2 | Stem-form is the mitigation; tradeoff is documented |
| R3 | Test runner auto-detection picks the wrong command | 2 | 3 | Detect by manifest presence; fallback to "no runner, verify manually" |
