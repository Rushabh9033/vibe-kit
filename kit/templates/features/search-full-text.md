# Feature: Search — Full-Text

> Copy this to `docs/requirements/<slug>/spec.md`, customize the `<angle brackets>`,
> then run `vibe-spec-approve <slug>`.

## Goal

Let users search a corpus (documents, products, users, posts, …) with a text
query plus structured filters (tags, date range, author, category). Results are
ranked by relevance, paginated, and returned in <300ms P95 for a 100k-row corpus.
Built on Postgres `tsvector` for v1; can swap to Meilisearch / Algolia later
behind the same API contract.

## Acceptance Criteria

- [ ] **AC1.** `GET /search?q=<query>` returns matching rows ordered by relevance
  - Verification:
    - automated test: `tests/search/test_query.py::test_search_returns_relevant_results`
    - expected behavior: Query matches N rows; response has `[{id, score, snippet}, ...]` sorted by `score DESC`

- [ ] **AC2.** Search matches across the configured fields (title, body, tags by default)
  - Verification:
    - automated test: `tests/search/test_query.py::test_multi_field_match`
    - expected behavior: Term in `body` alone matches; term in `tags` alone matches; partial matches score lower than exact

- [ ] **AC3.** Filters narrow results (`?tag=X&author=Y&from=2026-01-01&to=2026-12-31`)
  - Verification:
    - automated test: `tests/search/test_filters.py::test_combined_filters`
    - expected behavior: `tag=X AND author=Y` returns only rows matching both; date range excludes out-of-range

- [ ] **AC4.** Pagination via `?page=N&size=M` (default size 20, max 100)
  - Verification:
    - automated test: `tests/search/test_pagination.py::test_pagination_meta`
    - expected behavior: Response includes `total`, `page`, `size`, `has_next`; `size>100` clamped to 100; `page=0` returns 400

- [ ] **AC5.** Query sanitized — SQL injection attempts return 0 rows, not 500
  - Verification:
    - automated test: `tests/search/test_security.py::test_sql_injection_safe`
    - expected behavior: `q=' OR 1=1--` → 200 with empty results, no DB error

- [ ] **AC6.** P95 latency < 300ms for 100k-row corpus at 50 concurrent queries
  - Verification:
    - automated test: `tests/search/test_perf.py::test_p95_under_300ms`
    - expected behavior: k6 load test → P95 < 300ms; check via `p95_latency_ms` metric

- [ ] **AC7.** Snippet generation highlights matched terms with `<mark>` (safe HTML)
  - Verification:
    - automated test: `tests/search/test_snippet.py::test_snippet_highlighting`
    - expected behavior: Matched terms wrapped in `<mark>`; HTML in source is escaped (`<script>` → `&lt;script&gt;`)

- [ ] **AC8.** Empty query returns 400 (not "match everything")
  - Verification:
    - automated test: `tests/search/test_query.py::test_empty_query_rejected`
    - expected behavior: `?q=` or missing `q` returns 400 with "error: query required"

## Constraints

- **Read-only**: search endpoints never write to the corpus; indexing is a separate worker.
- **Authorization-aware**: results respect the same permission model as the source resource (see crud-with-permissions).
- **Query timeout**: 2s hard cap; long queries return a partial result with `truncated: true`.
- **No SQL injection**: every query is parameterized — `tsquery` constructed from sanitized tokens, NEVER raw concatenation.
- **Snippet HTML is always escaped** except for `<mark>` tags.
- **Result limit**: 100 max per page, regardless of `size` param.
- **Index updated within 5s** of source row write (via outbox + worker).

## Edge Cases

### Mandatory 11

- **Empty input:** `q` missing or empty → 400.
- **Max-size input:** `q` > 200 chars → 400.
- **Unicode / non-ASCII:** query is NFC-normalized; matches against NFC-normalized index.
- **Concurrent same-query:** idempotent — same results, same scores.
- **Network failure to DB:** 503 with "search temporarily unavailable".
- **Caller not authenticated:** 401 (unless search is unauthenticated by design).
- **Caller with no permission on the resource:** row excluded from results silently (no enumeration).
- **DB unavailable:** 503.
- **Idempotent pagination:** `page=2` after new row added → stable results for already-seen pages (cursor-based fallback for true stability).
- **Timezone / clock skew:** N/A for search; date filters use server timezone with explicit `tz` param.
- **Malformed filter value:** 400 with field-level error.

### Beyond mandatory

- **No matches:** 200 with empty `[]`, NOT 404.
- **Single match:** 200 with one-element array.
- **Special characters in query** (`-`, `*`, `:`, `&`): treated as plain text by default; advanced operators are opt-in via `?advanced=true`.
- **Stemming** (English default): "running" matches "run". Configurable per-language.
- **Stop words** ("the", "a", "an") excluded by default; configurable.
- **Ranking boost** by recency (`?recency_boost=true`) or by popularity (custom signal via column).
- **Search-as-you-type** (debounced): a separate endpoint `/search/suggest` with a smaller index.

## Non-Goals

- Semantic / vector search (separate spec — embeddings).
- Federated search across multiple corpora.
- Search analytics dashboard (separate spec).
- Custom ranking models per user (separate spec — personalization).
- Spell correction / "did you mean?" (separate spec).
- Search history per user (privacy implications).

## Verification

- `pytest tests/search/ -v`
- `vibe-test` (all ranks)
- `vibe-verify` (PASS for every AC)
- **Corpus test:** seed 100k rows, run 1000 random queries, verify P95 < 300ms
- **Manual:** search for a known term, verify snippet + ranking; try SQL injection attempt; try empty query
- **Security:** confirm parameterized queries via EXPLAIN; confirm HTML escaping in snippets