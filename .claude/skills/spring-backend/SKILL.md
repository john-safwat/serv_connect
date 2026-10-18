---
name: spring-backend
description: >-
  Scaffold and build a Spring Boot backend the same way the "Elevate Health Care"
  project is built — feature-sliced packages, Controller→Service→Repository layering,
  a sealed BaseResponseBody envelope, a global RFC-style exception handler, JWT +
  method security, Flyway migrations, JPA auditing, Redis fail-open caching, logback
  file logging, Accept-Language i18n, Docker/VPS deploy, and the docs/ + walkthrough
  discipline. Use this WHENEVER starting a new Spring Boot / Java backend, initializing
  a project, or adding a feature/endpoint/entity/DTO to one — AND whenever the user
  asks how to do security, auth, JWT, password policy, caching, logging, localization,
  error handling, response envelopes, database migrations, packaging, or deployment
  "the same as my other project" / "like the health care app" / "the way I usually do
  it." Trigger even if the user doesn't name this skill — any Spring Boot backend work
  should follow these conventions.
---

# Spring Boot Backend Conventions

This skill reproduces the architecture and conventions of the **Elevate Health Care**
Spring Boot backend so any new project (or new feature in an existing one) follows the
same shape. It is the portable version of that project's `CLAUDE.md` plus ready-to-copy
templates.

**Stack baseline:** Java 17 LTS · Maven · Spring Boot 4.x · Spring Data JPA · Spring
Security (stateless JWT) · Flyway · PostgreSQL · Redis · MapStruct · Lombok · Thymeleaf
email. Adapt versions to the target project, but keep the *shapes* below.

Throughout the templates, the placeholder base package is `com.example.app` and the
artifact is `app` — replace both with the real group/artifact. (The source project used
`com.elevate.health_care`; two of its packages, `respose` and `enitity`, are misspellings
kept only for backward-compat — **new projects use the correct `response` and `entity`
spelling.** Don't reproduce the typos.)

## How to use this skill

1. **Figure out which slice of work this is** — a brand-new project, or a change inside
   an existing one — then read the matching reference file(s) below before writing code.
   Each reference is self-contained and includes the "why," not just the rule.
2. **Follow the per-task workflow** (next section). It mirrors the source project's
   non-negotiable checklist: plan → build in the right layer → validate → handle errors →
   security-review → commit → update `docs/`.
3. **Copy templates from `assets/`** rather than re-deriving them. They are faithful to
   the source project (package names generalized, typos corrected).

## Reference files (read the ones relevant to the task)

| Topic | File | Read when… |
|---|---|---|
| Project init & structure | `references/initialization.md` | starting a new project, or adding a feature package |
| App architecture & layering | `references/architecture.md` | adding any controller/service/repository/DTO/mapper |
| Security, JWT & auth | `references/security.md` | anything touching auth, roles, passwords, PHI |
| Error handling & responses | `references/error-handling.md` | adding endpoints, exceptions, or the response envelope |
| Database, entities & migrations | `references/database.md` | new entity/table/column or a Flyway migration |
| Caching (Redis) | `references/caching.md` | adding a cache region or `@Cacheable`/`@CacheEvict` |
| Logging | `references/logging.md` | wiring logging, or reviewing a log line for PHI |
| Localization (i18n) | `references/localization.md` | user-facing messages, validation text, emails |
| Deployment (Docker/VPS) | `references/deployment.md` | building an image, writing the deploy script, env vars |
| Documentation discipline | `references/documentation.md` | **every task** — it isn't done until docs match |

## Templates in `assets/`

- `CLAUDE.md.template` — drop into a new project root as `CLAUDE.md`; it is the full
  ruleset the source project enforces, generalized. **Do this first on a new project.**
- `pom-dependencies.xml` — the dependency block (starters + Flyway + MapStruct + Lombok).
- `BaseResponseBody.java`, `FieldError.java` — the sealed response envelope.
- `HealthCareExceptionHandler.java` — the global `@RestControllerAdvice` (rename per project).
- `BaseEntity.java` — the `@MappedSuperclass` audit base.
- `SecurityConfig.java`, `CacheConfig.java` — config templates.
- `logback-spring.xml`, `Dockerfile`, `deploy.sh`, `.env.example` — infra templates.

## Per-task workflow (applies to every change, however small)

The source project's core rule: **a task is not done when the code compiles — it's done
when `docs/` reflects the change.** Follow this order:

1. **Plan first.** List every class you'll create/modify, its package, and the approach.
   For a non-trivial task, state the plan and get approval before writing code. For a
   destructive/irreversible action (dropping a table, editing an *applied* migration,
   force-push) always stop and confirm.
2. **Check before building.** Grep for an existing entity/service/mapper/endpoint that
   already covers the need; extend or reuse rather than duplicate. Check
   `docs/03-api-reference.md` so you don't create two endpoints that do the same thing.
3. **Build in the right layer.** Controller → Service → Repository, never skipping a
   layer; DTOs (records) cross the controller boundary, never entities. See
   `references/architecture.md`.
4. **Validate inbound data** with Jakarta Bean Validation on the request DTO; cross-field
   / DB-dependent checks live in the service and throw a typed exception.
5. **Handle errors** through the global handler and the `BaseResponseBody` envelope —
   never leak a stack trace or raw message. See `references/error-handling.md`.
6. **Security review.** Endpoints are authenticated by default; `permitAll()` is explicit.
   No PHI/PII in logs or URLs. Secrets come from `${ENV_VAR}`, never hardcoded. See
   `references/security.md`.
7. **Commit** with a conventional message (`feat(scope): …`, `fix(scope): …`, etc.) once
   `./mvnw clean verify` passes. Never commit secrets, `target/`, an applied migration
   edit, or a failing build.
8. **Update `docs/` and write a walkthrough.** This is mandatory, not optional. See
   `references/documentation.md`.

## The load-bearing conventions (quick reference)

These are the rules that make a project "look like this one." The reference files expand
each with rationale.

- **Feature-sliced packages** under `com.example.app.features.<feature>`, each split into
  `controller/ dto/ entity/ mapper/ repository/ service/`. Cross-cutting code lives in
  `common/`. A feature depends on another feature only through its service interface + DTOs.
- **Uniform response envelope** — every endpoint returns `BaseResponseBody` (a sealed
  `Success`/`Fail` hierarchy). **Never `204 No Content`**; a void success is
  `Success` with `data: null`.
- **Global exception handler** maps every exception to `BaseResponseBody.Fail` with a
  generic, localized, PHI-free message; detail is logged server-side only.
- **Stateless JWT security** with `@EnableMethodSecurity`; `@PreAuthorize` on
  controllers/services; BCrypt passwords; a `@SecurePassword` constraint with a
  HaveIBeenPwned check; refresh tokens stored as SHA-256 hashes with rotation + reuse
  detection.
- **JPA auditing** via a `BaseEntity` `@MappedSuperclass` (`createdAt/updatedAt/createdBy/
  updatedBy`); every domain entity extends it. Never `@Data` on an `@Entity`.
- **Flyway** is the schema source of truth; `ddl-auto=validate` outside a local sandbox;
  never edit an applied migration; zero-downtime column changes are two-step.
- **Redis caching** with a fail-open `CacheErrorHandler` (cache miss on Redis outage falls
  back to the DB), named cache regions with explicit TTLs, and paired `@CacheEvict` on
  every mutation.
- **i18n** from the `Accept-Language` header (`AcceptHeaderLocaleResolver` restricted to
  supported locales); messages and validation text from `MessageSource` bundles; localized
  Thymeleaf HTML emails with RTL support.
- **Logging** via SLF4J (`@Slf4j`), parameterized, to console + a rolling file appender;
  **no PHI/PII in any log line at any level.**
- **Config by env var** with profile files (`dev`/`prod`); fail-fast on missing required
  secrets; `.env.example` lists every variable.
- **Deploy** as a two-stage Docker image (non-root runtime user), pushed to a registry and
  redeployed over SSH by `scripts/deploy.sh`; no secret baked into the image.
- **Docs discipline** — `docs/01-project-overview.md` … `05-localization.md` plus dated
  `docs/walkthroughs/`, updated in the same change that alters behavior.
