-- Test-only table backing SyncProbe, used to exercise SyncableEntity against real Postgres.
CREATE TABLE sync_probes (
    id          UUID PRIMARY KEY,
    org_id      UUID        NOT NULL,
    label       VARCHAR(50) NOT NULL,
    version     BIGINT      NOT NULL,
    change_seq  BIGINT      NOT NULL,
    deleted_at  TIMESTAMPTZ,
    created_at  TIMESTAMPTZ NOT NULL,
    updated_at  TIMESTAMPTZ NOT NULL,
    created_by  UUID        NOT NULL,
    updated_by  UUID        NOT NULL
);
