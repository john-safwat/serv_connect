# Project Initialization & Structure

## Bootstrapping a new project

1. Generate a Spring Boot project (start.spring.io or `spring init`) — Java 17, Maven,
   packaging `jar`, group/artifact of your choice (source used `com.elevate` / `health_care`).
2. Add the dependencies in `assets/pom-dependencies.xml` (starters + Flyway + PostgreSQL +
   Redis + MapStruct + Lombok + Thymeleaf/mail as needed).
3. Drop `assets/CLAUDE.md.template` into the repo root as `CLAUDE.md` and adapt the domain
   name/package — it is the enforceable ruleset. Create the `docs/` skeleton
   (see `references/documentation.md`).
4. Create the package layout below and the `common/` scaffolding
   (`BaseEntity`, `BaseResponseBody`, the global exception handler, `SecurityConfig`,
   `CacheConfig`, i18n config) from `assets/`.
5. Wire config files: `application.properties` (profile-agnostic defaults + `spring.profiles.active=dev`),
   `application-dev.properties`, `application-prod.properties`, `logback-spring.xml`,
   `.env.example`, `compose.yaml` (local Postgres + Redis), `Dockerfile`, `.dockerignore`,
   `scripts/deploy.sh`.

## Package layout (feature-sliced, NOT layer-first at the root)

```
com.example.app/
├── AppApplication.java            # @SpringBootApplication + @EnableJpaAuditing(auditorAwareRef="auditorAwareImpl")
├── HomeController.java            # root health/landing endpoint only — not a feature
├── common/                        # cross-cutting; NEVER imports a feature package
│   ├── audit/                     # AuditorAwareImpl (resolves createdBy/updatedBy)
│   ├── base/                      # BaseEntity (@MappedSuperclass audit columns)
│   ├── config/                    # @Configuration: SecurityConfig, CacheConfig, LocalizationConfig, ValidationConfig, *Properties
│   ├── exception/                 # domain exceptions (extend RuntimeException)
│   ├── exception_handler/         # the global @RestControllerAdvice
│   ├── i18n/                      # SupportedLocales, MessageKeys
│   ├── response/                  # BaseResponseBody (sealed) + FieldError
│   ├── security/                  # JWTService, JWTAuthFilter, AppAuthenticationProvider, SecurityConstants, Rest*Handler
│   └── validation/                # custom Bean-Validation constraints (SecurePassword…)
└── features/
    └── <feature>/                 # auth, patient, doctor, admin, …
        ├── controller/
        ├── dto/                   # request/response records
        ├── entity/
        ├── mapper/                # MapStruct @Mapper(componentModel="spring")
        ├── repository/
        └── service/               # interface + *Impl
```

### Rules that keep the structure honest

- Every feature lives under `features.<feature>` — never add a feature directly under the
  base package, and never create root-level `controller`/`service`/`repository`/`entity`
  god-packages spanning all features.
- Only create the subpackages a feature actually needs (e.g. a feature that maps DTOs
  inline needs no `mapper/`). Don't add empty packages for symmetry.
- A feature may depend on `common/` freely, and on another feature **only** through that
  feature's public service interface + DTOs — never reach into another feature's
  `repository/` or `entity/`.
- `common/` may never import from a feature. Shared domain logic either belongs in `common/`
  or is owned by one feature and consumed via its interface.
- Default to package-private visibility; widen only when a real cross-package caller exists.

## Configuration profiles

- `application.properties` — profile-agnostic defaults only; set `spring.profiles.active=dev`.
- `application-dev.properties` — local dev; points at the `compose.yaml` Postgres/Redis with
  clearly-fake local credentials; may set `spring.jpa.hibernate.ddl-auto` loosely (local only).
- `application-prod.properties` — structure only, every value from `${ENV_VAR}`; `ddl-auto=validate`.
- `application-local.yml` — gitignored developer overrides (add to `.gitignore` on introduction).
- Activate a profile via `SPRING_PROFILES_ACTIVE`, never by editing the checked-in default.
- **Fail fast on missing secrets** — use `@ConfigurationProperties` + `@Validated` + `@NotBlank`
  on required fields, or explicit `@PostConstruct` checks. Never silently default a security
  value (JWT key, DB password) to an empty string.
- If using Spring Boot's Docker Compose support, set `spring.docker.compose.enabled=false` in
  the profiles where you want the app to connect to a real `DATABASE_URL` rather than have Boot
  auto-start (and prefer) the local `compose.yaml` container.

## Dependency management

Before adding a Maven dependency, check whether an existing starter already covers the need,
and confirm you're not duplicating `spring-boot-starter-data-jpa`/`-jdbc` functionality. Treat
**Spring Data JPA** (`@Entity` + `JpaRepository`) as the primary persistence mechanism; don't
mix a JDBC `@Table` entity and a JPA `@Entity` for the same table.

MapStruct + Lombok annotation-processor ordering matters in `maven-compiler-plugin`
`annotationProcessorPaths`: **lombok, then lombok-mapstruct-binding, then mapstruct-processor.**
