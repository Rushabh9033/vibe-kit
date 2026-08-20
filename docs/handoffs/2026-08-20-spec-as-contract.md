# Session: 2026-08-20 — Spec-as-Contract hardening

> Filled by session that rewrote positioning, spec template, and verify script.

## Goal
Strengthen the "Spec is the durable contract between planning and implementation"
concept end-to-end:
1. Sharpen README positioning (lead + diagram + principle).
2. Replace 99.99% / 0.001% messaging with the credible intent → Planner → Spec → Coder → Verify flow.
3. Make the spec template canonical (9 sections, human-approval gate, AI-authored surface area, Mandatory 11).
4. Make `vibe-verify` actually verify the Spec (not just code compilation). New status model.
5. Make ceremony scale with risk. Coherent terminology. Improved examples.
6. Be critical — inspect, identify problems, fix.

Preserve existing strengths. Do not rewrite from scratch.

## Branch / state
`main` based on `main`; dirty (changes to be committed)

## Done
- [x] README lead rewritten with "contract layer" tagline + stacked ASCII diagram showing SPEC/CONTRACT as central high-contrast artifact
- [x] `prompts/00-anchor.md` — replaced 99.99% messaging with credible asymmetry framing
- [x] `kit/templates/requirements-spec.md` — canonical 9-section structure + Human approval gate + AI-authored surface area + Mandatory 11
- [x] `examples/planner-output-spec.md` — rewritten in canonical form
- [x] `kit/bin/vibe-verify` — rewritten with PASS/PARTIAL/FAIL/UNVERIFIED/REVIEW status model
- [x] `kit/commands/vibe-verify.md` — rewritten to document the status model
- [x] Bug fixes: `hits_for` keyword matching, `check_non_goals` false positives, `check_migrations` false positives, icon inversion in Constraints display
- [x] Smoke test passes against fixture repo at `/tmp/vibe-verify-smoke`

## In progress
- Commit + push (pending at session end)

## Blocked
- None

## Files touched
- `README.md`
- `prompts/00-anchor.md`
- `kit/templates/requirements-spec.md`
- `examples/planner-output-spec.md`
- `kit/bin/vibe-verify`
- `kit/commands/vibe-verify.md`
- `CHANGELOG.md` (Unreleased section)
- `docs/handoffs/2026-08-20-spec-as-contract.md` (this file)

## Decisions made
- **Decision**: Status vocabulary is 5 states (PASS / PARTIAL / FAIL / UNVERIFIED / REVIEW), not 99. Rationale: smallest vocabulary that distinguishes "I checked, with evidence" from "I can't check, human please" from "I checked and it's wrong." REVIEW is reserved for Non-Goal / Constraint violations.
- **Decision**: Non-Goals check uses basename-only + length-≥-6 keywords + expanded stopwords. Rationale: path-matching caused every spec.md path to match "photo" and trigger false positives on every feature that mentions photos in its description. Basename + length filter raises precision at the cost of recall — acceptable since Non-Goal violations should be visually obvious anyway.
- **Decision**: `check_migrations` matches actual file paths only, not diff content. Rationale: the spec body itself (when added) contains the word "migrations" in `Hard constraints`; matching diff content was triggering false positives on the very act of writing the spec.
- **Decision**: `check_migrations` accepts `Migration strategy:` or a `## .* [Mm]igrations` heading in the spec as a declaration that migrations are in scope. Rationale: a spec that explicitly addresses migrations should not be flagged when migrations are edited.
- **Decision**: `hits_for` returns newline-separated file paths capped at 3, not comma-separated. Rationale: counting via `awk 'NF{c++}'` is robust to no-trailing-newline input; comma parsing was unreliable.

## Decisions needed
- **Decision**: bump version (proposed: 0.4.0 — Spec-as-Contract). User confirmation needed before commit.
- **Decision**: ship per-tool packs (Continue/Cody/Windsurf/JetBrains AI) — already deferred from 0.3.0; remain deferred.

## Verification
- [x] Smoke test against `/tmp/vibe-verify-smoke` — 2 PASS, 1 UNVERIFIED, 0 FAIL, 0 violations; overall PARTIAL (correctly: human-judged AC blocks ship without explicit review)
- [x] Bash trace debug (`set -x`) confirms `hits_for` returns correct filenames, `classify` uses robust field count
- [x] Icon inversion fixed: Constraints now shows `✓` when OK, `✗`/`⚠` when violated
- [ ] Lint — `kit/bin/vibe-verify` is bash; no project linter; `shellcheck` recommended
- [ ] Full diff review — pending

## Next steps for next session
1. Run `shellcheck kit/bin/vibe-verify` to catch any bash warnings.
2. Commit + push changes (`v0.4.0`).
3. Add a negative-path smoke test: a fixture where the script SHOULD flag a violation (e.g., a non-goal keyword that DOES match a real new file).
4. Consider adding a `--strict` flag to `vibe-verify` that fails on PARTIAL (currently PARTIAL exits 0, which is correct for "ship with human review").
5. Per-tool packs (Continue/Cody/Windsurf/JetBrains AI) — still deferred.

## Gotchas learned
- **bash pattern matching for "starts with"**: `${var#OK}` removes the prefix. If var starts with OK, result is "" (not equal to var). If var doesn't start with OK, result is var (equal). So "result starts with OK" is `${var#OK} != var` — counterintuitive; `[[ var == OK* ]]` is clearer.
- **`wc -l` undercounts on no-trailing-newline input on macOS BSD**. Use `awk 'NF{c++} END{print c+0}'` for robust newline-separated counting.
- **`paste -sd ', ' -` preserves leading whitespace** from input lines, producing double spaces in output. Strip leading whitespace before pasting, or use a delimiter that doesn't get duplicated.
- **awk `index($0, " b/"file)`** works correctly with file paths containing slashes when file is passed as a string variable (not a regex). Confirmed in the smoke test.

<!-- context metadata (do not edit) -->
- session_id: unknown
- started: 2026-08-20
- cwd: /Users/radhikamac/vibe-kit
- branch: main
- written_by: session
