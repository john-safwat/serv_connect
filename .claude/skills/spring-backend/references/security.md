# Security, Auth & PHI Handling

Treat every user/patient/clinician-identifying field as sensitive by default, even before a
formal compliance programme exists.

## Baseline posture

- **Everything is authenticated by default** via a `SecurityFilterChain` bean. An endpoint is
  public only when explicitly listed (`permitAll()`) — never by omission. See
  `assets/SecurityConfig.java`.
- **Stateless** sessions (`SessionCreationPolicy.STATELESS`); **CSRF disabled** because auth is
  bearer-token, not cookie-session. Re-evaluate if cookie sessions are ever added.
- **`@EnableMethodSecurity`** on the config class so `@PreAuthorize`/`@PostAuthorize` on
  controllers and services are actually enforced (without it they are silent no-ops). Put a
  class-level `@PreAuthorize("hasRole('…')")` on a feature's self-service controller.
- **CORS** configured explicitly in a `@Configuration` (allowed origins/methods/headers) — never
  `@CrossOrigin("*")` on a controller touching sensitive data.

## JWT authentication plumbing (`common/security/`)

- **`JWTService`** — issues/parses HMAC-signed JWTs (`io.jsonwebtoken` / jjwt). `jwt.secret`,
  token expiry, and refresh expiry come from `${JWT_SECRET}` / `${JWT_TOKEN_EXPIRY_TIME}` /
  `${JWT_REFRESH_TOKEN_EXPIRY_TIME}` — never hardcoded. Access tokens carry `id/name/email/roles`;
  refresh tokens carry `id` + a random `jti` so two tokens minted in the same millisecond differ.
  *(Watch the `@Value("${...}")` syntax — a missing `${` silently injects the literal string.)*
- **`AppAuthenticationProvider`** — verifies email + BCrypt password against the repo and returns
  an `Authentication` whose principal is the user **entity** (not just the email), so downstream
  code sees a consistent principal from either a fresh login or a validated bearer token.
- **`JWTAuthFilter`** — a `OncePerRequestFilter` that extracts the `Bearer` token, validates it,
  and populates `SecurityContextHolder`. Wire it explicitly with
  `.addFilterBefore(jwtAuthFilter, UsernamePasswordAuthenticationFilter.class)`. A bare
  `@Component` filter is **not** sufficient — Boot would register it after Spring Security's
  `FilterChainProxy`, so the token would never reach the context before authorization runs.
- **Roles** on the user entity mapped with `@ElementCollection` + `@CollectionTable` fetched
  `EAGER` (they back `getAuthorities()`, read outside any `@Transactional` boundary, so `LAZY`
  risks `LazyInitializationException`).

## Refresh tokens: rotation + reuse detection

- Store the refresh token as a **SHA-256 hash** (not BCrypt) — it's already high-entropy, and a
  deterministic hash allows an exact-match `findByTokenHash` lookup (BCrypt's per-call salt makes
  it unsuitable for lookup). The raw token is never stored.
- **Refresh rotates:** validate signature + expiry, look up the row by hash, reject if missing or
  already `revoked` (**reuse detection** — a rotated-away or logged-out token can't be replayed),
  flip that row to `revoked`, mint a new access+refresh pair, persist the new hash.
- **Logout** hashes the presented token and revokes the matching row if present — idempotent, no
  JWT parsing needed.
- Both "malformed/expired token" and "not tracked / already revoked" collapse to the **same**
  `InvalidCredentialsException` (401) as a failed login — never reveal which check failed. A
  failed login likewise collapses "no such email" and "wrong password" into one error.

## Password policy: `@SecurePassword`

A Bean-Validation constraint in `common/validation/` on every registration DTO's `password`:

1. **Max length ≤ 72** (checked first) — BCrypt throws `IllegalArgumentException` above 72 bytes;
   without this it surfaces as a 500 instead of a clean 400. `LoginRequest.password` carries the
   same `@Size(max = 72)` but is exempt from complexity/HIBP (a stored password may predate the policy).
2. **Complexity** — length ≥ 10, at least one upper, one lower, one digit, one non-alphanumeric.
3. **Compromise check** — delegates to a `CompromisedPasswordChecker` bean
   (`HaveIBeenPwnedRestApiPasswordChecker`), which uses k-anonymity (only the first 5 hex chars of
   the SHA-1 leave the server). On HIBP network failure, behaviour is driven by a
   `fail-open` config property (default `true`: log a warning and allow, so an outage doesn't block
   registration).

Passwords are always hashed with the `BCryptPasswordEncoder` bean — never stored/logged in
plaintext, never compared with `String.equals`.

## Multi-step password reset (pattern)

3 steps, cryptographically secure and non-enumerable:
1. **Forgot password** — returns `200` *unconditionally* (anti-enumeration). Generates a 6-digit
   OTP via `SecureRandom`, stored only as a SHA-256 hash, never logged; rate-limited (e.g. 3/hour);
   10-min expiry; a new request supersedes prior unused OTPs; sends a localized HTML email.
2. **Verify OTP** — max 5 attempts then permanent invalidation (brute-force defense); on success
   mints a high-entropy 32-byte opaque reset token, stored as SHA-256 hash with a 10-min TTL.
3. **Reset password** — validates the reset-token hash, single-use (nulls the hash immediately),
   enforces `@SecurePassword`, **revokes all refresh tokens** for the user (logs out all devices),
   and emails a confirmation.

## Filter-level 401/403 envelopes

Implement `AuthenticationEntryPoint` (401) and `AccessDeniedHandler` (403) that delegate to
`HandlerExceptionResolver`, and wire them via
`.exceptionHandling(ex -> ex.authenticationEntryPoint(...).accessDeniedHandler(...))` so
filter-level security failures return the same `BaseResponseBody.Fail` envelope as everything else.

## PHI/PII golden rules

- **Never log** a raw request/response body, a full entity, or any field with a name, DOB,
  diagnosis, address, phone, or national ID — at *any* level including `debug`. Log identifiers
  (`patientId`) instead of the person.
- **Never put PHI/PII in a URL** (path or query) — they land in access logs, browser history, and
  proxy logs. Use opaque numeric/UUID identifiers.
- Every write to a sensitive record should be attributable to an authenticated actor
  (`createdBy`/`updatedBy` — see `references/database.md`); this is the audit-trail foundation.
- Production enforces **TLS** (`server.ssl.*` or LB termination with
  `server.forward-headers-strategy=framework`); never disable cert validation to work around a
  local issue.
- All JWT/session secrets come from environment variables — never hardcoded, never committed even
  as a real-looking placeholder.
