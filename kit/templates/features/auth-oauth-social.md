# Feature: Auth — OAuth / Social Login

> Copy this to `docs/requirements/<slug>/spec.md`, customize the `<angle brackets>`,
> then run `vibe-spec-approve <slug>`.

## Goal

Let users sign in with their existing Google / GitHub / Apple / etc. account instead
of (or in addition to) email + password. The provider authenticates the user; we
receive an `id_token` (OIDC) or `code` (OAuth2), verify it server-side, then issue
our own session cookie exactly as in the email+password flow.

## Acceptance Criteria

- [ ] **AC1.** "Sign in with Google" button redirects to Google's authorization endpoint with our `client_id`, `redirect_uri`, `state`, `scope=openid email profile`
  - Verification:
    - automated test: `tests/auth/test_oauth.py::test_authorize_redirect`
    - expected behavior: 302 to `accounts.google.com/o/oauth2/v2/auth?...` with all required params

- [ ] **AC2.** Callback validates `state` matches the value we stored in the user's session at /authorize time (CSRF)
  - Verification:
    - automated test: `tests/auth/test_oauth.py::test_state_csrf_rejected`
    - expected behavior: Callback with mismatched/missing state returns 400, no user created, no session issued

- [ ] **AC3.** Callback exchanges `code` for tokens at the provider, then verifies the `id_token` signature against the provider's JWKS
  - Verification:
    - automated test: `tests/auth/test_oauth.py::test_id_token_verified`
    - expected behavior: Token signed by Google, valid claims, `aud` matches our `client_id` → user row created, session issued

- [ ] **AC4.** Callback rejects `id_token` with `iss` ≠ provider's issuer, `aud` ≠ our client_id, or `exp` in the past
  - Verification:
    - automated test: `tests/auth/test_oauth.py::test_id_token_claims_rejected`
    - expected behavior: Any claim mismatch → 401, no user created

- [ ] **AC5.** Returning user (matching email already exists) is linked, not duplicated
  - Verification:
    - automated test: `tests/auth/test_oauth.py::test_account_linking`
    - expected behavior: Second login via Google for the same email → existing user row updated, no duplicate created

- [ ] **AC6.** Provider never sees our users' passwords (we don't store any)
  - Verification:
    - automated test: `tests/auth/test_oauth.py::test_no_password_field`
    - expected behavior: User row created via OAuth has `password_hash IS NULL`

- [ ] **AC7.** OAuth `client_secret` is read from env var, never embedded in client-side code
  - Verification:
    - automated test: `tests/auth/test_oauth.py::test_secret_in_env`
    - expected behavior: `os.environ["OAUTH_GOOGLE_SECRET"]` present, grep of frontend bundles returns zero hits

## Constraints

- **State parameter**: cryptographically random ≥32 bytes from `secrets.token_urlsafe`, stored in server-side session, validated on callback. **Mandatory** — no opt-out.
- **PKCE** (code_verifier + code_challenge) for all OAuth2 flows where the provider supports it (mobile/SPA).
- **JWKS**: cached from the provider's `/.well-known/jwks.json`, refreshed on `kid` miss.
- **id_token signature**: verified via provider's public key, never trusted unverified.
- **`client_secret`**: env var only; never logged; never sent to the client.
- **`redirect_uri`**: exact-string match (no wildcards).
- **Scopes**: request the minimum (default `openid email profile`). Never `*`.
- **Provider outage**: degrade gracefully — show "Sign in with Google is temporarily unavailable, try email + password".

## Edge Cases

### Mandatory 11

- **Empty / missing `code`:** 400.
- **Oversized state cookie:** reject > 4KB.
- **Unicode in name from provider:** NFC-normalized; truncated at 255 chars.
- **Concurrent callback for same `code`:** one wins, other rejected (provider-side dedup).
- **Network failure during token exchange:** 502, user redirected to login with "try again".
- **Provider revokes token mid-flow:** 401, user shown "session expired".
- **User denies permission:** callback with `error=access_denied` → 200 with "you cancelled" UI.
- **DB unavailable:** 503.
- **Replay of callback with same `code`:** rejected (codes are single-use at provider).
- **Provider clock skew > 5min:** all `id_token`s fail `exp` / `iat` checks → 401.
- **Malformed `id_token`:** 400, not 500.
- **Idempotent replay of `code`:** once exchanged, second attempt at the same `code` returns 400 from the provider — we treat as no-op rather than an error.
- **Empty body on `/callback`:** 400 (no `code` to exchange).

### Beyond mandatory

- **Multiple Google accounts with same email:** linked to one user row, all aliases stored.
- **User unlinks Google account:** allowed only if user has another auth method (otherwise reject).
- **Provider sends email_verified=false:** rejected — we treat unverified emails as unverified.
- **`hd` claim (Google Workspace):** respected for B2B — restrict signups to specific hosted domains if configured.
- **Rate limit on OAuth attempts:** 10 per IP per hour (anti-bruteforce of state guessing).

## Non-Goals

- Email + password (separate spec).
- 2FA after OAuth login (separate spec).
- Enterprise SSO / SAML.
- Account deletion via OAuth provider (only via our own UI).
- Cross-provider account merge UI (auto-merge via matching email is enough).

## Verification

- `pytest tests/auth/ -v`
- `vibe-test` (all ranks)
- `vibe-verify` (PASS for every AC)
- **Manual:** click "Sign in with Google" → Google consent → land on `/dashboard`; cancel at Google → land on `/login?error=cancelled`; revoke in Google account settings → next login attempt fails cleanly
- **Security:** `bandit`, mock JWKS rotation test