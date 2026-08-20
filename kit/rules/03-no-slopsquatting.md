---
paths:
  - "package.json"
  - "pyproject.toml"
  - "requirements.txt"
  - "go.mod"
  - "Cargo.toml"
  - "**/package.json"
  - "**/requirements*.txt"
---

# Never add a dependency without verification (slopsquatting prevention)

Up to 20% of AI samples include hallucinated packages. Attackers register them.

## Mandatory before adding any dependency

1. **Registry check**: `npm view <pkg>` / `pip index versions <pkg>` / `cargo search <pkg>` — must exist with at least one non-prerelease version.
2. **Maintainer check**: real maintainer history, not a single fast-published version.
3. **Typosquat signature**: not a near-collision with a popular package (`reqests`, `lodashx`, `expres`).
4. **License check**: on the project allowlist (MIT, Apache-2, BSD; deny GPL in proprietary).
5. **Socket / Snyk / Dependabot**: must pass.
6. **osv-scanner**: must pass.
7. **Lockfile pinning**: exact version, not `^`/`~` for security-critical.

## Sandbox before trust

For high-risk or new maintainer deps, install in a throwaway venv/container and observe:

- post-install scripts (`preinstall`, `install`, `postinstall`)
- network calls
- env / disk access
- unexpected file writes

## CI gate

- Add `npm audit --omit=dev` (or equivalent) to PR pipeline; fail on critical.
- Lockfile diff required for any dependency change.
- A dependency PR must list: package, version, one-line justification, license, audit result.

## When the agent suggests a dependency

Treat that suggestion as untrusted. Run the checklist above before `npm install`. If the package doesn't exist, **don't install a similar-looking one** — that's the attack.

## Allowlist

Maintain a project allowlist at `docs/decisions/0002-deps-allowlist.md` (or similar). AI may not add deps outside the allowlist without an explicit ADR.
