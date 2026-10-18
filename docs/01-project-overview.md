# ServeConnect — Project Overview

Business source of truth: [`00-brd.md`](00-brd.md). This file describes how the system is built and how far along it is.

## Architecture

| Project | Stack | Role |
| --- | --- | --- |
| `sev_connect_backend/` | Kotlin 2.3, Java 25 toolchain, Spring Boot 4.1.1, Gradle (Groovy DSL), PostgreSQL 17, Redis 7 | Server source of truth: REST + sync API, permissions, audit |
| `serv_connect_mobile/` | Flutter / Dart | Offline-first role-based mobile app |
| `serv_connect_dashboard/` | React 19, TypeScript, Vite | Online-only web/admin console |

Backend: Spring MVC (servlet) with blocking JPA, Flyway migrations, Spring Security (stateless, default-deny), Redis caching with a fail-open error handler, Jackson 3 (`tools.jackson.*`), ar/en message bundles. Base package `com.john.sev_connect_backend`; feature code goes under `features/<feature>/`, shared infrastructure under `common/`.

### Backend `common/` building blocks (foundation, 2026-10-18)

| Package | Contents |
| --- | --- |
| `common/response` | `BaseResponseBody` (`Success` / `Fail`), `FieldError`, `PageResponse` |
| `common/exception` | `LocalizedException` base + `EntityNotFound`, `AlreadyExists`, `InvalidCredentials`, `StaleVersion`, `BusinessRule`, `FeatureDisabled` |
| `common/exception_handler` | `GlobalExceptionHandler` |
| `common/i18n` | `MessageKeys`, `SupportedLocales` |
| `common/config` | `SecurityConfig`, `CorsProperties`, `CacheConfig`, `LocalizationConfig`, `ValidationConfig`, `JacksonConfig`, `JpaAuditingConfig` |
| `common/security` | `SecurityConstants`, `RestAuthenticationEntryPoint`, `RestAccessDeniedHandler` |
| `common/base` | `BaseEntity`, `SyncableEntity`, `ChangeSeqListener` |
| `common/audit` | `AuditorAwareImpl` |
| `common/tenant` | `TenantContext`, `TenantContextFilter`, `TenantPrincipal` |
| `common/logging` | `CorrelationIdFilter` |

## Local setup (backend)

1. Install and start Docker (needed for `compose.yaml` and for the Testcontainers-based tests). JDK 25 is auto-provisioned by the Gradle foojay toolchain resolver; no manual install needed.
2. `cd sev_connect_backend && ./gradlew bootRun` — the `dev` profile starts the compose Postgres + Redis automatically and applies Flyway migrations.
3. `GET http://localhost:8080/actuator/health` returns `UP`.
4. If host ports are taken, override them: `POSTGRES_PORT=15432 REDIS_PORT=16379 SERVER_PORT=18080 ./gradlew bootRun`.
5. `./gradlew clean build` runs compile, ktlint, and all tests.

## Configuration (backend environment variables)

| Variable | Required in | Notes |
| --- | --- | --- |
| `SPRING_PROFILES_ACTIVE` | all | `dev` (default), `prod`; tests run under the `test` profile (set by the Gradle test task and by `@ActiveProfiles("test")`) |
| `DATABASE_URL`, `DATABASE_USERNAME`, `DATABASE_PASSWORD` | prod | dev defaults point at compose with fake credentials |
| `REDIS_HOST`, `REDIS_PORT`, `REDIS_PASSWORD` | prod | locally `REDIS_PORT` also overrides the host port compose publishes |
| `CORS_ALLOWED_ORIGINS` | prod | comma-separated dashboard origins; `*` is rejected at startup |
| `REDIS_SSL_ENABLED` | prod (optional) | defaults to `true` |
| `POSTGRES_PORT` | local compose only | host port override for Postgres; compose binds to `127.0.0.1` only |

Added by later plans: `JWT_*`, `OFFLINE_GRACE_DAYS`, `FIELD_ENCRYPTION_KEY`, `S3_*`, `FCM_CREDENTIALS_PATH`, `SMTP_*`, `SMS_*`. See `sev_connect_backend/.env.example`.

The `prod` profile has no defaults: a missing variable aborts startup, and a set-but-empty `DATABASE_URL`, `DATABASE_USERNAME`, `DATABASE_PASSWORD`, `REDIS_HOST` or `REDIS_PASSWORD` is rejected too (`RequiredSecretsProperties`). In prod `DATABASE_URL` must use TLS (`sslmode=verify-full`, or at least `require`), and Redis uses TLS unless `REDIS_SSL_ENABLED=false`.

## Container image

`sev_connect_backend/Dockerfile`: two stages (`eclipse-temurin:25-jdk-alpine` build, `25-jre-alpine` runtime), non-root user, `SPRING_PROFILES_ACTIVE=prod`, no secrets baked in.

## Mobile client (`serv_connect_mobile/` — M0 foundation, 2026-10-18)

Flutter Clean Architecture + `BaseCubit<T, A, NE>` + `ApiResult<T>` / `Resources<T>` / sealed `Errors` + AES-256 encrypted `HiveStorage` (`HiveAesCipher` key in `SecureStorage`) + `Dio`/`Retrofit` (`AcceptLanguageInterceptor`, `AuthInterceptor`, serialized `RefreshInterceptor` with `FR-1.3` offline grace window, PII-safe `LoggingInterceptor`) + `auto_route` (`AuthGuard`, `ScopeGuard`) + `easy_localization` (`en`/`ar` + RTL) + native `dev`/`staging`/`prod` flavors + warm editorial design system (`AppColors`, `AppTypography`) and 17 `Serve*` shared UI components (`docs/07`–`docs/10`).

| Variable (`.env.example`) | Required in | Notes |
| --- | --- | --- |
| `API_BASE_URL` | all flavors | Backend base URL (`https://` enforced in `staging`/`prod`) |
| `ENV_NAME` | all flavors | `dev` \| `staging` \| `prod` |
| `DEFAULT_OFFLINE_GRACE_DAYS` | all flavors | Offline session grace window in days (`FR-1.3`, default `14`) |
| `MEDIA_CACHE_MAX_MB` | all flavors | Max LRU media cache size in MB (`NFR-12`, default `250`) |
| `SYNC_BATCH_SIZE` | all flavors | Outbox batch size (`POST /api/v1/sync/mutations`, default `50`) |
| `SENTRY_DSN` | optional | Crash reporting DSN (PII-scrubbed) |

## Web dashboard (`serv_connect_dashboard/` — D0 foundation, 2026-10-18)

React 19 + TypeScript 6 (`strict`) + Vite 8 + `oxlint` + Clean Architecture (`use<Screen>Controller` + discriminated union `Action`s + `assertNever`) + `ApiResult<T>` / `Resources<T>` / `AppError` + in-memory `AuthSession` + wall-clock `IdleLockWatcher` + `HttpClient` (`AcceptLanguageInterceptor`, `AuthInterceptor`, `RefreshMutexInterceptor`) + `react-i18next` (`en`/`ar` + RTL logical CSS + typed `locale_keys.g.ts`) + unified warm editorial `tokens.css` + 20 `Serve*` shared UI components + `AppShell` (`docs/08-dashboard-architecture.md`).

| Variable (`.env.example`) | Required in | Notes |
| --- | --- | --- |
| `VITE_API_BASE_URL` | all modes | Backend base URL (`https://` enforced in `staging`/`prod`) |
| `VITE_ENV_NAME` | all modes | `dev` \| `staging` \| `prod` |
| `VITE_DEFAULT_LOCALE` | all modes | `en` \| `ar` |
| `VITE_IDLE_TIMEOUT_MINUTES` | all modes | Inactivity timeout before session lock & cache wipe (default `15`) |

## BRD coverage

| BRD module | Status |
| --- | --- |
| 8.1 Authentication, Onboarding & Identity | client session/guard/grace-window groundwork ready (`AuthSession`, `IdleLockWatcher`, `PermissionChecker`); login endpoints & screens next |
| 8.2 Member Directory & Records | not started (`ServeMemberAvatar` photo-consent gate ready) |
| 8.3 Groups & Assignments | not started |
| 8.4 Scheduling & Events | not started |
| 8.5 Attendance & Follow-up | not started |
| 8.6 Task Management | not started |
| 8.7 Communication & Collaboration | not started |
| 8.8 Curriculum & Lesson Management | not started |
| 8.9 Content Library | not started |
| 8.10 Memorization & Points | not started |
| 8.11 Trips, Conferences & Logistics | not started |
| 8.12 Notifications & Reminders | not started |
| 8.13 Safeguarding, Privacy & Audit | groundwork ready: audit columns, `PermissionChecker`/`ScopeGuard`, AES-256 `HiveStorage` with isolated `sensitive_records`, `ServeMemberAvatar` photo-consent gate, PII-redacting `AppLogger` |
| 8.14 Analytics & Reporting | not started |
| 8.15 Prayer & Praise Board | not started |
| 8.16 Administration & Configuration | groundwork ready: `FeatureFlagService` & `OrgLabelResolver` (`FR-16.2`, `FR-16.5`) |
| §11 Data & Sync | groundwork ready (`SyncableEntity`, `sync_change_seq`, encrypted `HiveStorage`, `ServeSyncBanner`, `ServeOfflineBanner`) |
| §10.3 Backend infrastructure | foundation done: profiles, envelope, errors, i18n, security skeleton, caching, logging, image |
| §10.1 / §10.2 Mobile & Dashboard foundations | M0 & D0 done: Clean Architecture spines, design system tokens (`designs/main.main.svg`), `Serve*` UI catalogues, EN/AR + RTL, flavors, test harnesses |
