# Feature: Auth — Email + Password

> Copy this to `docs/requirements/<slug>/spec.md`, customize the `<angle brackets>`,
> then run `vibe-spec-approve <slug>`.

## Goal

Standard authentication for human users via email + password. Signup with email
verification, login with rate-limited attempts, password reset via email link,
secure session via httpOnly cookies or rotating bearer tokens. Argon2id for
hashing (NOT bcrypt, NOT sha256). 2FA deferred to a separate spec.

## Acceptance Criteria

- [ ] **AC1.** New user can sign up with email + password (≥12 chars)
  - Verification:
    - automated test: `tests/auth/test_signup.py::test_signup_creates_user`
    - expected behavior: POST `/auth/signup` with valid body returns 201, user row exists, password stored as Argon2id hash

- [ ] **AC2.** Email verification link is sent, account is locked until clicked
  - Verification:
    - automated test: `tests/auth/test_signup.py::test_email_verification_required`
    - expected behavior: Until verification link clicked, login returns 403 "verify your email"

- [ ] **AC3.** Login with correct credentials returns a session token
  - Verification:
    - automated test: `tests/auth/test_login.py::test_login_returns_session`
    - expected behavior: POST `/auth/login` with valid creds returns 200 + Set-Cookie (httpOnly, Secure, SameSite=Lax)

- [ ] **AC4.** Login with wrong password returns 401 + generic error (no user-enumeration leak)
  - Verification:
    - automated test: `tests/auth/test_login.py::test_login_wrong_password_generic`
    - expected behavior: 401 with `"invalid credentials"` — same response as wrong email

- [ ] **AC5.** Login rate-limited to 5 attempts per email per 15 minutes
  - Verification:
    - automated test: `tests/auth/test_login.py::test_login_rate_limited`
    - expected behavior: 6th attempt in 15min window returns 429 + `Retry-After` header

- [ ] **AC6.** Password reset email contains single-use token, expires in 1 hour
  - Verification:
    - automated test: `tests/auth/test_reset.py::test_reset_token_single_use`
    - expected behavior: Token works once, second use returns 410 Gone; token > 1h old returns 410

- [ ] **AC7.** Sessions are rotated on login (no session fixation)
  - Verification:
    - automated test: `tests/auth/test_login.py::test_session_rotated`
    - expected behavior: Pre-login session cookie is invalid after successful login

- [ ] **AC8.** Logout invalidates the session server-side, not just client-side
  - Verification:
    - automated test: `tests/auth/test_logout.py::test_logout_invalidates_session`
    - expected behavior: After logout, the same session token returns 401 from any endpoint

- [ ] **AC9.** Password change requires current password + invalidates all other sessions
  - Verification:
    - automated test: `tests/auth/test_password_change.py::test_change_invalidates_others`
    - expected behavior: After password change, all OTHER sessions for the user return 401

## Constraints

- **Argon2id** for password hashing. Never bcrypt, never SHA-256, never MD5.
- Email + password verified BEFORE any user row is created (atomic signup).
- Passwords are NEVER logged, even hashed.
- Email verification tokens are 32+ bytes from `secrets.token_urlsafe`.
- Sessions are server-side state with random opaque IDs (NOT JWT in localStorage).
- Cookies: `httpOnly`, `Secure`, `SameSite=Lax`, 30-day rolling expiry.
- Password reset endpoint rate-limited per email AND per IP.
- TLS required for all auth endpoints (no HTTP fallback).

## Edge Cases

### Mandatory 11

- **Empty input:** 400 with field-level errors.
- **Max-size input:** email ≤ 254 chars (RFC 5321), password ≤ 128 chars.
- **Unicode in email / password:** normalized via NFC; non-ASCII password chars allowed.
- **Concurrent signup with same email:** one wins, other returns 409 Conflict (no enumeration).
- **Network failure during email send:** user exists but email not sent → user can re-request verification.
- **Token expired:** 410 Gone with explicit "link expired, request a new one".
- **User deleted (GDPR):** sessions invalidated within 60s.
- **DB unavailable:** 503 + clear error.
- **Idempotent logout:** logout of an already-logged-out session returns 204 (idempotent).
- **Timezone / clock skew:** N/A (server-time only).
- **Malformed email:** 400, not 500.

### Beyond mandatory

- **Existing user tries to re-signup with same email:** 409 with "already registered" (acceptable enumeration leak post-signup, NOT on login).
- **Password reuse on reset:** rejected if matches last 5 passwords.
- **User changes email:** requires re-verification of new email before swap.
- **Brute force across many accounts from one IP:** IP-level rate limit kicks in (see rate-limiting template).

## Non-Goals

- 2FA / TOTP / WebAuthn (separate spec).
- Social / OAuth login (separate spec).
- Magic-link-only auth (separate spec).
- Account-deletion workflow beyond "user deleted → sessions invalidated".
- Admin impersonation / "log in as user" (separate spec).
- SSO / SAML / enterprise auth.

## Verification

- `pytest tests/auth/ -v`
- `vibe-test` (all ranks)
- `vibe-verify` (PASS for every AC)
- **Manual:** signup → verify email → login → reset password → change password → logout, end-to-end
- **Security:** `bandit -r src/auth/`, `pip-audit`