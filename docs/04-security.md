# Security

## Foundation posture (backend)

- Default-deny: every path requires authentication except `SecurityConstants.publicApis()`: `/`, `/actuator/health`, `/api/v1/auth/**` (the wildcard is temporary — see open item M3). Until the identity plan lands, any other path returns the `401` `BaseResponseBody.Fail` envelope.
- Stateless sessions, CSRF disabled (Bearer tokens, no cookies), `@EnableMethodSecurity` on so `@PreAuthorize` is enforceable.
- Filter-level 401/403 are routed through `GlobalExceptionHandler` (via `HandlerExceptionResolver`), so they share the envelope and are localized.
- Only `health` is exposed by actuator, with no details.
- CORS: allowed origins come from `CORS_ALLOWED_ORIGINS` (`serveconnect.cors.allowed-origins`); never `*` (rejected at startup); missing in prod aborts startup. Allowed methods GET/POST/PUT/PATCH/DELETE/OPTIONS; allowed headers `Authorization`, `Content-Type`, `Accept-Language`, `Idempotency-Key`, `X-Correlation-Id`.
- Secrets only via environment; the `prod` profile has no secret defaults and fails fast. Dev defaults are clearly fake and only for the compose services.

## Tenancy and auditing

- `TenantContext` holds the caller's `orgId`; `TenantContextFilter` binds it from a `TenantPrincipal` after authentication and always clears it. Services take the org from `TenantContext`, never from a request body.
- JPA auditing records `created_by` / `updated_by` from the authenticated user's UUID, falling back to the system UUID. `AuditEntry` (Sensitive read/write audit) arrives with the audit plan.

## Logging rules

- No PII, Sensitive data, request bodies, tokens, or cache keys in logs. The global handler logs the request path and exception only.
- `X-Correlation-Id` is accepted only if it is a well-formed UUID (anything else is replaced), preventing log injection. The id is a random UUID, never user data.
- 500 responses never include exception text.

## Data classification

No PII or Sensitive fields exist yet. Classes (from the BRD): Public, Internal, PII (names, contact, birthdate, photo), Sensitive (medical, pastoral notes, consent). Sensitive data gets its own table and endpoint, is audited on every read, and is encrypted at rest on the device. Column encryption (`FIELD_ENCRYPTION_KEY`) lands with the first Sensitive table.

## Permission catalog

Empty on the server until the identity plan lands. Both clients (`serv_connect_mobile` and `serv_connect_dashboard`) ship `PermissionChecker`, `ScopeType` (`ORG`, `STAGE`, `GROUP`, `SELF`, `CHILDREN`), `ScopeGuard`, and `<RequirePermission>` so every route and action checks permission keys + scope and never branches on role names.

## Mobile client security & safeguarding (`serv_connect_mobile/` — M0)

- **Secure token & key storage:** `accessToken`, `refreshToken`, `lastServerAuthAt`, and the 256-bit Hive encryption key live exclusively in `SecureStorage` (`flutter_secure_storage`, Keychain/Keystore) — never in `SharedPreferences`, plain Hive boxes, or logs.
- **Encrypted local database (`NFR-4`, `FR-13.7`):** `HiveStorage` opens every local box (`served_members`, `sensitive_records`, `outbox_mutations`, `org_config`) with `HiveAesCipher`. `sensitive_records` is isolated from general member cache and purged immediately on `purgeSensitiveAndScopedData()` (scope revocation, logout, or offline grace window expiry).
- **Offline session grace window (`FR-1.3`):** On network/timeout/5xx failure during token refresh, `AuthSession` keeps the servant signed in (`AuthenticatedOffline`) while within `DEFAULT_OFFLINE_GRACE_DAYS`, transitions to read-only `OfflineGraceExpired` (wiping `sensitive_records`) if expired offline, and only forces logout when `/api/v1/auth/refresh` explicitly returns `401` (while preserving unsynced `outbox_mutations`).
- **Photo consent gate (`FR-13.5`):** `ServeMemberAvatar` renders a network image only when `photoConsent == true` and `imageUrl` is non-empty, falling back to deterministic initials otherwise.
- **PII-safe logging & TLS (`NFR-4`):** `AppLogger` is a no-op in release builds and scrubs sensitive keys (`authorization`, `password`, `otp`, `token`, `phone`, `email`, `medical`, `note`). `LoggingInterceptor` logs HTTP method, path, and status code only. Release Android (`android:usesCleartextTraffic="false"`) and iOS (`NSAllowsArbitraryLoads = false`) disallow cleartext HTTP; `AppEnvironment.assertConfigured()` rejects non-HTTPS URLs in `staging`/`prod`.

## Web dashboard security & safeguarding (`serv_connect_dashboard/` — D0)

- **Access token in memory only (`AuthSession`):** `accessToken`, `RoleAssignment`s, and scopes are held strictly in memory inside `AuthSession` — never written to `localStorage`, `sessionStorage`, `IndexedDB`, or JS-readable cookies.
- **Idle session lock (`IdleLockWatcher`):** Tracks user activity against wall-clock time (`targetTimestampMs - Date.now()`) and locks the session + calls `queryClient.clear()` after `VITE_IDLE_TIMEOUT_MINUTES` of inactivity on shared church office desktops.
- **Zero browser-storage persistence of PII/Sensitive data:** No TanStack Query cache persistence is configured; logout, `401` refresh failure, or idle lock immediately clears `AuthSession` and `QueryClient`.
- **Photo consent gate (`FR-13.5`):** `<ServeMemberAvatar />` checks `photoConsent === true` before rendering `<img loading="lazy" />`, falling back to initials when `false`.
- **PII-safe logging & HTTPS:** `AppLogger` is a no-op in `prod` and scrubs sensitive keys; `oxlint` enforces `no-console` across `src/`. `AppEnvironment.assertConfigured()` rejects missing/placeholder `VITE_*` keys and non-HTTPS `VITE_API_BASE_URL` in `staging`/`prod`.

## Hardening notes (security audit, 2026-10-18)

- Auditing: `AuditorAwareImpl` uses the system user only when there is no or an anonymous authentication. An authenticated caller must expose `UserPrincipal.userId`; a principal without one throws instead of being attributed to the system user. The user id is never parsed from `Authentication.name`.
- A deny-all `UserDetailsService` replaces Boot's generated default user until the identity plan lands.
- Prod: empty `DATABASE_*` / `REDIS_HOST` / `REDIS_PASSWORD` abort startup; Redis TLS on by default; `DATABASE_URL` must use `sslmode=verify-full` (or `require`).
- Build hygiene: `.dockerignore` and `.gitignore` exclude env files, keystores, certificates, and service-account JSON; the image build copies only `src/main`.
- Cache errors log only the exception class and cache name at warn.

### Open items (tracked in the backend foundation plan)

- **M3 (identity plan):** replace the `/api/v1/auth/**` permitAll wildcard with explicit method + path matchers; add CSRF protection (Origin / `Sec-Fetch-Site` check or double-submit) on cookie-based refresh and logout; `allowCredentials` only with pinned origins.
- **M4 (done here):** see Auditing above; identity must implement `UserPrincipal` and `TenantPrincipal`.
- **L2 (identity plan, before any IP rate limiting):** `server.forward-headers-strategy=framework` trusts client-supplied `X-Forwarded-*`; switch to `native` with the load balancer's CIDR as trusted proxies (or guarantee the LB strips these headers), and never build links from the request host.
- **L3 (before the first prod deploy):** `dev` is the default profile; add a guard that refuses `dev` against a non-local database, or require the profile explicitly.
- **L4 (before the first cache region is used):** narrow the Redis polymorphic type allow-list to exact types, or use typed per-region serializers.
- **L8 (CI / devops):** pin the Gradle wrapper with `distributionSha256Sum`, pin Docker images by digest, and run a dependency CVE scan in CI.
- **S1 (identity plan / first `Map` DTO):** sanitize client-controlled JSON path segments before logging or echoing them in the malformed-request handler.
- **R1 (before the first prod deploy):** Postgres TLS is only documented; add a prod check that `DATABASE_URL` carries `sslmode=require|verify-ca|verify-full`. Redis TLS can be disabled with `REDIS_SSL_ENABLED=false`.
