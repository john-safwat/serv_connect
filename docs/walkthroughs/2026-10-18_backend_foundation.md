# Backend Foundation

- **Date:** 2026-10-18
- **Plan:** [plans/2026-10-18_backend_foundation.md](../../plans/2026-10-18_backend_foundation.md)

## Summary

Turned the Spring Initializr skeleton in `sev_connect_backend/` into the base all MVP modules build on: Gradle build with ktlint and Testcontainers, dev/prod/test profiles, local Postgres + Redis via `compose.yaml`, the `BaseResponseBody` envelope with a global localized exception handler, ar/en bundles, default-deny stateless security with env-driven CORS, audited and syncable base entities backed by `sync_change_seq`, tenant context, fail-open Redis caching, logging with correlation IDs, and a non-root Docker image.

## BRD coverage

No `FR` delivered end-to-end. Groundwork for §10.3, §11, NFR-1, NFR-3, NFR-4, NFR-6, NFR-9, NFR-11.

## Files changed

Backend (`sev_connect_backend/`): `build.gradle`, `settings.gradle`, `.gitignore`, `.editorconfig`, `.dockerignore`, `Dockerfile`, `compose.yaml`, `.env.example`; resources `application*.properties`, `logback-spring.xml`, `i18n/messages*.properties`, `db/migration/V1__create_change_seq_sequence.sql`; `src/main/kotlin/.../` `SevConnectBackendApplication`, `HomeController`, and `common/{response,exception,exception_handler,i18n,config,security,base,audit,tenant,logging}`; tests under `src/test` (32 tests), `src/test/resources/application.properties`, test-only migration `db/test-migration/V9000__create_sync_probe_table.sql`. `HELP.md` removed. Docs `docs/01` to `docs/06`, `docs/README.md`.

## API / sync contract changes

Conventions only (`docs/03`, `docs/06`): envelope, headers, status codes, base sync entity. No `/api/v1` endpoints. `GET /` and `GET /actuator/health` are public.

## DB schema changes

`V1`: sequence `sync_change_seq`. No domain tables.

## Security & safeguarding impact

Default-deny; 401/403 in the envelope; CORS pinned to configured origins (wildcard rejected); prod fails fast without env; correlation IDs sanitized; handler logs path only; 500s leak nothing. No PII or Sensitive data introduced.

## Localization

New keys in both `en` and `ar`: see `docs/05-localization.md`.

## Testing

The count is now 58 (32 initial, 22 from the QA round, 4 from the security round — see below); `./gradlew clean build` green (compile, ktlint, tests): handler (validation en/ar, malformed JSON, 404/409/500), locale resolution, security (public/401/CORS/correlation id), fail-open cache, auditor, CORS properties, and a Postgres integration test for `SyncableEntity` (`changeSeq`, `@Version`, tombstone, audit columns) plus Flyway V1.

## Config

`DATABASE_URL`, `DATABASE_USERNAME`, `DATABASE_PASSWORD`, `REDIS_HOST`, `REDIS_PORT`, `REDIS_PASSWORD`, `CORS_ALLOWED_ORIGINS`, `SPRING_PROFILES_ACTIVE`; local-only `POSTGRES_PORT`, `REDIS_PORT` for compose. See `sev_connect_backend/.env.example`.

## Known limitations / follow-ups

- Feature flags (`@RequireFeature`) deferred to the admin plan; no MinIO and no `scripts/deploy.sh` yet.
- JWT, permissions, scope evaluator, `AuditEntry` arrive with the identity and audit plans; `TenantContextFilter` binds a tenant only once the principal implements `TenantPrincipal`.
- Cache region names are placeholders (`reference-data`, `org-config`) until a feature needs them.
- JPA auditing lives in `JpaAuditingConfig` (not on the application class) so web-slice tests need no JPA metamodel.

## QA fixes (2026-10-18, uncommitted)

- `CacheConfig`: removed `@ConditionalOnBean(RedisConnectionFactory)` so the custom Redis cache manager (TTLs, Jackson 3 serializer) is actually used; `CacheManagerWiringTest` (Redis Testcontainer) proves the TTLs and JSON values.
- `GlobalExceptionHandler`: added 415, 406 (JSON envelope pinned), 400 for missing header/part/method validation/`ConstraintViolationException`, 409 for optimistic-lock and `DataIntegrityViolationException` (generic message). New keys `error.unsupported-media-type`, `error.not-acceptable`, `error.data-conflict` in en and ar. The catch-all now logs class + path only at error (stack at debug), so no row values reach logs.
- `SyncableEntity.equals/hashCode` use `Hibernate.getClass` (proxy safe).
- Tests: 22 added (54 total) covering the new handlers, 403 envelope (en/ar), 401 without `WWW-Authenticate`, `TenantContextFilter`, `CorrelationIdFilter`, i18n bundle parity, CORS empty list.
- Test config moved to `application-test.properties` (profile `test`, set by the Gradle `test` task) so main defaults are exercised. IDE runs need the `test` profile too.
- Docs: `docs/03` error mapping, `docs/05` keys, `docs/06` known limitation (out-of-order `change_seq` commits), `docs/01` env table, `.env.example` note.

### Security-audit follow-ups (not fixed here)

- **M3 (identity plan):** replace the `/api/v1/auth/**` permitAll wildcard with explicit method + path matchers; CSRF protection (Origin / Sec-Fetch-Site check or double-submit) on cookie-based `/refresh` and `/logout`; `allowCredentials` only with pinned origins.
- **L2 (identity plan, before IP rate limiting):** `forward-headers-strategy=framework` trusts client `X-Forwarded-*`; switch to native + trusted proxy CIDR or guarantee the load balancer strips them; never build links from the request host.
- **L3 (before first prod deploy):** `dev` is the default profile; add a guard refusing `dev` with a non-local DB, or require the profile explicitly.
- **L4 (before the first cache region is used):** narrow the Redis polymorphic type allow-list to exact types / typed per-region serializers.
- **L8 (CI / devops):** Gradle wrapper `distributionSha256Sum`, pinned image digests, dependency CVE scan in CI.
- **S1 (identity plan / first Map DTO):** sanitize client-controlled JSON path segments before logging or echoing them in `handleNotReadable`.

## Security-audit fixes (2026-10-18, uncommitted)

M1 `.dockerignore` globs + image copies only `src/main`; M2 prod `RequiredSecretsProperties` rejects blank secrets, Redis TLS default (`REDIS_SSL_ENABLED`), TLS note for `DATABASE_URL`; M4 `AuditorAwareImpl` requires a typed `UserPrincipal` for authenticated callers; L1 deny-all `UserDetailsService` (no generated password in the app context); L5 cache handler logs class + cache name only; L6 compose binds to `127.0.0.1`; L7 `.gitignore` secrets patterns. Tests now 58.
