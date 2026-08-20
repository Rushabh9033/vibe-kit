# Intake — what the user typed into the Planner

This is the user → Planner handoff. Plain language. The Planner runs prompts/00-anchor.md first, then prompts/02-feature-spec.md with this intake as the body.

---

## User's message

> I'm building a social network for couples. People in a relationship pair up and share a private feed.
>
> First feature I want: every user can upload a profile photo. Crop to a square, save at 32/64/256/512 px so it looks right everywhere.
>
> Must work on mobile. Must be private (EXIF GPS stripped). Must be idempotent (network drops shouldn't double-upload).
>
> Stack: TypeScript, Next.js, Postgres + S3. Auth via NextAuth.
>
> No new top-level dependencies — we use the existing libs. Specifically: `sharp` for image processing (already in the project).

## What the Planner extracts from this

- **Project**: Couples social network.
- **This feature**: profile photo upload.
- **Job-to-be-done**: "When I set up my profile, I want a recognizable photo, so other users recognize me."
- **User**: signed-in couple-member.
- **Stack**: TS / Next.js / Postgres / S3 / NextAuth / sharp.
- **Constraints**: mobile-first, EXIF stripped, idempotent, no new deps.
- **Out of scope (likely)**: filters, multiple photos, cover photo, generated avatars.

## Planners questions before writing

- Q1. Max file size (5MB ok? 10MB ok?).
- Q2. Allowed formats (JPEG / PNG / WebP)?
- Q3. Animation (GIF, APNG) — yes/no?
- Q4. Crop rotation (90° CW only? both directions?)?
- Q5. Concurrent uploads same user — last-write wins, or 409 on second?
- Q6. Idempotency window (forever? 24h?)?

If any are missing, the Planner asks. In this example, the Planner reasons:

- Q1 — 10MB sane default.
- Q2 — JPEG/PNG/WebP (sharp supports all).
- Q3 — no.
- Q4 — 90° CW only (most common convention).
- Q5 — last-write wins (typical UX).
- Q6 — same Idempotency-Key returns original; no time limit.

These become explicit in `planner-output-spec.md`.
