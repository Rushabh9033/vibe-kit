# Feature: Rate Limiting

> Copy this to `docs/requirements/<slug>/spec.md`, customize the `<angle brackets>`,
> then run `vibe-spec-approve <slug>`.

## Goal

Protect every public-facing endpoint (and the system behind it) from abuse
and runaway clients. Apply a **token-bucket** algorithm per key (user ID for
authenticated requests, IP for anonymous, API key for partner integrations).
Returns HTTP 429 with `Retry-After` when exhausted. Headers (`X-RateLimit-*`)
let well-behaved clients self-throttle before they hit the wall.

## Acceptance Criteria

- [ ] **AC1.** Authenticated endpoints rate-limited per user ID (default 600 req/min)
  - Verification:
    - automated test: `tests/ratelimit/test_per_user.py::test_user_limit_enforced`
    - expected behavior: 601st request in a minute returns 429; bucket refills at 10/sec

- [ ] **AC2.** Anonymous endpoints rate-limited per IP (default 60 req/min)
  - Verification:
    - automated test: `tests/ratelimit/test_per_ip.py::test_ip_limit_enforced`
    - expected behavior: 61st request in a minute from same IP returns 429

- [ ] **AC3.** Every response includes `X-RateLimit-Limit`, `X-RateLimit-Remaining`, `X-RateLimit-Reset`
  - Verification:
    - automated test: `tests/ratelimit/test_headers.py::test_headers_present`
    - expected behavior: Even non-rate-limited responses include the headers; values reflect current bucket state

- [ ] **AC4.** 429 responses include `Retry-After` (seconds until refill)
  - Verification:
    - automated test: `tests/ratelimit/test_429.py::test_retry_after_header`
    - expected behavior: 429 body is `{"error": "rate_limited", "retry_after_seconds": N}`; header is integer seconds

- [ ] **AC5.** Per-endpoint overrides (e.g. `/auth/login` tighter than default)
  - Verification:
    - automated test: `tests/ratelimit/test_overrides.py::test_endpoint_specific_limit`
    - expected behavior: `/auth/login` configured to 5/min; 6th attempt returns 429 even if user-bucket is full

- [ ] **AC6.** Rate-limit state survives server restart (Redis-backed)
  - Verification:
    - automated test: `tests/ratelimit/test_persistence.py::test_state_in_redis`
    - expected behavior: Restart server, send N requests from same IP — bucket reflects pre-restart consumption

- [ ] **AC7.** Burst allowance: bucket of 100 with refill 10/sec allows 100 instant + 10/sec sustained
  - Verification:
    - automated test: `tests/ratelimit/test_burst.py::test_burst_then_sustained`
    - expected behavior: First 100 requests in 1s all succeed; subsequent requests succeed at 10/sec; over-limit requests 429

- [ ] **AC8.** Rate-limit decisions happen BEFORE expensive work (auth, DB query)
  - Verification:
    - automated test: `tests/ratelimit/test_perf.py::test_decision_under_5ms`
    - expected behavior: Rate-limit check returns in < 5ms; mock endpoint with 100ms work still bounded

## Constraints

- **Algorithm: token bucket** (not fixed window — avoids the boundary spike problem).
- **Storage: Redis** with atomic Lua scripts (`INCRBY` + `EXPIRE`) — no read-modify-write race.
- **Defaults configurable** via env: `RATE_LIMIT_AUTHENTICATED`, `RATE_LIMIT_ANONYMOUS`, `RATE_LIMIT_<ENDPOINT>`.
- **Headers always present**, not just on 429 — well-behaved clients need visibility.
- **No silent throttling** — always return 429, never delay the response.
- **IP source**: respect `X-Forwarded-For` ONLY from configured trusted proxies (security).
- **Per-API-key limits**: partner integrations get their own bucket, isolated from user/IP buckets.

## Edge Cases

### Mandatory 11

- **Empty / missing key:** fall back to IP for anonymous, fail-closed if neither available.
- **Oversized `X-Forwarded-For`:** use the leftmost IP that's in our trusted proxy list.
- **Unicode / non-ASCII in headers:** N/A — keys are hashes.
- **Concurrent requests for same user:** atomic bucket decrement via Redis Lua.
- **Redis down:** fail OPEN (allow request) with warning log — rate limiting is a safety net, not a critical path. NEVER fail closed.
- **Datastore unavailable (Redis or DB):** the rate-limit decision itself degrades to "allow" with a warning; the underlying API endpoint must then surface its own 503 if it can't serve the response.
- **Caller not authenticated:** use IP bucket (separate from auth: 401 is returned by the auth layer, not by rate-limit middleware).
- **Caller authenticated:** use user bucket; a 401 from the auth layer below does NOT consume the rate-limit counter (rate-limit runs first).
- **Bucket exhausted exactly at second boundary:** 429 with `Retry-After: 1`.
- **Idempotent 429s:** returning 429 twice is fine; doesn't extend the penalty.
- **Clock skew across Redis nodes:** use Redis server time, not app server time.
- **Malformed bucket config:** fail fast at startup with clear error.

### Beyond mandatory

- **Distributed rate limiting**: Redis-based, works across N app servers.
- **Per-route stricter limits**: e.g., `/auth/*` is 5/min, `/api/v1/search` is 30/min, `/api/v1/users/me` is 600/min.
- **Whitelisted IPs** (health checks, internal services): bypass rate limit via config.
- **Cost-based limiting**: expensive endpoints (e.g., `/api/v1/render`) cost 5 tokens per call instead of 1.
- **Cooldown after auth failure**: 5 wrong passwords → 15min cooldown even if IP bucket has tokens.
- **Rate-limit observability**: per-endpoint counter + dashboard.
- **Auto-tuning**: detect sustained 429s → suggest raising limit in next deploy.

## Non-Goals

- DDoS protection at the network layer (use Cloudflare / AWS Shield in front).
- Per-resource / per-tenant fairness (use a quota system for that — separate spec).
- Cost-based billing (separate spec — Stripe integration).
- CAPTCHA for human users (only when bot traffic is suspected — separate spec).
- WebSocket rate limiting (different shape — separate spec).

## Verification

- `pytest tests/ratelimit/ -v`
- `vibe-test` (all ranks)
- `vibe-verify` (PASS for every AC)
- **Manual:** hit an endpoint 1000 times from one IP, verify 429 + `Retry-After`
- **Redis down test:** stop Redis, verify requests still flow + warning log
- **Load:** 10k RPS mixed traffic, verify P99 rate-limit-decision < 5ms