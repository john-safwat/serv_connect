# Database, Entities & Migrations

## Migrations (Flyway)

- Schema changes go through **Flyway** files under `src/main/resources/db/migration/`, named
  `V<version>__<description>.sql` (e.g. `V1__create_patient_table.sql`). Add `flyway-core` (+
  `flyway-database-postgresql` for Postgres 10+) if not present. The source project organizes
  migrations by database under `db/migration/{postgresql,h2,common}` when it runs tests on H2 and
  prod on Postgres — a single `db/migration/` folder is fine when there's one target DB.
- `spring.jpa.hibernate.ddl-auto` is `validate` (or `none`) in every profile except a developer's
  own `application-local.yml`. Hibernate is never the schema source of truth outside a laptop.
- **Never edit a migration already applied** in any shared environment — ship a new migration to
  fix a mistake, even a one-character one. Editing an applied migration is a stop-and-confirm action.
- One logical schema change per file.

## Zero-downtime sequencing

- Never combine a column removal/rename with the release that stops using it. Two steps: (1) add
  the new column, deploy, backfill, migrate reads/writes; (2) a later release drops the old column.
- Adding a `NOT NULL` column to a populated table needs a default or a backfill in the same/prior
  migration.
- Treat a rename as drop + add (the two-step above) unless the deploy strategy tolerates a brief
  schema/code mismatch.

## Entities

- One `@Entity` per aggregate-root table, named after the domain concept, at the top level of its
  feature's `entity/` package.
- **Standard Lombok shape:** `@Getter @Setter @NoArgsConstructor(access = PROTECTED)` plus a
  package-visible all-args constructor or static factory. **Never `@Data` on an `@Entity`** — it
  generates `equals`/`hashCode` over all fields (triggers N+1 through lazy associations, breaks
  Hibernate proxies) and a `toString()` that can leak PHI into logs.
- **Identity equality by database `id` only, once assigned:**

  ```java
  @Override public boolean equals(Object o) {
      if (this == o) return true;
      if (!(o instanceof Patient other)) return false;
      return id != null && id.equals(other.id);
  }
  @Override public int hashCode() { return getClass().hashCode(); }
  ```

- Bidirectional associations: one side `mappedBy`, plus a helper (`addX`/`removeX`) that keeps both
  sides in sync — never set only one side.
- Default `@ManyToOne`/`@OneToOne` to `LAZY` unless measured otherwise; `@OneToMany`/`@ManyToMany`
  are `LAZY` by default (JPA).
- A **shared-PK one-to-one** to a parent is `@MapsId` (the source project's role profiles —
  `PatientProfile`, `DoctorProfile`, … — are each a `@MapsId` one-to-one with the `AppUser`).

## Auditing (`createdAt`/`updatedAt`/`createdBy`/`updatedBy`)

- A `BaseEntity` `@MappedSuperclass` (see `assets/BaseEntity.java`) carries the four audit columns,
  registered with `AuditingEntityListener`. Every domain entity `extends BaseEntity` rather than
  redeclaring the columns.
- Enable with `@EnableJpaAuditing(auditorAwareRef = "auditorAwareImpl")` on the application class,
  plus an `AuditorAwareImpl` in `common/audit/` that returns the current actor. Until auth is wired,
  it may return a fixed `"System User"`; once `JWTAuthFilter` populates `SecurityContextHolder`,
  read the principal from there.

## Timestamps & timezones

- Persist absolute instants as `Instant` (UTC), column type `timestamptz` (Postgres) so timezone
  is never dropped. Use `LocalDate`/`LocalTime` only for genuine date/time-of-day concepts (a DOB,
  clinic opening hours).
- Never format a timestamp on the backend — return the raw `Instant`/ISO-8601 and let the client
  render locally. If a slot needs a specific local time, store both the `Instant` and the IANA
  `ZoneId` explicitly.

## Queries & performance

- Prefer derived query methods (`findByEmailAndActiveTrue`) and JPQL `@Query`; native SQL only when
  JPQL genuinely can't express it.
- Paginate any list that can grow (`Pageable`/`Page<T>`) — no unbounded `findAll()` reaching a
  controller.
- Avoid N+1 with `@EntityGraph`/`JOIN FETCH` on listing associations.
- Index every column used in a `WHERE`/`JOIN`/`ORDER BY` on a growing table, in the same migration
  that introduces the query pattern.
