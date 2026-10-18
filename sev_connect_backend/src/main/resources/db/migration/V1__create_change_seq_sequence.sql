-- Global monotonic token for the offline sync feed (docs/06-sync.md).
-- SyncableEntity.changeSeq draws from it on every insert/update.
CREATE SEQUENCE sync_change_seq AS BIGINT START WITH 1 INCREMENT BY 1 NO CYCLE;
