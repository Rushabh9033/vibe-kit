# 2026-08-21 — vibe-mutate + AI-assisted intake

## TL;DR

Two ships in one push:

- **`vibe-mutate`** — language-aware mutation testing binary. Auto-detects
  Python (mutmut) / Node (Stryker) / Java (PIT). Threshold-gated
  (default 70, matches `~/.claude/rules/02-verify.md`). Wired into
  `vibe-claim-check` as a post-test step. FAIL → PARTIAL → override can
  lift but not to PASS.
- **`vibe-spec-intake --ai`** — opt-in AI-assisted intake. When the user
  passes `--ai`, the kit invokes the user's `claude` CLI with a kit-owned
  prompt template to produce intent-specific ACs. Falls back to template
  on any failure (no CLI, non-zero exit, output validation fail).

173 assertions across 6 suites, 0 failures. Both features ship with specs
under `docs/requirements/<feature>/spec.md`.

## What changed (file list)

| File | Why |
|---|---|
| `kit/bin/vibe-mutate` | NEW. Language-aware mutation runner. |
| `kit/bin/vibe-claim-check` | Now invokes `vibe-mutate` after `vibe-test`. Mutation FAIL/BLOCK → PARTIAL. |
| `kit/bin/vibe-spec-intake` | Added `--ai` flag + `generate_ai` function + fallback to template. |
| `kit/prompts/spec-intake.md` | NEW. Kit-owned prompt template with `{{INTENT}}` / `{{SLUG}}` / `{{DATE}}` placeholders. |
| `kit/commands/vibe-spec.md` | Mentions `--ai` in intake section. |
| `kit/CLAUDE.md` | Added mutation-as-Rank-1 line to "Always" list. |
| `README.md` | New "Mutation testing" subsection under "Ship". New "AI-assisted intake" line under Spec templates. |
| `CHANGELOG.md` | Two [Unreleased] entries: vibe-mutate + AI-assisted intake. |
| `docs/requirements/vibe-mutate/spec.md` | NEW. Spec for #4 (shipped). |
| `docs/requirements/vibe-spec-intake-ai/spec.md` | NEW. Spec for #5 (shipped). |
| `tests/weapons/test-vibe-mutate.sh` | NEW. 33 assertions. |
| `tests/weapons/test-spec-intake-ai.sh` | NEW. 8 assertions. |

## Mutation testing — what it does and what it doesn't

- **What it does:** prove the test suite actually exercises the code, not
  just runs. `verify` is keywords, `claim-check` is tests-run, mutation
  is tests-meaningful.
- **What it doesn't:** run at mid-development (too slow); auto-install
  mutation tools (user opts in); mutate only changed lines (full-project
  for now; differential in v0.2).
- **Score parsers:**
  - mutmut: `[0-9]+/[0-9]+` ratio, fallback to `N%` literal.
  - Stryker: `--json` → `mutationScore` (0-1) or aggregated from per-file mutants.
  - PIT: `Mutation Coverage N%` literal.
- **Threshold:** 70 default, `--threshold=N` override. Below threshold → FAIL
  (rc=1). At or above → PASS (rc=0). No tool → BLOCK (rc=2). No language
  detected → UNVERIFIED (rc=3).
- **Claim-check integration:**
  ```
  vibe-test → vibe-mutate → per-AC evidence → verdict
  ```
  Mutation FAIL/BLOCK becomes PARTIAL (rc=2). Override (set by the pre-push
  hook, not claim-check itself) lifts PARTIAL → 0.

## AI-assisted intake — what it does and what it doesn't

- **What it does:** when `--ai` is passed, the script generates a Spec by
  calling `claude --print "$(kit-owned prompt)"`. The prompt template is
  auditable at `kit/prompts/spec-intake.md`. Output is captured verbatim
  into `spec.md`. Output is validated: if the AI's response doesn't
  mention the intent keywords (length ≥ 4), it's rejected and the
  template is used instead.
- **What it doesn't:** default to AI (must be `--ai`); auto-install the
  claude CLI; stream output (deterministic `--print` mode); support other
  AI CLIs (v0.1 is claude-only).
- **Cost:** AI invocation costs tokens. The script logs to stderr:
  `vibe-spec-intake: invoking AI (this costs tokens)...`. The prompt
  template itself is NOT logged (may contain sensitive intent).

## Compound lesson (gotchas.md candidate)

**Never run `rm -rf <relative-path>` in a test script.** A test doing
`rm -rf docs` between cases will happily delete the project's `docs/`
directory if the test is run from the project root. During this session,
`test-spec-intake-ai.sh` did exactly that and deleted the entire `docs/`
tree (including `docs/handoffs/`, `docs/requirements/`, etc.).

Restoration: `git checkout HEAD -- docs/`. Recovery took <5s because
the files were tracked.

Fix applied to `test-spec-intake-ai.sh`: `cd "$TMPDIR_BASE"` once at the
top of the script, then operate in the sandbox. Same lesson applies to
`test-vibe-mutate.sh` — it uses absolute paths under `$TMPDIR_BASE`.

**Rule of escalation:** if a test needs to clean up its own working dir,
it must own the cwd or use absolute paths. Mixing the two is the
slips-between-the-cracks mode that breaks recovery.

## Test results (final)

```
test-vibe-mutate.sh:       33 / 33 ✓
test-spec-intake-ai.sh:     8 /  8 ✓
test-pre-push.sh:          18 / 18 ✓
test-weapons.sh:           40 / 40 ✓
test-prep-room.sh:         21 / 21 ✓
test-spec-first-gate.sh:   53 / 53 ✓ (no summary line)
                         ──────────────
                         173 / 173, 0 failures
```

## What's still on the list

Both top of the priority list are now shipped. From the original
five-item queue:

- ✅ #1: auto-arm after Spec approval (`vibe-spec-approve`)
- ✅ #2: Spec template gallery (10 templates)
- ✅ #3: `/vibe-claim-check` as the real ship gate
- ✅ #4: Mutation testing as Rank 1 (this push)
- ✅ #5: AI-assisted intake (this push)

The kit's hard-gate surface is now complete for v0.2. The natural next
step is the language-tooling work that's been implicit in the weapons:
per-tool detection polish, more templates, and a one-command
"fresh-project bootstrap" that runs `vibe-spec-intake --ai` + `vibe-arm`
in sequence.

## For the next session

If you extend mutation testing:

1. **Differential mutation** (mutate only changed lines) is the obvious
   next move — current approach mutates the whole project, which is
   slow. `git diff --name-only HEAD` gives the candidate files.
2. **Per-AC mutation** would be powerful: which mutations correspond to
   which AC. Not a v0.3 thing; needs a Spec AC ↔ line-range mapping.
3. **The Stryker parser depends on Python 3 being available** for the
   `--json` output. If the project is Node-only with no Python, add a
   pure-bash JSON parser. Out of scope for v0.2.

If you extend the intake:

1. **Multi-CLI support** (codex, gemini): abstract behind a `vibe-ai`
   shim. Trivial adapter pattern; spec it first.
2. **Streaming output**: `--print` is non-streaming. For a long intent,
   users see nothing for 10s+. Stream the response so the terminal shows
   progress.
3. **Cache by intent hash**: same intent → same spec. Avoids re-billing.
   Risky if intent is sensitive; gate behind explicit opt-in.
