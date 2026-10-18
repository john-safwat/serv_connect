# ServeConnect — Spring Boot (Kotlin) Backend — Claude Development Rules

> **Claude must read and follow every rule in this file before starting _any_ task.**
> These rules are non-negotiable and apply to **every kind of work** — a new feature, a bug fix, a refactor, a chore, a one-line hot-fix, a spike, or a question whose answer leads to a code change. "It's only a small change" is never grounds to skip a rule.
>
> A task does not end with the code compiling or the endpoint responding `200`. **A task ends only when the relevant `docs/*.md` files have been updated** to reflect the change (see §23 — Post-Task Documentation Updates). Any change that alters behaviour without touching the matching docs is incomplete.
>
> Scope: the **ServeConnect** backend in `sev_connect_backend/` of the ServeConnect monorepo (group `com.john`, project `sev_connect_backend`, **Kotlin 2.3 on a Java 25 toolchain, Gradle 9.8 (Groovy DSL), Spring Boot 4.1.1**). It is the server-side source of truth for the ServeConnect **offline-first** mobile app (sibling project `serv_connect_mobile/`) used by churches to connect **servants** with the **served** (members, children, youth, families). It serves clients over a versioned REST API plus dedicated sync endpoints. Because the system holds data about **minors**, every member-identifying field is treated as **PII** and every pastoral/medical/consent field as **Sensitive** by default (see §11 — Security, Safeguarding & PII Handling).
>
> **Monorepo layout.** Documentation is **global to the monorepo**, not per project:
>
> ```
> Serv-Connect/                  # monorepo root
> ├── docs/                      # shared docs — BRD, API contract, sync protocol, security, walkthroughs
> ├── sev_connect_backend/       # this project
> └── serv_connect_mobile/       # mobile client
> ```
>
> Every `docs/...` path in this file means the **monorepo-root** `docs/` (i.e. `../docs/` from this project). Never create a `docs/` folder inside `sev_connect_backend/`. Backend tasks never edit files under `serv_connect_mobile/`; if a backend change requires a client change (API contract, sync payload), say so in the plan and walkthrough instead.
>
> **Business source of truth.** The Business Requirements Document — `docs/00-brd.md` — defines the modules, roles, phases, and functional requirements (`FR-x.y`). Every plan, commit, and walkthrough cites the `FR-x.y` IDs it implements. If a request contradicts the BRD, flag it before building.
>
> **Current state.** This is a **bare Spring Initializr skeleton**: only `SevConnectBackendApplication.kt`, an empty `application.properties`, and `spring-boot-starter` exist. **Nothing in `common/`, no configuration, no security, no `docs/` yet.** The first approved tasks build the foundation (§21 — Build Order). Do not assume any class, package, or doc mentioned in this file exists — grep first (§0). Where this file describes something not yet built, it is the **target design** the foundation must implement.
>
> **Companion skill:** this project follows the `spring-backend` skill for structure and conventions. That skill's `assets/` templates are **Java** — translate them to idiomatic Kotlin per §20 rather than pasting Java. Where this file and the skill ever disagree, **this file wins for ServeConnect.** A previous Java implementation exists at `../../Code/serveconnectbackend`; it may be consulted for ideas, but nothing is copied from it without stating so in the plan.

---

## 0. Pre-Task Checklist

Before writing a single line of code, Claude must:

1. Read this file in full.
2. Identify the **BRD module and `FR-x.y` IDs** the task touches, and their **phase tag** (`[MVP]`, `[P2]`, `[P3]`). Do not build a `[P2]`/`[P3]` requirement unless the user explicitly asked for it (§2.1).
3. **Create a written plan** for the task — listing every class that will be created or modified, the package it lives in, the approach, the permission keys and scopes involved, the sync/conflict strategy for any new syncable entity (§12), and any decisions made — and **wait for explicit approval** before proceeding. No code is written until the plan is approved.
4. **Check `docs/03-api-reference.md`** to confirm the endpoint being changed doesn't already exist under a different name or path. Never define two endpoints that do the same thing.
5. **Check the feature package** for the concern (`src/main/kotlin/com/john/sev_connect_backend/features/<feature>/`) before adding a new entity, DTO, service, or repository. Extend or reuse what's there rather than duplicating it.
6. Grep the codebase for existing entities, repositories, mappers, and utility classes that already cover the requirement. If something exists, extend or parameterise it rather than reinventing it; justify any new implementation in the walkthrough.
7. State the plan and wait for approval on any destructive or irreversible action (dropping/altering a shared table, editing a committed Flyway migration, purging tombstones, force-push, deleting generated files, etc.).

---

## 1. Project Structure & Package Organization

The codebase is organised **by feature (vertical slice)**, not by technical layer. Every business concern lives under `com.john.sev_connect_backend.features.<feature>`, each split internally into per-layer subpackages; `common/` holds cross-cutting code, and the base package itself carries only the application entry point and a root health controller:

```
src/main/kotlin/com/john/sev_connect_backend/
├── SevConnectBackendApplication.kt   # @SpringBootApplication entry point — no business logic here
├── HomeController.kt                 # root landing/health endpoint only — not a feature, stays out of features/
├── common/                           # Cross-cutting code shared by every feature
│   ├── audit/                        # AuditorAwareImpl — resolves createdBy/updatedBy
│   ├── base/                         # BaseEntity, SyncableEntity — shared audit + sync columns
│   ├── config/                       # @Configuration classes (SecurityConfig, CacheConfig, LocalizationConfig, JwtProperties...)
│   ├── exception/                    # Custom exception classes (EntityNotFoundException, InvalidCredentialsException...)
│   ├── exception_handler/            # The global @RestControllerAdvice (GlobalExceptionHandler)
│   ├── featureflag/                  # @RequireFeature + FeatureFlagService (per-deployment module toggles, FR-16.5)
│   ├── i18n/                         # MessageKeys, SupportedLocales
│   ├── response/                     # Shared response envelope (BaseResponseBody, FieldError)
│   ├── security/                     # JWTService, JWTAuthFilter, ScopePermissionEvaluator, SecurityConstants, Rest*Handler
│   ├── tenant/                       # TenantContext + TenantContextFilter (org_id of the caller)
│   └── validation/                   # Custom Bean Validation constraints (SecurePassword, PhoneNumber...)
└── features/
    └── <feature>/                    # one package per business concern; added as features are built
        ├── controller/               # XController
        ├── dto/                      # request/response data classes
        ├── entity/                   # X (@Entity)
        ├── mapper/                   # XMappers.kt — extension functions Entity ↔ DTO
        ├── repository/               # XRepository : JpaRepository
        └── service/                  # XService (interface) + XServiceImpl, or a concrete XService
```

### 1.1 Planned feature packages (BRD module → package)

Use these exact package names when a module is built — do not invent synonyms:

| BRD module | Package | Earliest phase |
|---|---|---|
| 8.1 Authentication, Onboarding & Identity | `identity` | MVP |
| 8.2 Member Directory & Records | `members` | MVP |
| 8.3 Groups & Assignments | `groups` | MVP |
| 8.4 Scheduling & Events | `schedule` | MVP |
| 8.5 Attendance & Follow-up | `attendance` | MVP |
| 8.6 Task Management | `tasks` | MVP |
| 8.7 Communication & Collaboration | `communication` | MVP→P2 |
| 8.8 Curriculum & Lesson Management | `curriculum` | P2 |
| 8.9 Content Library | `content` | MVP→P2 |
| 8.10 Memorization & Points | `engagement` | P2 |
| 8.11 Trips, Conferences & Logistics | `trips` | P2 |
| 8.12 Notifications & Reminders | `notifications` | MVP |
| 8.13 Safeguarding, Privacy & Audit | `safeguarding` + `audit` | MVP→P2 |
| 8.14 Analytics & Reporting | `analytics` | P2→P3 |
| 8.15 Prayer & Praise Board | `prayer` | P2 |
| 8.16 Administration & Configuration | `admin` (org profile, stages, content-pack selection, feature flags) | MVP |
| §11 Data & Sync Strategy | `sync` | MVP |

Rules:

- Every feature package lives under `com.john.sev_connect_backend.features.<feature>` — do **not** add a new feature directly under the base package.
- The base package is `com.john.sev_connect_backend` (as generated). Do not rename it as a drive-by; a rename is its own approved refactor.
- Within a feature package, split by technical layer into subpackages: `controller/`, `dto/`, `entity/`, `mapper/`, `repository/`, `service/`. Only create the subpackages a feature actually needs; don't add an empty package purely for symmetry.
- **Admin-only actions on a domain concept live inside the feature they act on**, guarded by a permission (§11) — the `admin` package only owns deployment-level configuration (organization profile, stage structure, content-pack selection, feature flags, notification defaults). It is never a god-package for "everything an admin can do."
- This per-feature layering is **not** a root-level god-package: do **not** create `com.john.sev_connect_backend.controller`, `.service`, `.repository`, or `.entity` packages that span every feature.
- A feature package may depend on `common/` freely. A feature package may depend on another feature package **only** through its public interface (service interface + DTOs) — never reach into another feature's `repository/` or `entity/` package directly. (Cross-feature JPA associations are by **ID**, not by `@ManyToOne` to another feature's entity.)
- `common/` may never import from a feature package. If two features need to share domain logic, either it belongs in `common/` or one feature genuinely owns it and the other consumes it through a service interface.
- Kotlin `internal` is the default for anything not meant to be used outside the feature; `private` for file/class-local helpers. Only make a declaration public when a real cross-package caller exists.

### 1.2 Domain vocabulary & business rules

Code uses the BRD glossary (BRD §16) so business and code speak the same language. **UI labels are configurable per church; code names are not.**

| Concept | Code name | Notes |
|---|---|---|
| Base profile of any person | `Person` | Specialised by role links, not by inheritance per role |
| Volunteer / teacher / mentor | `Servant` | |
| Recipient of the service | `ServedMember` | May be a minor → safeguarding rules apply |
| Parent / guardian link, siblings | `FamilyLink` | FR-2.3 |
| Stage / grade tier | `Stage` | Ordered; promotion moves N → N+1 |
| Group (grade, choir, team) | `Group` + `GroupType` | |
| Servant ↔ Group | `GroupAssignment` (with `isLead`) | End-dated, never deleted |
| ServedMember ↔ Group | `GroupMembership` | End-dated, never deleted |
| Recurring meeting | `Event` (recurrence rule) → `EventOccurrence` | FR-4.1/4.2 |
| Presence record | `AttendanceRecord` (occurrence × member, status `PRESENT/ABSENT/EXCUSED`) | Merge, never overwrite |
| Absentee contact | `FollowUp` | Append-only |
| Private pastoral note | `PastoralNote` | Append-only, Sensitive, audited |
| Work item | `Task` (type `FOLLOW_UP/LESSON_PREP/LOGISTICS/GENERAL`) | |
| Versioned content bundle | `ContentPack` → `ContentItem` | |
| Sensitive-access record | `AuditEntry` | Append-only |
| Role held by a user in a scope | `RoleAssignment` (role, scopeType, scopeId) | |

Business rules that apply everywhere:

- **Denomination-neutral.** No tradition-specific content (readings, prayers, feasts, hymns, saints, calendar dates) is ever hard-coded. It is data in a `ContentPack` loaded by the administrator (BRD §8.9). The same applies to labels like "Servant" or "Sunday School."
- **Record portability (FR-2.4).** Moving a member between groups/stages or changing a servant never loses history; the previous servant loses *write* scope, the record itself is unchanged.
- **Annual promotion (FR-3.4)** is a single, transactional, audited, **reversible** operation recorded as a `PromotionRun` that holds enough to undo it.
- **Absence → follow-up (FR-5.2/5.4/6.3).** Absentee computation, follow-up task creation, and absence alerts are server-side, triggered when attendance for an occurrence is (re)synced — idempotently, so re-syncing the same attendance never creates duplicate tasks or notifications.
- **Payments are tracking only (FR-11.4).** Never store card/bank details or integrate a payment processor; record who paid, how much, and when.
- **Consent gates (FR-11.3, FR-13.5).** A minor cannot be marked cleared-to-travel without a valid consent record; photo-consent flags are respected by every endpoint returning a member photo.
- **Multiple roles per user (FR-1.2).** A user may be Servant + Parent at once; never model "the user's role" as a single column.

---

## 2. Git Commits & Phase Discipline

- Create a commit after every completed, working unit of change.
- Commit message format:

  ```
  <type>(<scope>): <short description>

  <body — what changed and why, if non-obvious; cite FR-x.y IDs>
  ```

- Never add a `Co-Authored-By` trailer to commit messages.

- Valid types: `feat`, `fix`, `refactor`, `docs`, `chore`, `build`, `perf`, `security`, `test`.
- Scope is the feature package or infrastructure area: `identity`, `members`, `attendance`, `sync`, `security`, `db`, `config`, `ci`, …
- Never commit:
  - `application-local.yml`/`.properties`, `.env`, or any file containing real credentials, connection strings, FCM service-account JSON, or API keys.
  - `build/`, `.gradle/`, `.kotlin/`, `.idea/`, `*.iml` (already gitignored — verify before a broad `git add`).
  - Failing builds (`./gradlew clean build` must pass before committing).
  - Commented-out code blocks — delete instead.
  - A modified, already-applied Flyway migration file (see §5).
  - Real member data (names, photos, phone numbers) in seeds, fixtures, or test files — use obviously fake data.
- Never run `--no-verify`, `git push --force` on `main` / `develop` / `release/*`, or `git reset --hard` without explicit user instruction.

### 2.1 Phase discipline

- The BRD ships in phases: **MVP → P2 → P3** (BRD §13). MVP is the daily loop: **schedule → attend → follow up → assign tasks**, plus essential content, all offline-first.
- Build only what the current task's `FR` IDs require. A `[P2]`/`[P3]` field, endpoint, or table is **not** added "for later" — design so it can be added without a breaking change, and note it in the walkthrough's follow-ups.
- Everything in BRD §4.2 (Out of scope) is **not built**: public website, full accounting/donation processing, payment rails, live streaming/video, servant web client. Phase-3 multi-tenancy is an architectural option kept open (§5.2 `org_id`), not built.

---

## 3. Walkthrough History

- After every completed feature, bug fix, or significant refactor, create or update a walkthrough document.
- Location: `docs/walkthroughs/YYYY-MM-DD_backend_<short-slug>.md` (the `backend_` prefix distinguishes backend walkthroughs from mobile ones in the shared folder)
- Each walkthrough file must contain: **Date**, **Summary**, **BRD coverage** (`FR-x.y` IDs + phase, fully / partially implemented), **Files changed** (grouped by package), **API changes** (method, path, request/response, required permission + scope, and whether `docs/03-api-reference.md` was updated), **Schema changes** (migration file(s) + backward-compatibility, §5.3), **Sync impact** (new syncable entities, conflict strategy, tombstone behaviour — §12), **Security impact** (new permissions, new PII/Sensitive fields, changed scope rules, new audited reads), **Configuration** (new config keys / env vars), **Known limitations / follow-ups**.
- The walkthrough index at `docs/walkthroughs/README.md` must be updated with a one-line entry linking to the new file.

---

## 4. Secrets & Environment Configuration

- No credential, API key, or connection string is ever hardcoded in `application*.properties` or in Kotlin source. Every one of them is an environment variable, referenced with Spring's placeholder syntax: `${JWT_SECRET}`.
- Profile layout:
  - `application.properties` — profile-agnostic defaults only (`spring.application.name`, `spring.profiles.active=dev`, message basename, Flyway/JPA toggles).
  - `application-dev.properties` — local development, points at the `compose.yaml` Postgres/Redis/MinIO instances with clearly-fake local credentials (via `${VAR:default}`); Docker Compose auto-start enabled.
  - `application-prod.properties` — structure only, every value sourced from `${ENV_VAR}` placeholders with **no defaults** for secrets; `ddl-auto=validate`; Docker Compose disabled.
  - `application-local.yml`/`.properties` — gitignored, developer-specific overrides. Add to `.gitignore` in the foundation task.
  - `src/test/resources/application.properties` — hermetic test config (H2 or Testcontainers, `cache.type=simple`, Docker Compose disabled, fake JWT values, FCM/S3 stubbed).
- Activate a profile via `SPRING_PROFILES_ACTIVE`, never by editing the checked-in default profile.
- Provide a `.env.example` listing every required variable with no real values: `DATABASE`, `DATABASE_USERNAME`, `DATABASE_PASSWORD`, `DATABASE_URL`, `REDIS_HOST`, `REDIS_PORT`, `REDIS_PASSWORD`, `JWT_SECRET`, `JWT_TOKEN_EXPIRY_TIME`, `JWT_REFRESH_TOKEN_EXPIRY_TIME`, `OFFLINE_GRACE_DAYS`, `FIELD_ENCRYPTION_KEY`, `S3_ENDPOINT`, `S3_BUCKET`, `S3_ACCESS_KEY`, `S3_SECRET_KEY`, `FCM_CREDENTIALS_PATH`, `SMTP_*`, `SMS_*` (when added), `SPRING_PROFILES_ACTIVE`, plus any integration key introduced later.
- `compose.yaml` is for **local development only**. It must never contain a value that also protects staging/production data.
- If a required secret is missing at boot, the application must **fail fast** — `@ConfigurationProperties` classes are `@Validated` with `@field:NotBlank`/`@field:Positive`, so a missing `JWT_SECRET` or `FIELD_ENCRYPTION_KEY` aborts startup. Never silently fall back to an empty string or a hardcoded default for anything security-relevant.

---

## 5. Database, Entities & Migrations

### 5.1 Migrations

- Schema changes go through **Flyway** migration files under `src/main/resources/db/migration/`, named `V<version>__<description>.sql` (e.g., `V1__create_organization_table.sql`). PostgreSQL is the only target database. No migrations exist yet — the foundation introduces `V1`.
- `spring.jpa.hibernate.ddl-auto` must be `validate` (or `none`) in every profile except a developer's own local override.
- **Never edit a migration file that has already been applied in any shared environment.** Ship a new migration instead, even to fix a mistake.
- One logical schema change per migration file.
- Reference data that the app depends on (permission catalog, default roles → permissions, default feature flags) is seeded by migration, so every environment boots with the same catalog.

### 5.2 Entities

- One `@Entity` per aggregate root table, named after the domain concept (§1.2 vocabulary), placed in its feature's `entity/` package and extending the shared `BaseEntity` `@MappedSuperclass` (`createdAt`/`updatedAt`/`createdBy`/`updatedBy` via JPA auditing). Entities the mobile client caches extend `SyncableEntity` instead (§12).
- Table and column names are `snake_case`; table names are plural (`served_members`, `event_occurrences`). Avoid SQL reserved words — e.g. `Group` maps to `@Table(name = "service_groups")`, `Event` to `events`, `Task` to `tasks`.
- **Primary keys are `UUID`** — the offline client must be able to create records before the server sees them (FR-1.3, BRD §11.2). The server accepts a client-supplied UUID on create and treats a repeat as idempotent (§12.3).
- **Tenant-ready from day one** (BRD Q7): every tenant-scoped table carries a non-null `org_id`, indexed, populated from `TenantContext` in the service — never from the request body. Every repository query on such a table is filtered by `org_id`.
- Kotlin entity rules (the `kotlin-jpa` + `allOpen` plugins are required, §20):
  - An entity is a plain `class`, **never a `data class`** — generated `equals`/`hashCode`/`toString`/`copy` break Hibernate proxies, trigger N+1, and leak PII into logs.
  - Mutable columns are `var`; immutable ones `val`. Nullable Kotlin types match nullable columns exactly.
  - Override `toString()` only to print the `id`.
- Entity identity equality is based on the database `id` only, once assigned:

  ```kotlin
  override fun equals(other: Any?): Boolean {
      if (this === other) return true
      if (other !is MyEntity) return false
      return id != null && id == other.id
  }

  override fun hashCode(): Int = javaClass.hashCode()
  ```

- Bidirectional associations always designate one side `mappedBy` and provide sync helpers — never set only one side.
- Default fetch type for `@ManyToOne` / `@OneToOne` is `LAZY` unless there's a measured reason to eager-fetch. `@OneToMany` / `@ManyToMany` are always `LAZY`.
- **Sensitive fields live in their own table** (FR-13.3): medical/emergency info, pastoral follow-up notes, consent records are never columns on the general `person`/`served_member` table. See §11.2.
- **History is never destroyed** (FR-2.4 record portability): group memberships and servant assignments are end-dated (`valid_from`/`valid_to`), not deleted or overwritten; attendance, follow-ups, and notes keep a reference to the group/occurrence context in which they were made.
- Treat **Spring Data JPA** (`@Entity` + `JpaRepository`) as the persistence mechanism for domain aggregates. Do not mix a JDBC `@Table` entity and a JPA `@Entity` for the same table.

### 5.3 Zero-Downtime Migrations

- Never combine a column removal/rename with the release that stops using it. Sequence: (1) add the new column, deploy, backfill, migrate reads/writes; (2) a later release drops the old column.
- Adding a `NOT NULL` column to a populated table requires a default or a backfill step in the same or a preceding migration.
- Renaming a column is a drop + add for most tooling — treat it as the two-step process above.
- **Old mobile clients stay in the field for weeks offline.** A schema change must not break a sync payload that an older app version still sends or expects (§12.5).

### 5.4 Queries

- Prefer Spring Data derived query methods and `@Query` (JPQL). Reserve native SQL for cases JPQL genuinely cannot express (date-bucketed attendance aggregates, window functions for streaks/at-risk).
- Any list that could grow unbounded must be paginated (`Pageable` / `Page<T>`), never `List<T>` returned wholesale into a controller.
- N+1 risk: when a listing endpoint needs an association, use `@EntityGraph` or a JPQL `JOIN FETCH`, not a lazy association walked in a loop.
- Scope filtering (my group / my stage / my children) is applied **in the query**, not by loading everything and filtering in memory.

---

## 6. Layered Architecture

Every feature follows the same call chain: **Controller → Service → Repository**. No layer is skipped.

```
XController     --calls-->   XService (interface)
                                   |
                             XServiceImpl  --calls-->  XRepository
                                   |                         |
                             XMappers.kt (extensions)   X (@Entity)
```

### Rules

- **Controllers** only: bind the HTTP request (`@RequestBody`, `@PathVariable`, `@RequestParam`), validate (`@Valid`), enforce authorization (`@PreAuthorize`, `@RequireFeature`, §11), delegate to exactly one service method, and wrap the return value in a `ResponseEntity` via `BaseResponseBody`. No business logic, no repository calls, no entity manipulation.
- **Services** hold business logic and own transaction boundaries (`@Transactional`, §15). A service function receives and returns DTOs or domain types — controllers never see an `@Entity` directly. Any server-authoritative value (timestamps, `org_id`, computed state, absentee lists, points) is set in the service, never trusted from the client.
- Define a service **interface + `*Impl`** when a feature genuinely has (or will soon have) more than one implementation, or when consumed by another feature package. For a simple single-implementation CRUD feature, a concrete `@Service` class is enough — don't add an interface for ceremony.
- **Repositories** are `interface XRepository : JpaRepository<X, UUID>`. No business logic beyond derived-query names and `@Query`.
- **Mappers** convert `Entity ↔ DTO` as **Kotlin extension functions** in the feature's `mapper/XMappers.kt` (`fun Member.toResponse() = MemberResponse(...)`). No MapStruct/kapt — explicit Kotlin mapping is compile-checked and keeps PII choices visible.
- Constructor injection only — Kotlin primary constructors with `private val` dependencies. Never `@Autowired lateinit var` field injection. Where a bean needs a `@Qualifier`, put it on the constructor parameter.

---

## 7. DTOs & Mapping

- Request and response DTOs are **Kotlin `data class`es with `val` properties** — immutable.
- A DTO never carries a JPA annotation and an entity never carries a request-binding validation annotation — validation lives on the request DTO.
- Never return an `@Entity` (or a JPA-proxied collection) directly from a controller.
- A response DTO only includes fields the consumer needs. Omit internal audit columns and never expose another member's personal data to a caller who has no right to it (§11 data minimization). When two callers see different amounts of a record (e.g. servant of the group vs. stage head vs. parent), use **distinct response DTOs** (`MemberSummaryResponse`, `MemberRecordResponse`) rather than nulling fields at runtime.
- Sensitive data (§11.2) is never embedded in a general DTO — it is fetched through its own endpoint so the read can be authorized and audited separately.

---

## 8. REST API Conventions

- Base path: `/api/v1/<resource>` — the version prefix is mandatory from the first endpoint. A breaking change to a response shape is a new version, not a silent change to `v1` (offline clients lag behind releases).
- Resource naming: plural nouns, kebab-case for multi-word resources (`/api/v1/served-members`, `/api/v1/event-occurrences`). No verbs in the path — a sub-resource action like `POST /api/v1/groups/{id}/promotion` or `POST /api/v1/lessons/{id}/submission` is acceptable when the state transition isn't a plain field update; prefer `PATCH` otherwise. A `me` sub-path scopes a collection to the authenticated user (`/api/v1/me/tasks`, `/api/v1/me/schedule`, `/api/v1/me/children`).
- HTTP methods map to intent: `GET` (read, no side effects), `POST` (create, `201` + `Location`), `PUT` (full replace), `PATCH` (partial update), `DELETE` (soft-delete / tombstone, §12). `GET`/`DELETE` never take a body.
- Status codes: `200`, `201`, `400` (validation), `401` (missing/invalid auth), `403` (authenticated but lacks the permission/scope, or feature disabled), `404`, `409` (conflict — duplicate, stale `version`, schedule clash), `429` (rate limit), `500` (unhandled — never leaks a stack trace, §10). **Never return `204 No Content`** — every endpoint returns a structured `BaseResponseBody` envelope (`data = null` with a success code for void operations).
- Pagination: list endpoints accept `page`, `size`, `sort` (Spring `Pageable`) and return a `Page<T>`-shaped envelope.
- **Idempotency:** every create/mutation endpoint the mobile client can call offline accepts a client-generated UUID (the entity `id` or an `Idempotency-Key` header) and returns the original result on a retry instead of creating a duplicate (BRD §11.2).
- **API documentation:** use springdoc-openapi only once a Spring Boot 4-compatible release is on the classpath; until then `docs/03-api-reference.md` is the source of truth for the API surface. Even with springdoc, `docs/03-api-reference.md` stays the human-readable contract.
- **When adding a new endpoint**, the same change updates `docs/03-api-reference.md` with method, path, request/response shape, the **required permission + scope** (§11), the **feature flag** gating it, and the `FR-x.y` it serves.

---

## 9. Validation

- All inbound data is validated with Jakarta Bean Validation on the request DTO. In Kotlin, annotate the backing field: `@field:NotBlank`, `@field:Email`, `@field:Size(max = 100)`, `@field:Past`, `@field:Valid` for nested objects. A bare `@NotBlank` on a constructor parameter is a bug.
- Controller functions that accept a body declare `@Valid @RequestBody request: XRequest`.
- Required-but-missing JSON fields on non-null Kotlin properties fail in Jackson before Bean Validation runs; the global handler (§10) maps that deserialization error to the same `400` validation envelope with the field name — never a `500`.
- Cross-field or DB-dependent validation (uniqueness, referential state, business rules such as "no minor is cleared to travel without valid consent" FR-11.3, "attendance only for a member of the occurrence's group", schedule conflicts FR-4.4) lives in the **service layer** as the real guard and raises a typed exception (§10) — client-side checks are a convenience, never the authority.
- Custom constraint annotations live in `common/validation/` (e.g. `@SecurePassword`, `@PhoneNumber`) and are reused across features.

---

## 10. Error Handling

- All errors returned to a client flow through a single global handler (`common/exception_handler/GlobalExceptionHandler`, a `@RestControllerAdvice`) and are serialized as the uniform `BaseResponseBody.Fail` envelope. The client-facing message is generic and **localized** (via `MessageSource` keyed by `MessageKeys`, always with the English string as the default so a missing key degrades gracefully).
- Domain exceptions live in `common/exception/` (`EntityNotFoundException` → 404, `InvalidCredentialsException` → 401, `AlreadyExistsException` → 409, `StaleVersionException` → 409, `ScheduleConflictException` → 409, `FeatureDisabledException` → 403, `BusinessRuleException` → 400/409 …) and extend `RuntimeException`. Services throw these; they never return `null` to signal "not found" and never let a raw `DataIntegrityViolationException` / JPA exception escape.
- The generic catch-all handler must never expose the raw message or stack trace — log server-side (with the request path as an opaque, PII-free identifier) and return a generic, localized message.
- A repository unique-constraint violation is caught and re-thrown as a typed `*AlreadyExists`/`Duplicate*` exception → `409` — except where the conflict rule is merge/idempotent (attendance upsert, repeated `mutationId`, §12), which returns the existing result instead of an error.
- Jackson deserialization errors (malformed JSON, missing non-null Kotlin fields, unknown enum values) map to `400` with the offending field name.
- Filter-level `401`/`403` (thrown before a controller runs) are routed through `RestAuthenticationEntryPoint` / `RestAccessDeniedHandler` into the same handler, so they use the same envelope.
- A `403` for an out-of-scope record and a `404` for a missing one must not let a caller enumerate records they cannot see: when the caller has no scope over the target type at all, prefer `404`.
- Inside a sync push batch, exceptions are converted into the per-item result (`REJECTED`/`CONFLICT`, §12.2), never a failed batch.

---

## 11. Security, Safeguarding & PII Handling

**Authorization model.** ServeConnect enforces **permission-based, scope-aware authorization** project-wide (BRD §6). Roles are **data** — a role is a named bundle of permissions, assigned to a user in a scope (`ORG`, `STAGE`, `GROUP`, `SELF`, `CHILDREN`) — so a church can tune them without a code change. **Never use `hasRole(...)` or branch on a role name in code.**

- Coarse checks: `@PreAuthorize("hasAuthority('attendance.record')")`.
- Resource-scoped checks: `@PreAuthorize("hasPermission(#groupId, 'group', 'attendance.record')")`, evaluated by `ScopePermissionEvaluator`, which resolves whether the caller holds the permission in a scope that contains the target (the group itself, its stage, or the org).
- Module gating: every controller (or endpoint) carries `@RequireFeature("<module>")` so a disabled module returns `403` (FR-16.5).
- Permission keys are `<feature>.<action>[.<qualifier>]` (`members.read.full`, `members.notes.read`, `groups.assign-servants`, `lessons.approve`, `audit.read`). The full catalog, default role → permission mapping (from BRD §6.2), and scope semantics are documented in `docs/04-security.md` and seeded by migration (§5.1).

### 11.1 General rules

- **Default deny.** Endpoints are authenticated by default via the `SecurityFilterChain` bean — public only when explicitly listed in `SecurityConstants.publicApis()` (`/`, `/actuator/health`, `/api/v1/auth/**`). `@EnableMethodSecurity` is on so `@PreAuthorize`/`@PostAuthorize` are enforced. Authorization is always re-checked server-side per request, never inferred from client state (NFR-4: client checks are UX only).
- **Authentication (FR-1.1).** Phone number or email + password; OTP verification for phone. Stateless JWT. Passwords hashed with `BCryptPasswordEncoder` — never plaintext, never `==`. A `@SecurePassword` constraint enforces max 72 bytes → complexity → a HaveIBeenPwned compromise check (k-anonymity, **fail-open** on outage). OTPs are short-lived, single-use, stored hashed, and rate-limited.
- **Provisioning (FR-1.4).** Accounts are created by admin invitation (link/code). Self-registration is off by default and, when enabled by config, lands in a pending-approval state.
- **Offline grace window (FR-1.3).** Refresh tokens live for the configurable grace window (`OFFLINE_GRACE_DAYS`, 14–30 days) so a servant offline mid-meeting is never locked out; access tokens stay short. Refresh tokens are stored as **SHA-256 hashes** with rotation + reuse detection; "invalid," "expired," and "already revoked" all collapse to one `InvalidCredentialsException`, as does a failed login (never reveal whether the identifier or the password was wrong).
- **JWT plumbing** (`common/security/`): `JwtProperties` (env-sourced, fail-fast) → `JWTService` (issues access tokens carrying `id/org_id/authorities`, refresh tokens with a random `jti`; verifies) → `JWTAuthFilter` (`OncePerRequestFilter` before `UsernamePasswordAuthenticationFilter`) → `TenantContextFilter` (populates `TenantContext`). **No name/email/phone in the JWT** — tokens are cached on devices.
- **CORS** configured explicitly (allowed origins, methods, headers) in a `@Configuration` class — never `@CrossOrigin("*")`.
- **CSRF** disabled only for the stateless bearer-token API; re-evaluate if cookie-based sessions are ever added (e.g. a P3 web console).

### 11.2 Data classification

| Class | Examples | Rules |
|---|---|---|
| **PII** | name, photo, birthdate, phone, email, address, family links | Scope-checked on read; never logged; never in URLs or push payloads |
| **Sensitive** | medical & emergency info, pastoral/follow-up notes (FR-2.5), consent forms, safeguarding incidents | Everything for PII **plus**: separate table + separate permission + separate endpoint; encrypted at the column level (JPA `AttributeConverter`, key from `FIELD_ENCRYPTION_KEY`); **every read and write produces an `AuditEntry`** |
| **Operational** | schedules, tasks, attendance status, content | Scope-checked; normal logging of IDs only |

### 11.3 Safeguarding rules (FR-13.x)

- **Scope-based access to minors (FR-13.1).** A servant sees full records only for members of groups they are currently assigned to; a stage head for their stage; a parent only their linked children; a served member only themself. Losing an assignment removes access immediately — including from the sync feed (§12.4).
- **Audit log (FR-13.2).** Each `AuditEntry` records actor, action (`VIEW`, `CREATE`, `UPDATE`, `EXPORT`, …), target type + ID, scope used, and `Instant` — **never the sensitive value itself**. The audit table is append-only (no update/delete endpoints, no `@Modifying` update queries) and readable only with `audit.read`.
- **Data minimization (FR-13.3).** Listing/admin endpoints expose only what the action needs — never another member's full personal record. Analytics (FR-14.x) return aggregates, not raw sensitive rows.
- **Data subject requests (FR-13.6, P2).** Export and deletion are workflows that are themselves audited; deletion of a person anonymises/purges PII while keeping aggregate attendance counts consistent.

### 11.4 Logging, URLs, transport

- **No PII in logs.** Never log a raw request/response body, a full entity, a DTO's `toString()`, or any name/email/phone/contact/medical/note field — at any level, including `debug`. Log identifiers (`userId`, `memberId`) instead of the person; the global handler logs only the request path + exception.
- **No PII in URLs.** Never put a name, phone, email, or other personal datum in a path or query string. Use opaque UUIDs and the `me` scope.
- **Audit trail.** Every write is attributable via `createdBy`/`updatedBy` (`AuditorAwareImpl` resolves the authenticated user's UUID from `TenantContext`/`SecurityContextHolder`, falling back to the system UUID `00000000-0000-0000-0000-000000000000` for jobs).
- **Transport.** The production profile enforces TLS in transit (LB termination with `server.forward-headers-strategy=framework`). Never disable certificate validation to work around a local issue.
- **Media** (photos, hymn audio, lesson PDFs) live in S3-compatible object storage, never in the database. The DB stores key, content type, size, checksum. Clients get **short-lived pre-signed URLs** issued only after the scope check; member photos honour photo consent.
- JWT/other secrets follow §4 — env vars only, never hardcoded or committed.

---

## 12. Offline-First Sync

Offline-first is mandatory (BRD §11, NFR-1/NFR-3). The server is the source of truth; the mobile app holds an eventually-synced replica plus an outbox of queued mutations.

### 12.1 Syncable entities

- Every entity the client caches extends `SyncableEntity` (`common/base/`), which adds: `id: UUID` (client-suppliable), `orgId`, `version: Long` (`@Version`, optimistic locking), `changeSeq: Long` (server-assigned, monotonic, from a Postgres sequence on every insert/update/delete), and `deletedAt: Instant?` (tombstone).
- **Deletes are soft.** A delete on a syncable entity sets `deletedAt` and bumps `changeSeq` so clients receive a tombstone. Hard purging is only done by an approved retention/DSR job (§0 step 7).
- Repositories exclude tombstoned rows from normal reads by default.

### 12.2 Sync endpoints (`features/sync`)

- **Pull:** `GET /api/v1/sync/changes?since=<token>&entities=<list>&limit=<n>` returns upserts + tombstones with `changeSeq > token`, a `nextToken`, and `hasMore`. The token is the server `changeSeq`, **never a client or wall-clock timestamp**.
- **Push:** `POST /api/v1/sync/mutations` accepts a batch of mutations, each with a client `mutationId`, entity type, op, entity `id`, base `version`, and payload. The response returns a **per-item result** (`APPLIED`, `DUPLICATE`, `MERGED`, `CONFLICT` with the server copy, `REJECTED` with a reason) — one bad item never fails the whole batch.
- Processed `mutationId`s are stored so a retry is answered with the original result (idempotency).
- Each pushed mutation goes through the **same service method and the same permission/scope check** as the equivalent REST endpoint. The sync layer is transport, not a back door.

### 12.3 Conflict resolution — per data type (BRD §11.3)

Every new syncable entity declares its strategy in the plan and in `docs/06-sync.md`:

| Data type | Strategy |
|---|---|
| Schedules, curriculum, groups, config | Server-authoritative last-write-wins on `version`; a stale write returns `CONFLICT` with the server copy so the client can warn the editor |
| **Attendance** | **Merge per (occurrence, member)** — unique key, upsert; concurrent marks from two servants never overwrite each other blindly |
| **Follow-ups & pastoral notes** | **Append-only** — no update/delete; a correction is a new entry referencing the old one |
| Tasks | Field-level merge; status transitions reconciled by a deterministic rule documented with the entity |
| Personal state (reading progress, favourites, notification prefs, points) | Per-user last-write-wins |

### 12.4 Scope in the feed

- The pull feed is filtered by the caller's current scopes with the same `ScopePermissionEvaluator` rules as REST reads. It must never return a row the caller could not `GET`.
- When a caller loses scope over a record (member moved group, assignment ended), the feed sends a **revocation** for it so the device drops its cached copy.
- Sensitive data (§11.2) is only included in the feed for callers holding the specific permission, and those reads are audited.

### 12.5 Compatibility

- Sync payloads are versioned with the API. Adding optional fields is fine; removing/renaming a field or changing its meaning requires a new payload version while old clients remain supported.

---

## 13. Logging

- SLF4J via a Kotlin logger per class: `private val log = LoggerFactory.getLogger(javaClass)` (or in a `companion object`). Never `println`.
- Log to console **and** a rolling file appender (`logback-spring.xml` → `logs/serveconnect.log`, 20MB/file, 30-day/1GB retention; add `logs/` to `.gitignore`).
- Levels: `error` for unhandled/unexpected failures (always with the exception object last so the stack trace is captured), `warn` for handled-but-notable conditions (a validation rejection, a failed auth attempt, a sync conflict, a cache/FCM fallback), `info` for significant business events (promotion run, sync batch summary counts), `debug` for diagnostics — never `debug`-level PII either.
- Parameterized logging only: `log.info("Attendance synced for occurrence {} by user {}", occurrenceId, userId)` — never string templates (`"$x"`) or concatenation in log calls.
- The log pattern includes an `%X{correlationId}` MDC slot (default `-`); populate it with a correlation-id filter. Sync requests also log batch size and result counts (NFR-11 observability).

---

## 14. Timestamps, Timezones & Recurrence

- Persist every absolute instant as `Instant` (UTC) at the entity level — never `LocalDateTime` for `createdAt`, `updatedAt`, attendance time, or any event time. Server-authoritative instants are authored server-side; the client device clock is never trusted for ordering (use `changeSeq`, §12).
- Client-reported times (e.g. "attendance taken at" while offline) may be stored as an additional `clientRecordedAt` field for display only.
- `LocalDate` / `LocalTime` are used only for genuine date/time-of-day concepts (birthdate, "every Friday at 18:00").
- **Recurring events (FR-4.1/4.2)** store the recurrence rule as local wall-clock time plus the organization's IANA `ZoneId` — never as a UTC time — so DST changes don't shift meetings. Occurrences are materialised with a concrete `Instant`; editing "this occurrence" vs. "the whole series" is modelled explicitly.
- Column type is `timestamptz` (Postgres) for instants so timezone info is never silently dropped.
- Never format a timestamp for display on the backend — return the raw ISO-8601 `Instant` or `LocalDate` string in the DTO; the client renders local time and localized calendars (NFR-6).

---

## 15. Configuration & Bean Conventions

- One `@Configuration` class per concern (`SecurityConfig`, `CacheConfig`, `LocalizationConfig`, `StorageConfig`, `PushConfig`, …) under `common/config/`.
- Typed configuration: group related properties behind `@ConfigurationProperties` **data classes** (e.g. `JwtProperties`, `SyncProperties`, `StorageProperties`) rather than scattered `@Value("\${...}")`. Register them with `@ConfigurationPropertiesScan` on the application class.
- `@Bean` functions receive dependencies as parameters; no static/`ApplicationContext.getBean(...)` lookups.
- Prefer Spring Boot auto-configuration over hand-rolled setup where a starter already covers the need.
- Deployment-level business settings (enabled modules, offline grace days, follow-up thresholds, notification defaults, labels) are **admin-editable data** (FR-16.x), not properties — properties are for infrastructure.

---

## 16. Transactions & Side Effects

- `@Transactional` on **service** functions only, never controllers or repositories.
- Read-only service functions use `@Transactional(readOnly = true)`.
- Keep transactions short: no outbound HTTP (FCM, S3, SMS, HIBP), no file I/O, no long computation inside a `@Transactional` function — persisting and dispatching a side effect are **separate** steps. Publish a domain event and handle it with `@TransactionalEventListener(phase = AFTER_COMMIT)` (or a persisted outbox for anything that must not be lost).
- Kotlin exceptions are unchecked, so Spring rolls back on any thrown exception by default — never catch-and-swallow inside a `@Transactional` function in a way that defeats the rollback.
- A sync push batch processes each mutation in **its own transaction** so one failure doesn't roll back the others (§12.2).

---

## 17. Performance, Caching & Notifications

- Caching uses **Redis** via the Spring Cache abstraction with a **fail-open `CacheErrorHandler`** (`CacheConfig` — a Redis outage degrades to a DB read, never a request failure). Named cache regions with explicit TTLs (e.g. `CACHE_REFERENCE_DATA` 60m for permission catalog/stages, `CACHE_CONTENT_PACK` long-lived per pack version, `CACHE_DAILY_VERSE` until midnight org time). Tests fall back to an in-memory cache (`spring.cache.type=simple`).
- **Boot 4 uses Jackson 3** (`tools.jackson.*`): use the Jackson 3 Redis serializer (`GenericJacksonJsonRedisSerializer`) and register the Jackson 3 Kotlin module so data classes (de)serialize correctly.
- Add `@Cacheable` only for read-heavy, rarely-changing lookups (content packs, permission catalog, org config) and **pair every `@CacheEvict`/`@CachePut` with the mutation that invalidates it.** Never cache member records, scoped lists, or anything containing PII/Sensitive data.
- Content packs and media are served with HTTP caching headers / ETags keyed on pack version so the client downloads once on Wi-Fi (NFR-12).
- List endpoints are paginated by default (§8). Watch N+1 (§5.4); index every `WHERE`/`JOIN`/`ORDER BY` column — including `org_id`, `change_seq`, and scope columns — in the same migration that introduces the query pattern.
- **Push notifications (FR-12.1)** go through FCM/APNs after commit (§16). Payloads carry IDs + a localized generic message — **no minor's name, no note content, no medical data** (they appear on lock screens). Notification preferences and quiet hours (FR-12.3) are honoured server-side before sending. Reminders for meetings are computed on-device (FR-12.2); the server only pushes changes.

---

## 18. Localization (i18n)

- User-facing messages, validation text, notification text, and email content are resolved from `MessageSource` bundles (`src/main/resources/i18n/messages*.properties`), keyed by constants in `common/i18n/MessageKeys` — never hardcode a user-facing string in a service or controller.
- The active locale is resolved from the `Accept-Language` header via an `AcceptHeaderLocaleResolver` restricted to `common/i18n/SupportedLocales` (English default + Arabic); an unsupported locale falls back to the default. Message-bundle lookup stays with Boot's auto-configuration (`spring.messages.basename=i18n/messages`) — don't hand-roll a `MessageSource` bean.
- Push notifications are localized to the **recipient's** stored language, not the sender's request locale.
- Error envelopes (§10) carry a localized message resolved through the same `MessageSource`, always with the English string as the default so a missing key degrades gracefully.
- Standard Jakarta constraint messages are overridden app-wide in both bundles; keep the two bundles' keys in sync. Any HTML email templates are localized with **RTL support** for Arabic (NFR-6).
- Content packs are per language (BRD §8.9); content text is data, not message-bundle entries.

---

## 19. Dead Code & Module Boundary Enforcement

- Remove unused imports, private functions, and classes on sight — do not comment them out. Git preserves history.
- No feature imports another feature's `Repository`/`@Entity`/`internal` declaration directly (§1). `common/` never imports a feature.
- Before adding a Gradle dependency, check whether a Spring Boot starter already covers the need; let the Spring dependency-management plugin manage versions (no hardcoded versions for Boot-managed artifacts).
- Every change builds clean: `./gradlew clean build` with no new compiler warnings.

---

## 20. Code Style, Kotlin Idioms & Build

- Kotlin official code style: 4-space indent, one top-level class per file (mapper extension files excepted), no wildcard imports, trailing commas allowed. Add ktlint (via Spotless or the ktlint Gradle plugin) in the foundation task and run `./gradlew ktlintFormat`/`spotlessApply` before commit once it exists.
- **Null safety:** never use `!!` in production code — use `?: throw EntityNotFoundException(...)`, `requireNotNull`, or a safe call. `lateinit` only for test fixtures.
- Prefer `val` over `var`, expression bodies for one-liners, `when` over `if` chains on enums/sealed types. Model closed sets of states (attendance status, task status, lesson status, sync result) as `enum class` or `sealed` hierarchies — never strings.
- **No Lombok** — Kotlin covers it: data classes for DTOs (§7), primary-constructor injection (§6), the class logger (§13). Never `data class` for an `@Entity` (§5.2).
- Naming symmetry: `XController` ↔ `XService` ↔ `XRepository` ↔ `X`. `PascalCase` types, `camelCase` members, `UPPER_SNAKE_CASE` constants (`const val` in a `companion object` or top-level).
- **Servlet stack (Spring MVC), blocking JPA.** No WebFlux, no coroutine controllers unless a later approved decision says otherwise.
- **Required build plugins** (added in the foundation task to `build.gradle`): `org.jetbrains.kotlin.plugin.jpa` (no-arg constructors for entities) and an `allOpen` block for `jakarta.persistence.Entity`, `jakarta.persistence.MappedSuperclass`, `jakarta.persistence.Embeddable` (Hibernate lazy proxies need open classes). Keep the existing `-Xjsr305=strict` compiler flag.
- **Java 25 toolchain.** The project compiles via the Gradle Java toolchain (`languageVersion = 25`), so `./gradlew` works regardless of the JDK Gradle itself runs on. If the build reports no matching toolchain, install a JDK 25 or enable toolchain auto-provisioning — don't lower the version.
- **Tests:** JUnit 5 + `kotlin-test`, MockK (`springmockk` for `@MockkBean`) for mocks. Every service rule from §1.2 (merge, append-only, scope, idempotency, promotion reversal) gets a unit test; every endpoint gets at least one `@WebMvcTest`/integration test covering the happy path, a `403` for an out-of-scope caller, and a `400` for invalid input. Sync conflict strategies get dedicated tests (BRD R1).
- Build commands:

  ```bash
  ./gradlew bootRun          # local; dev profile auto-starts compose.yaml Postgres + Redis (+ MinIO)
  ./gradlew clean build      # compile + tests — must pass before commit
  ./gradlew bootJar          # build the jar
  ```

- **Deployment.** Two-stage `Dockerfile` (non-root runtime user, Java 25 base) pushed to a registry and redeployed over SSH by `scripts/deploy.sh`; no secret is baked into the image (§4). Managed Postgres/Redis are preferred (BRD R9).

---

## 21. Check Before Building & Build Order

### 21.1 Check before building

1. Read `docs/00-brd.md` for the module and `FR-x.y` being implemented.
2. Read `docs/01-project-overview.md` for the architecture baseline.
3. For a feature, read its section of `docs/03-api-reference.md`.
4. For schema, read `docs/02-database-schema.md` + the latest Flyway migration.
5. For auth/authorization/safeguarding, read `docs/04-security.md`.
6. For anything the mobile client caches, read `docs/06-sync.md`.
7. Grep for existing services/repositories/mappers that might already cover the problem.
8. Extend or reuse if it exists; document in the relevant `docs/*.md` why.
9. Only create new if the existing can't be extended without a breaking change; flag the trade-off in the walkthrough.

### 21.2 Recommended build order (each step is its own approved plan)

0. **Foundation** — Gradle plugins & starters (web, validation, data-jpa, security, flyway + postgresql, data-redis, cache, actuator, docker-compose, Jackson Kotlin), profiles, `compose.yaml`, `.env.example`, `common/` (envelope, exception handler, i18n, base/syncable entities, auditing, tenant context, feature flags, logging), `docs/` skeleton.
1. `identity` + permission/role/scope model + JWT/refresh/OTP + invitations (FR-1.1–1.4) and `admin` org/stage setup (FR-16.1–16.2).
2. `members` + family links (FR-2.1–2.4), `audit` basics (FR-13.1–13.3).
3. `groups` + assignments + promotion (FR-3.1–3.4).
4. `sync` engine (BRD §11) — before any further module, so every later entity is syncable from the start.
5. `schedule` (FR-4.1–4.4) → `attendance` + follow-up (FR-5.1–5.4) → `tasks` (FR-6.1–6.3).
6. `notifications` (FR-12.1–12.3), `communication` announcements (FR-7.1), `content` Bible tracking/daily verse/hymn text (FR-9.1–9.3).
7. Phase 2 modules only on explicit request.

---

## 22. Definition of Done for Safeguarding-Relevant Work

Any task touching a minor's data, a Sensitive field, a permission, or the sync feed is done only when:

- [ ] Every new read path is scope-checked server-side and has a `403` test for an out-of-scope caller.
- [ ] Every Sensitive read/write writes an `AuditEntry` (and a test asserts it).
- [ ] No new PII appears in logs, URLs, JWT claims, push payloads, or cache entries.
- [ ] The sync feed for the new data respects scope and revocation (§12.4).
- [ ] `docs/04-security.md` lists any new permission, its default roles, and its scope semantics.

---

## 23. Post-Task Documentation Updates

**Every task ends with a documentation update.** "The code compiles" is not "the task is done" — the task is done when the docs match reality.

Update, as applicable: `docs/03-api-reference.md` (endpoints + required permission/scope + feature flag), `docs/02-database-schema.md` (migrations), `docs/04-security.md` (permissions, roles, scopes, PII/Sensitive fields, audited actions), `docs/06-sync.md` (syncable entities + conflict strategy), `docs/01-project-overview.md` (feature/integration/config, BRD coverage status per module), `docs/05-localization.md` (messages/locales), `docs/README.md` (new docs), and a walkthrough (§3). If a documented rule/limitation is now true/false/changed, update it rather than letting it drift. Drive-by doc fixes are encouraged. `docs/00-brd.md` is only changed when the user changes the requirements.

Before committing:

```bash
# run from the monorepo root
git status -- docs/     # expect changes matching the task
git diff -- docs/
```

If `git status docs/` shows no changes for a task that modified code or the API surface, stop and ask whether it really needed none.

---

## Quick Reference — Mandatory Actions Per Task

| Task Type                     | Plan & Approval | FR IDs cited | Migration        | Validation | Error Handling | Security / Scope Review | Sync Review | Tests | Commit | Walkthrough | Docs Update |
| ------------------------------ | ---------------- | ------------ | ----------------- | ---------- | --------------- | ------------------------ | ----------- | ----- | ------ | ------------ | ----------- |
| New feature/endpoint           | ✅               | ✅           | If schema change  | ✅         | ✅              | ✅                        | If cached by client | ✅ | ✅ | ✅ Create | ✅ API reference + schema (if any) + security (permission) |
| New entity/table               | ✅               | ✅           | ✅                 | —          | —                | ✅ (PII/Sensitive class)  | ✅ (syncable? strategy) | ✅ | ✅ | ✅ Update | ✅ `docs/02-database-schema.md` (+ `06-sync.md`) |
| New DTO / changed response     | ✅               | ✅           | —                  | ✅         | —                | If PII-adjacent           | If in sync payload | ✅ | ✅ | ✅ Update | ✅ `docs/03-api-reference.md` |
| New permission / scope rule    | ✅               | ✅           | ✅ (seed)          | —          | —                | ✅ (§22 checklist)        | ✅ (feed filtering) | ✅ | ✅ | ✅ Update | ✅ `docs/04-security.md` |
| Sensitive data / minors        | ✅               | ✅           | If related         | ✅         | ✅              | ✅ (§22 checklist)        | ✅          | ✅ | ✅ | ✅ Update | ✅ `docs/04-security.md` |
| Bug fix                        | ✅               | If related   | If schema-related  | If related | If related       | If related                | If related  | ✅ regression | ✅ | ✅ Update | ✅ Relevant doc section — rule or gap closed |
| Refactor                       | ✅               | —            | If related         | If related | If related       | If related                | If related  | ✅ still green | ✅ | ✅ Update | ✅ Any doc whose examples/paths are now stale |
| New configuration/secret       | ✅               | If related   | —                  | —          | —                | ✅                        | —           | — | ✅ | ✅ Update | ✅ `docs/01-project-overview.md` §config + `.env.example` |
| Question that led to a change  | ✅               | If related   | If related         | If related | If related       | If related                | If related  | If related | ✅ | ✅ Update | ✅ Whichever doc was wrong/incomplete |
