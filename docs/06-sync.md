# Offline-First Sync

Protocol skeleton from BRD §11 and backend `CLAUDE.md §12`. No entity is syncable yet; the base class and token sequence exist.

## Protocol

- IDs are UUIDs created on the device; every mutation carries a `mutationId` so retries are idempotent.
- Pull uses a monotonic change token: `change_seq`, drawn from the Postgres sequence `sync_change_seq` by `ChangeSeqListener` on every insert and every real update of a `SyncableEntity`. Device clocks are never used for ordering.
- Deletes are tombstones (`deleted_at` set, row kept, new `change_seq`). Lost access arrives as a revocation and the device must drop that data.
- Every read in the feed is scope-filtered server-side in the query.
- Server-side triggers (e.g. absence to follow-up) must be idempotent.
- A push batch processes each mutation in its own transaction; failures become per-item `REJECTED` / `CONFLICT` results, never a failed batch.
- `/api/v1` changes are additive; old app versions stay offline for weeks.

## Base class

`SyncableEntity` (`common/base`): `id` (client-suppliable UUID), `orgId`, `version` (`@Version`), `changeSeq`, `deletedAt`, plus audit columns from `BaseEntity`. Entities declare their own strategy below.

## Conflict strategy per data type

| Data type | Strategy |
| --- | --- |
| Config, schedules, groups | server-authoritative last-write-wins with a conflict warning |
| Attendance | merge per (occurrence, member) |
| Follow-ups, pastoral notes | append-only |
| Tasks | field-level merge |
| Personal state | per-user last-write-wins |

## Syncable entities

| Entity | Strategy | Scope filter | Notes |
| --- | --- | --- | --- |
| (none yet) | | | |

## Known limitations

- **Out-of-order commits can hide a row from a pull.** `change_seq` is drawn from a sequence at flush time, not at commit time. Two concurrent transactions can take seq 10 and 11 and commit in the order 11, 10. A client that pulled between the two commits holds token 11 and never receives seq 10. Intended mitigation, to be decided in the `sync` plan: the pull endpoint only returns rows up to a safe watermark (for example `now - lag window`, or the lowest in-flight seq), and clients re-pull a small overlap below their token (idempotent upserts make this safe). Until the sync feature exists, no feed reads `change_seq`.
