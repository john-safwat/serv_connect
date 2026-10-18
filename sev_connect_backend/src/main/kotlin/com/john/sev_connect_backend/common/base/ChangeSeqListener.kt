package com.john.sev_connect_backend.common.base

import jakarta.persistence.PrePersist
import jakarta.persistence.PreUpdate
import org.springframework.jdbc.core.JdbcTemplate
import org.springframework.stereotype.Component

/** Stamps a fresh `sync_change_seq` value on every insert and on every real update of a syncable row. */
@Component
class ChangeSeqListener(
    private val jdbcTemplate: JdbcTemplate,
) {
    @PrePersist
    @PreUpdate
    fun assignChangeSeq(entity: SyncableEntity) {
        entity.changeSeq = checkNotNull(jdbcTemplate.queryForObject(NEXT_SEQ_SQL, Long::class.java))
    }

    private companion object {
        const val NEXT_SEQ_SQL = "select nextval('sync_change_seq')"
    }
}
