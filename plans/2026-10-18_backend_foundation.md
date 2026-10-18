# Backend Foundation — Plan

| Field | Value |
| --- | --- |
| Status | Done |
| Area | backend |
| BRD | §10.3, §11 (groundwork), NFR-1, NFR-3, NFR-4, NFR-6, NFR-9, NFR-11 — no `FR` delivered end-to-end; `FR-16.5` [P2] only if Open decision 2 says so |
| Phase | MVP (infrastructure) |
| Created | 2026-10-18 |
| Approved | 2026-10-18 — "Approved — use the recommended option for all 6 open decisions and start building." |
| Depends on | none |
| Walkthrough(s) | [2026-10-18_backend_foundation](../docs/walkthroughs/2026-10-18_backend_foundation.md) |
| Blocked / abandoned reason | — |

---

## 1. Goal

Turn the bare Spring Initializr skeleton in `sev_connect_backend/` into the foundation every MVP module builds on: build plugins and starters, dev/prod/test profiles, local Postgres + Redis, the `BaseResponseBody` envelope and global exception handler, ar/en message bundles, audited + syncable base entities, tenant context, default-deny security, fail-open Redis caching, logging with correlation IDs, a container image, and the shared `docs/` skeleton. It follows the `spring-backend` skill (Elevate Health Care conventions) translated to Kotlin, with `sev_connect_backend/CLAUDE.md` winning wherever they differ. Step 0 of backend `CLAUDE.md §21.2`.

## 2. Scope & Decisions

| # | Decision | Choice |
| --- | --- | --- |
| 1 | Skill vs. project rules | Skill conventions (feature-sliced packages, envelope, global handler, Flyway, fail-open cache, logback, Accept-Language i18n, docs discipline) apply; its Java/Maven/Lombok/MapStruct specifics are replaced by Kotlin + Gradle + extension-function mappers per backend `CLAUDE.md §6, §20`. The skill's `CLAUDE.md.template` is **not** used — the project already has its own `CLAUDE.md`. |
| 2 | Base package | Keep `com.john.sev_connect_backend` (no rename, backend `CLAUDE.md §1.1`). |
| 3 | Web stack | Spring MVC (servlet) + blocking JPA; no WebFlux. |
| 4 | Boot 4 starters | Use Boot 4's modular starters (`spring-boot-starter-webmvc`, `-validation`, `-data-jpa`, `-security`, `-flyway`, `-data-redis`, `-cache`, `-actuator`, `spring-boot-docker-compose`) + `flyway-database-postgresql`, `postgresql`, Jackson 3 Kotlin module. Versions managed by the Boot BOM — exact artifact names verified against Boot 4.1.1 while implementing. |
| 5 | Identity/JWT | **Not in this plan.** Security gets a default-deny `SecurityFilterChain`, the 401/403 handlers, and CORS only. `JwtProperties`, `JWTService`, `JWTAuthFilter`, and the permission/scope model ship with the `identity` plan (§21.2 step 1). |
| 6 | First migration | `V1__create_change_seq_sequence.sql` — the global Postgres sequence `SyncableEntity.changeSeq` draws from. No domain tables yet. |
| 7 | Lint | ktlint via the `org.jlleitschuh.gradle.ktlint` plugin, wired into `check`. |
| 8 | Mocks | MockK + `springmockk`. |

### 2.1 Non-goals

- Any domain feature package (`identity`, `members`, `admin`, …) and any `/api/v1` endpoint.
- JWT issuing/verification, OTP, invitations, permission catalog, `ScopePermissionEvaluator` (identity plan).
- Column encryption converter for Sensitive fields (`FIELD_ENCRYPTION_KEY`) — lands with the first Sensitive table.
- S3/MinIO, FCM, SMTP, SMS wiring — land with the feature that first needs them.
- springdoc-openapi (only once a Boot 4-compatible release exists, backend `CLAUDE.md §8`).
- `scripts/deploy.sh` (needs a target host/registry — see Open decision 5).

## 3. Current State

- `SevConnectBackendApplication.kt`, `SevConnectBackendApplicationTests.kt` (context-loads test).
- `application.properties` with only `spring.application.name`.
- `build.gradle`: Kotlin 2.3.21, Boot 4.1.1, `spring-boot-starter` only, Java 25 toolchain.
- **Local machine has JDK 17 only** — the Java 25 toolchain won't resolve without auto-provisioning (Open decision 1).
- Docker 28 is installed (needed for `compose.yaml` and Testcontainers).
- Root `docs/` holds only `00-brd.md`.

## 4. Design

### 4.1 Backend

Packages / classes (all under `src/main/kotlin/com/john/sev_connect_backend/`):

| Package | Classes | Notes |
| --- | --- | --- |
| (root) | `SevConnectBackendApplication` (modified: `@EnableJpaAuditing(auditorAwareRef = "auditorAwareImpl")`, `@ConfigurationPropertiesScan`), `HomeController` | `GET /` returns a `BaseResponseBody.Success` with app name only |
| `common/response` | `BaseResponseBody` (sealed: `Success<T>`, `Fail`), `FieldError`, `PageResponse<T>` | Translated from skill asset `BaseResponseBody.java`/`FieldError.java`; never `204` |
| `common/exception` | `EntityNotFoundException`, `AlreadyExistsException`, `InvalidCredentialsException`, `StaleVersionException`, `BusinessRuleException`, `FeatureDisabledException` | Each carries a `MessageKeys` key + args, never a raw user string |
| `common/exception_handler` | `GlobalExceptionHandler` (`@RestControllerAdvice`) | Maps domain exceptions, `MethodArgumentNotValidException`, Jackson 3 deserialization errors (field name → 400), `AccessDenied`/`Authentication` exceptions, catch-all 500 (path + exception logged, generic localized message) |
| `common/i18n` | `MessageKeys`, `SupportedLocales` | en (default) + ar |
| `common/config` | `LocalizationConfig` (`AcceptHeaderLocaleResolver` restricted to `SupportedLocales`), `ValidationConfig` (validator uses `MessageSource`), `SecurityConfig`, `CorsProperties` (`@Validated`), `CacheConfig`, `JacksonConfig` (Kotlin module) | One class per concern |
| `common/security` | `SecurityConstants` (`publicApis()`: `/`, `/actuator/health`, `/api/v1/auth/**`), `RestAuthenticationEntryPoint`, `RestAccessDeniedHandler` | Both write the `Fail` envelope via the handler; stateless, CSRF off, `@EnableMethodSecurity` |
| `common/base` | `BaseEntity` (`@MappedSuperclass`: `createdAt`, `updatedAt`, `createdBy`, `updatedBy` — `Instant`/`UUID`), `SyncableEntity` (extends it: `id: UUID` client-suppliable, `orgId`, `@Version version`, `changeSeq`, `deletedAt`) + `ChangeSeqListener` assigning `nextval('sync_change_seq')` on persist/update | Plain classes, id-based `equals`/`hashCode` |
| `common/audit` | `AuditorAwareImpl` | Caller UUID from `SecurityContextHolder`, system UUID `00000000-…` fallback |
| `common/tenant` | `TenantContext`, `TenantContextFilter` | Holds caller `orgId`; filter is registered now and populated once the identity plan puts `org_id` on the principal |
| `common/logging` | `CorrelationIdFilter` | `X-Correlation-Id` in/out, MDC `correlationId` |

Resources:

- `application.properties` (defaults, `spring.profiles.active=dev`, `spring.messages.basename=i18n/messages`, `spring.jpa.hibernate.ddl-auto=validate`, `spring.jpa.open-in-view=false`, actuator exposes `health` only).
- `application-dev.properties` (compose Postgres/Redis via `${VAR:fake-local-default}`, docker-compose enabled).
- `application-prod.properties` (every value `${ENV}` with no defaults for secrets, docker-compose disabled, `server.forward-headers-strategy=framework`).
- `src/test/resources/application.properties` (hermetic: Testcontainers or H2 per Open decision 3, `spring.cache.type=simple`, docker-compose disabled).
- `i18n/messages.properties` + `i18n/messages_ar.properties` — error + Jakarta constraint overrides, keys in sync.
- `logback-spring.xml` — console + rolling `logs/serveconnect.log` (20MB/file, 30d, 1GB cap), pattern with `%X{correlationId:-}` (from skill asset).
- `db/migration/V1__create_change_seq_sequence.sql`.

Project files: `build.gradle`, `settings.gradle` (toolchain resolver), `compose.yaml` (Postgres 17 + Redis 7, fake local creds), `.env.example`, `.gitignore` (+ `logs/`, `.env`, `application-local.*`), `Dockerfile` (two-stage, Java 25, non-root — from skill asset), `.dockerignore`. Delete the generated `HELP.md` (already gitignored, untracked).

Entities & migrations: no domain entities. `V1` creates `sync_change_seq`.
Endpoints: `GET /` (public, landing) and `GET /actuator/health` (public). Neither is under `/api/v1`, so neither is a client contract.
Business rules: N/A.

### 4.2 Mobile

N/A — backend only.

### 4.3 Dashboard

N/A — backend only. CORS allow-list is env-driven (`CORS_ALLOWED_ORIGINS`) so the dashboard dev server can be allowed locally.

### 4.4 API contract changes (`docs/03-api-reference.md`)

Creates `docs/03-api-reference.md` documenting the conventions every endpoint will follow: `/api/v1` base path, `BaseResponseBody` `Success`/`Fail` shapes, `FieldError`, page envelope, status codes (no `204`), `Accept-Language` (`en`, `ar`), `X-Correlation-Id`, idempotency rule. No `/api/v1` endpoints yet.

### 4.5 Sync (`docs/06-sync.md`)

| Entity | Syncable? | Conflict strategy | Scope filter |
| --- | --- | --- | --- |
| — (base class `SyncableEntity` only) | groundwork | per data type, declared by each entity later | per entity later |

Creates `docs/06-sync.md` with the protocol from BRD §11 / backend `CLAUDE.md §12` (change token = `change_seq`, tombstones, revocations, per-type strategies) and an empty entity table.

## 5. Security & Safeguarding

- Permissions added: none. `@EnableMethodSecurity` on; every non-public path returns 401 until identity lands.
- Data classification: no PII/Sensitive fields introduced.
- Audited reads/writes: `createdBy`/`updatedBy` auditing wired; `AuditEntry` comes with the audit plan.
- Logging: handler logs path + exception only; no bodies. Correlation ID is a random UUID, not user data.
- Secrets: prod profile has no secret defaults; `CorsProperties` is `@Validated` so prod fails fast without `CORS_ALLOWED_ORIGINS`. `.env.example` lists every variable without values.
- On-device storage: N/A.

## 6. Localization

- New keys (en + ar): `error.generic`, `error.validation`, `error.not-found`, `error.already-exists`, `error.unauthorized`, `error.forbidden`, `error.invalid-credentials`, `error.stale-version`, `error.feature-disabled`, `error.malformed-request`, plus Jakarta overrides (`jakarta.validation.constraints.NotBlank.message`, `NotNull`, `Size`, `Email`, `Pattern`, `Past`, `Positive`, `Min`, `Max`).
- RTL considerations: none server-side; backend returns machine values only.

## 7. Testing

- Backend:
  - `GlobalExceptionHandlerTest` (`@WebMvcTest` with a test-only controller): 400 validation with field errors, 400 malformed JSON with field name, 404, 409, 500 hides message — each in `en` and `ar`.
  - `SecurityConfigTest`: public paths 200, any other path 401 envelope.
  - `LocalizationConfigTest`: `ar` → Arabic, unsupported → English.
  - `CacheConfigTest`: error handler swallows Redis failures (fail-open).
  - `AuditorAwareImplTest`: system UUID when unauthenticated.
  - `SyncableEntity` integration test against Postgres: `changeSeq` increases on insert/update; `@Version` bumps.
  - Context-loads test passes with the test profile; Flyway `V1` applies.
- Mobile / Dashboard: N/A.
- Conflict / idempotency tests: N/A (no syncable entity yet).
- `./gradlew clean build` (compile + ktlint + tests) green.

## 8. Docs to Update

- [x] `docs/01-project-overview.md` — architecture, three projects, config/env table, BRD coverage table (all modules "not started")
- [x] `docs/02-database-schema.md` — conventions (UUID PKs, `org_id`, `timestamptz`, `change_seq`) + migration list (`V1`)
- [x] `docs/03-api-reference.md` — conventions + envelope (§4.4)
- [x] `docs/04-security.md` — default-deny, public paths, CORS, data classes, logging rules; permission catalog section empty
- [x] `docs/05-localization.md` — locales, `Accept-Language`, key conventions, RTL rule
- [x] `docs/06-sync.md` — protocol skeleton (§4.5)
- [x] `docs/07-mobile-architecture.md` / `docs/08-dashboard-architecture.md` — N/A
- [x] `docs/README.md` — index of all docs
- [x] Walkthrough `docs/walkthroughs/2026-10-18_backend_foundation.md` + `docs/walkthroughs/README.md`

## 9. Work Breakdown

- [x] 1. Build setup — files: `build.gradle` (kotlin `jpa` plugin, `allOpen` for `Entity`/`MappedSuperclass`/`Embeddable`, starters, ktlint, MockK/springmockk, Testcontainers if chosen), `settings.gradle` (toolchain resolver), `.gitignore` — verify: `./gradlew clean build` green on the skeleton.
- [x] 2. Profiles & local infra — files: `application*.properties`, test `application.properties`, `compose.yaml`, `.env.example`, `logback-spring.xml`, `CorrelationIdFilter` — verify: `./gradlew bootRun` starts Postgres + Redis and `/actuator/health` is `UP`.
- [x] 3. Envelope, exceptions, i18n — files: `common/response/*`, `common/exception/*`, `common/exception_handler/GlobalExceptionHandler`, `common/i18n/*`, `LocalizationConfig`, `ValidationConfig`, `JacksonConfig`, `i18n/messages*.properties`, `HomeController` + tests — verify: handler + localization tests.
- [x] 4. Security skeleton — files: `SecurityConfig`, `CorsProperties`, `common/security/*` + tests — verify: public 200 / other 401 envelope.
- [x] 5. Persistence base & tenancy — files: `BaseEntity`, `SyncableEntity`, `ChangeSeqListener`, `AuditorAwareImpl`, `common/tenant/*`, `V1__create_change_seq_sequence.sql`, app class annotations + tests — verify: Flyway `V1` applies; `changeSeq`/`version` test.
- [x] 6. Caching — files: `CacheConfig` (named regions + TTLs, fail-open `CacheErrorHandler`, Jackson 3 Redis serializer) + test — verify: fail-open test.
- [x] 7. Container image — files: `Dockerfile`, `.dockerignore` — verify: `docker build` succeeds and the container starts with the `prod` profile when env vars are given, and fails fast without them.
- [x] 8. Docs + walkthrough — files: §8 list — verify: `git status -- docs/ plans/`.

## 10. Acceptance Criteria

- [x] `./gradlew clean build` passes (compile, ktlint, tests) with no new warnings.
- [x] `./gradlew bootRun` on a clean machine with Docker starts local Postgres + Redis and serves `GET /actuator/health` → `UP`.
- [x] Any unknown or non-public path returns `401` in the `BaseResponseBody.Fail` envelope; errors are localized via `Accept-Language` (`en`, `ar`).
- [x] The prod profile refuses to start when a required variable is missing.
- [x] No secrets, `build/`, `.gradle/`, `.kotlin/`, `.idea/`, `logs/` committed.
- [x] Docs in §8 exist and match the code.

## 11. Open Decisions

| # | Question | Options | Answer (date) |
| --- | --- | --- | --- |
| 1 | JDK 25 isn't installed (only JDK 17). How should the Java 25 toolchain resolve? | (a) Add the foojay toolchain resolver to `settings.gradle` so Gradle downloads JDK 25 automatically — **recommended**; (b) you install JDK 25 yourself | (a) foojay toolchain resolver (2026-10-18) |
| 2 | Backend `CLAUDE.md §21.2` lists feature flags (`@RequireFeature`) in the foundation, but BRD marks FR-16.5 as **[P2]**. Build it now? | (a) Defer to the `admin` plan, when there is a module to gate and a table to store flags — **recommended**; (b) build a config-driven version now | (a) defer to the `admin` plan (2026-10-18) |
| 3 | Test database | (a) Testcontainers Postgres, the same engine as prod so Flyway SQL is tested for real — **recommended**; (b) H2 in Postgres mode (faster, no Docker) | (a) Testcontainers Postgres (2026-10-18) |
| 4 | MinIO in `compose.yaml` now? | (a) No, add it with the first media feature — **recommended**; (b) yes, now | (a) no MinIO yet (2026-10-18) |
| 5 | `scripts/deploy.sh` (skill's VPS deploy) | (a) Defer until you have a registry + host — **recommended**; (b) add a template now with placeholders | (a) defer `deploy.sh` (2026-10-18) |
| 6 | Pipeline: this is infrastructure with no business choices, so the `business-development` discussion loop adds nothing | (a) Skip step 1 for this plan; run backend-developer → qa-backend → security-auditor → your confirmation → git-expert — **recommended**; (b) run the full pipeline | (a) skip step 1; build → QA → security → confirmation → git-expert (2026-10-18) |

## 12. Risks & Mitigations

| Risk | Mitigation |
| --- | --- |
| Boot 4.1 starter / Jackson 3 artifact names differ from the skill's Boot 3-era templates | Verify each artifact against the Boot 4.1.1 BOM while implementing; log any change in the progress log |
| Hibernate needs open classes and no-arg constructors for Kotlin entities | `kotlin-jpa` + `allOpen` plugins in step 1; covered by the step 5 integration test |
| `changeSeq` assigned from a DB sequence adds a round-trip per write | Acceptable at MVP scale; revisit with batch allocation if sync profiling shows it |
| `changeSeq` is drawn at flush, so concurrent transactions can commit out of order and a pull token could skip a row | Documented in `docs/06-sync.md` Known limitations; the `sync` plan must pull only up to a safe watermark / lag window and let clients re-pull a small overlap |
| Docker not running blocks `bootRun` and Testcontainers | Documented in `docs/01` local-setup section |

### Known follow-ups (security audit, not fixed in this plan; each tagged with the plan that must address it)

- **M3 (identity plan):** replace the `/api/v1/auth/**` permitAll wildcard with explicit method + path matchers; CSRF protection (Origin / Sec-Fetch-Site check or double-submit) on cookie-based `/refresh` and `/logout`; `allowCredentials` only with pinned origins.
- **L2 (identity plan, before IP rate limiting):** `forward-headers-strategy=framework` trusts client `X-Forwarded-*`; switch to native + trusted proxy CIDR or guarantee the load balancer strips them; never build links from the request host.
- **L3 (before first prod deploy):** `dev` is the default profile; add a guard refusing `dev` with a non-local DB, or require the profile explicitly.
- **L4 (before the first cache region is used):** narrow the Redis polymorphic type allow-list to exact types / typed per-region serializers.
- **L8 (CI / devops):** Gradle wrapper `distributionSha256Sum`, pinned image digests, dependency CVE scan in CI.
- **S1 (identity plan / first Map DTO):** sanitize client-controlled JSON path segments before logging or echoing them in `handleNotReadable`.

## 13. Progress Log

- 2026-10-18 — Plan drafted from the `spring-backend` skill + backend `CLAUDE.md §21.2` step 0. Waiting for approval and answers to the Open decisions.
- 2026-10-18 — Approved by the user with the recommended option for all six Open decisions.
- 2026-10-18 — Implementation started (backend-developer); Status set to In progress. Steps 1-8 done, uncommitted. QA and security audit still pending.
- 2026-10-18 — Step 1: Boot 4.1.1 artifacts verified against the BOM: starters `webmvc`, `validation`, `data-jpa`, `security`, `flyway`, `data-redis`, `cache`, `actuator`; `flyway-database-postgresql` 12.4.0; `tools.jackson.module:jackson-module-kotlin` 3.1.5; Testcontainers 2.0.5 (`testcontainers-junit-jupiter`, `testcontainers-postgresql`, `spring-boot-testcontainers`); MockK 1.14.5 (resolved 1.14.6) and springmockk 5.0.1; ktlint plugin 13.1.0; foojay resolver 1.0.0. Java 25 toolchain auto-provisioned (Temurin 25.0.4.1). Deviation: `tasks.jar` disabled so only the boot jar is produced (Dockerfile copies `build/libs/*.jar`).
- 2026-10-18 — Deviation: `@EnableJpaAuditing` is on `common/config/JpaAuditingConfig`, not the application class, so `@WebMvcTest` slices do not need a JPA metamodel. `@ConfigurationPropertiesScan` stays on the application class.
- 2026-10-18 — Deviation: added `LocalizedException` base class, `.editorconfig` (ktlint package-name rule off for `sev_connect_backend`), extra message keys (`common.success`, `error.field-invalid`, `error.method-not-allowed`, `error.business-rule`), extra handlers (404 no-resource, 405, bad parameter), `PageResponse`. `TenantContextFilter` is added inside the security chain (not a servlet-registered bean) so it runs after authentication; `TenantPrincipal` interface lets the identity plan supply the org. Redis is unauthenticated in `compose.yaml` because the Boot compose service connection does not carry a Redis password; compose host ports are overridable (`POSTGRES_PORT`, `REDIS_PORT`).
- 2026-10-18 — Test-only entity `SyncProbe` + test migration `V9000` exercise `SyncableEntity` against Testcontainers Postgres. 32 tests green.
- 2026-10-18 — Verification: `bootRun` (dev, ports overridden because the machine's 5432/8080 are held by another project's containers) -> `/actuator/health` UP, unknown path 401 envelope (ar and en). Docker image built; prod profile with no env aborts startup; with env it starts and serves health UP and the 401 envelope. Compose services and throwaway containers removed.
- 2026-10-18 — QA fixes (uncommitted): custom Redis cache manager now active (dropped `@ConditionalOnBean`) with a Redis Testcontainer wiring test; handler gains 415/406/400/409 mappings and PII-safe error logging; `SyncableEntity.equals` proxy-safe; 22 tests added (54 total); test config moved to `application-test.properties` with the `test` profile set by Gradle; docs (03, 05, 06, 01), `.env.example` and walkthrough updated; out-of-order `change_seq` risk documented. Dockerfile HEALTHCHECK intentionally skipped.
- 2026-10-18 — QA follow-up (uncommitted): Spring-context tests carry `@ActiveProfiles("test")` so IDE runs do not load `dev`/compose; docs/01 profile note corrected.
- 2026-10-18 — Security-audit fixes (uncommitted): M1 dockerignore/Dockerfile, M2 prod blank-secret validation + Redis TLS default, M4 typed `UserPrincipal` for auditing, L1 deny-all UserDetailsService, L5 cache log hygiene, L6 compose loopback ports, L7 gitignore. M3/L2/L3/L4/L8/S1 recorded as follow-ups. 58 tests green; image rebuilt OK.
- 2026-10-18 — Security re-audit and final QA passed (58 tests, uncommitted). `docs/04-security.md` open items extended with L2, L3, L4, L8, S1 and R1 (Postgres `sslmode` only documented, not enforced). Ready for user confirmation and commit.
- 2026-10-18 — User confirmed the commit. Status set to Done. Backend code, this plan, the backend walkthrough and docs 02/03/06 are committed; the shared docs (01, 04, 05, docs/README, walkthroughs/README, plans/README) also hold the mobile/dashboard session's uncommitted work, so they are committed together with it later.
