---
description: Verify the Spec is satisfied by the current changes
---

Verify the current changes against the feature's Spec.

This is the **contract checker**. It reads `docs/requirements/<feature>/spec.md`,
extracts the acceptance criteria + requirements + non-goals + constraints,
checks the git diff for evidence of each, runs the detected test suite,
and reports the per-item status.

The question it answers:

> **Does the implementation match the Spec?**

Not just: "Does the code compile?"

## What it checks

1. **Acceptance criteria** — for each AC, does the diff have evidence?
2. **Requirements** — for each functional requirement, does the diff touch it?
3. **Non-Goals** — for each declared non-goal, is it NOT implemented?
4. **Constraints** — were migrations edited? were new deps added?
5. **Tests** — does the detected test runner pass?
6. **Scope creep** — which files changed and are they intentional?

## Status model

The verifier uses five statuses. The smallest vocabulary that says what matters.

| Status | Symbol | Meaning | Blocks ship? |
|---|---|---|---|
| **PASS** | `✓` | Evidence in the diff matches the AC | no |
| **PARTIAL** | `⚠` | Some evidence, some gaps | soft warning |
| **FAIL** | `✗` | No evidence in the diff | yes |
| **UNVERIFIED** | `?` | Human-judged AC; needs explicit review | soft warning |
| **REVIEW** | `!` | Non-Goal / Constraint violation | yes |

The AC's status is decided by:

- **PASS** — multiple keyword matches in the diff (a file for the AC + a test for it).
- **PARTIAL** — one keyword match (e.g., implementation file but no test, or vice versa).
- **FAIL** — no keyword matches.
- **UNVERIFIED** — the AC explicitly says "human-judged", "manual review", or "needs review".

The overall verdict is:

- **PASS** — every AC is PASS or UNVERIFIED; no constraint violations; tests pass.
- **PARTIAL** — at least one AC is PARTIAL or UNVERIFIED; no FAILs.
- **FAIL** — at least one AC is FAIL, or a constraint was violated, or tests fail.

It's honest about the difference between "I checked" and "I claim it works."

## When to use

- After the Coder finishes a feature, before `/vibe-ship`.
- Before claiming "done" on any user-visible feature.
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

## Acceptance criteria
  ✓  PASS       AC1. user uploads 5MB photo returns 200 with variants
  ⚠  PARTIAL    AC2. reject non-image MIME type with 415 status
                   evidence: src/upload.ts
  ✗  FAIL       AC3. concurrent uploads last-write wins
  ?  UNVERIFIED AC4. EXIF GPS stripped (human-judged)

summary: 1/4 ACs PASS  ·  1 PARTIAL  ·  1 UNVERIFIED  ·  1 FAIL

## Non-Goals (must NOT be implemented)
  ✓  not implemented: Cover photo
  ✓  not implemented: Filters / adjustments

## Constraints
  ✓ migrations: not edited (or spec declares strategy)
  ✓ dependencies: no manifest change

test runner: npx jest --silent
  ✓ tests pass

## Scope creep (files changed)
  src/upload.ts
  tests/upload.test.ts

overall: FAIL
  missing ACs: AC3
  fix: implement the AC, or update the spec if scope changed.
```

## What each section means

- **Acceptance criteria** — the Spec's ACs, with their per-item status.
- **Non-Goals** — the Spec's "Non-Goals" section. Each must NOT be implemented. If a non-goal's keyword matches the diff, that's a violation.
- **Constraints** — the Spec's `Hard constraints` block. If migrations were edited but the spec has no migration strategy, that's a violation. If a manifest file changed, it's a warning.
- **Tests** — did the detected test runner pass?
- **Scope creep** — which files changed. Eyeball them against the ACs; if files appear that no AC justifies, they're unintended.
- **overall** — PASS / PARTIAL / FAIL.

## Limits

- Keyword matching is heuristic. A clever filename ("utils.ts") can match an AC that has nothing to do with utils. Always eyeball the matches before trusting the report.
- The script cannot prove semantic correctness. It cannot tell whether a test exercises the AC; it only knows whether tests run and pass. Use mutation testing (rank 4) for that.
- Multi-spec repos: the script always picks the most-recent spec. Run it per-feature when shipping multiple in one branch.
- The script does not claim "PASS = shippable." It claims "PASS = no keyword gaps." The verifier is a tripwire, not a sign-off.
