# Database Schema

PostgreSQL 17 is the only target. Schema changes go through Flyway (`sev_connect_backend/src/main/resources/db/migration/`), named `V<version>__<description>.sql`. An applied migration is never edited. `spring.jpa.hibernate.ddl-auto=validate` in every profile.

## Conventions

- Table and column names are `snake_case`; table names are plural.
- Primary keys are `UUID`, creatable by the offline client.
- Every tenant-scoped table has a non-null, indexed `org_id` (populated from `TenantContext`, never from a request body).
- Instants are `timestamptz`, mapped to `Instant` (UTC).
- Syncable tables carry the `SyncableEntity` columns below.
- History is end-dated (`valid_from` / `valid_to`) or tombstoned (`deleted_at`), never physically deleted.
- Sensitive data lives in its own tables.

### Audit columns (every entity, `BaseEntity`)

| Column | Type | Notes |
| --- | --- | --- |
| `created_at` | timestamptz not null | set by JPA auditing, not updatable |
| `updated_at` | timestamptz not null | |
| `created_by` | uuid not null | acting user; `00000000-0000-0000-0000-000000000000` when no user (system) |
| `updated_by` | uuid not null | |

### Sync columns (`SyncableEntity`)

| Column | Type | Notes |
| --- | --- | --- |
| `id` | uuid PK | client-suppliable |
| `org_id` | uuid not null | tenant |
| `version` | bigint not null | optimistic lock (`@Version`); null in memory until first persist |
| `change_seq` | bigint not null | drawn from `sync_change_seq` on every insert and real update; index it with `org_id` in the entity's migration |
| `deleted_at` | timestamptz null | tombstone |

## Migrations

| Version | File | Purpose |
| --- | --- | --- |
| V1 | `V1__create_change_seq_sequence.sql` | creates sequence `sync_change_seq` (the global monotonic sync token) |

Test-only migration `V9000__create_sync_probe_table.sql` lives in `src/test/resources/db/test-migration/` and is never packaged.
