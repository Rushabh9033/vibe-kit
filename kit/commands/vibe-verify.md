---
description: Run AC↔test contract check against current changes
---

Verify the current changes against the feature's acceptance criteria.

This is the **contract checker** — it reads `docs/requirements/<feature>/spec.md`,
extracts every AC, checks the git diff for keyword matches per AC, runs the
detected test suite, and reports whether every AC has both implementation
and a green test.

## What it does

1. Find the most recent spec at `docs/requirements/*/spec.md`.
2. Extract ACs (lines matching `- [ ] AC1.` or `- [ ] **AC1**:`).
3. Compute the diff (HEAD~1..HEAD if available, else working tree).
4. For each AC: extract up to 10 keywords (with plural→singular stem form),
   grep the diff for matches, flag AC as ✓ implemented or ✗ missing.
5. Auto-detect test runner (`package.json` → jest/vitest/mocha,
   `pyproject.toml` → pytest, `go.mod` → go test, `Cargo.toml` → cargo test).
6. Run tests; emit tail of log on failure.
7. Print scope-creep diff and an overall PASS/BLOCK verdict.

## When to use

- Before claiming "done" on any user-visible feature.
- After the Coder finishes a feature, before `/vibe-ship`.
- As a gate in PR review: paste the report into the PR description.

## Usage

```
/vibe-verify                # verify the most recent feature spec
/vibe-verify profile-photo  # verify a specific feature by slug
```

## Implementation

This command runs the script at `kit/bin/vibe-verify` (or its installed
equivalent at `~/.claude/vibe-kit/bin/vibe-verify`).

```bash
# Locate the script (project install takes priority over global)
if [ -x "./kit/bin/vibe-verify" ]; then
  ./kit/bin/vibe-verify
elif [ -x "$HOME/.claude/vibe-kit/bin/vibe-verify" ]; then
  $HOME/.claude/vibe-kit/bin/vibe-verify
else
  echo "vibe-verify not installed. Run kit/bin/vibe-init or copy the script."
  exit 1
fi
```

## Reading the output

```
verifying feature=upload-feature
spec=docs/requirements/upload-feature/spec.md

AC contract:
  ✓ AC1. user uploads 5MB photo returns 200 with variants
      implemented: src/upload.ts,tests/upload.test.ts
  ✗ AC2. reject non-image MIME type with 415 status
      NOT IMPLEMENTED in current diff

summary: 1/2 ACs have implementation in the diff
test runner: npx jest --silent
  ✓ tests pass
scope creep check: src/upload.ts, tests/upload.test.ts

overall: BLOCK
  missing ACs: AC2
  fix: implement the AC, or update the spec if scope changed.
```

- **✓ AC** → keyword-matched file in the diff. Manually verify the match
  is real, not a substring coincidence.
- **✗ AC** → no keyword match. Implement it, or update the spec.
- **scope creep** → files changed that don't match any AC. Confirm they're
  intentional or revert.
- **overall BLOCK** → do not ship. Fix the missing ACs and re-run.
- **overall PASS** → safe to `/vibe-ship`.

## Limits

- Keyword matching is heuristic. A clever filename ("utils.ts") can
  match an AC that has nothing to do with utils. Always eyeball the
  matches before trusting the report.
- The script cannot tell whether a test exercises the AC; it only knows
  whether tests run and pass. Use mutation testing (rank 4) for that.
- Multi-spec repos: the script always picks the most-recent spec. Run
  it per-feature when shipping multiple in one branch.
