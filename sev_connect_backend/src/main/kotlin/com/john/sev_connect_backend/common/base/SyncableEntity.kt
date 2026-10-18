package com.john.sev_connect_backend.common.base

import jakarta.persistence.Column
import jakarta.persistence.EntityListeners
import jakarta.persistence.Id
import jakarta.persistence.MappedSuperclass
import jakarta.persistence.Version
import org.hibernate.Hibernate
import java.time.Instant
import java.util.UUID

/**
 * Base for every entity the mobile client caches (docs/06-sync.md). The id is client-suppliable;
 * [changeSeq] is the monotonic sync token drawn from `sync_change_seq` on every insert/update;
 * [deletedAt] is the tombstone (rows are never physically deleted).
 */
@MappedSuperclass
@EntityListeners(ChangeSeqListener::class)
abstract class SyncableEntity(
    @Id
    @Column(name = "id", nullable = false, updatable = false)
    var id: UUID,
    @Column(name = "org_id", nullable = false, updatable = false)
    var orgId: UUID,
) : BaseEntity() {
    /** Null until first persisted; a null wrapper-typed version is how Spring Data detects a new entity. */
    @Version
    @Column(name = "version", nullable = false)
    var version: Long? = null

    @Column(name = "change_seq", nullable = false)
    var changeSeq: Long = 0

    @Column(name = "deleted_at")
    var deletedAt: Instant? = null

    override fun equals(other: Any?): Boolean {
        if (this === other) return true
        if (other !is SyncableEntity) return false
        // Hibernate.getClass unwraps lazy proxies on both sides.
        if (Hibernate.getClass(this) != Hibernate.getClass(other)) return false
        return id == other.id
    }

    override fun hashCode(): Int = Hibernate.getClass(this).hashCode()

    override fun toString(): String = "${javaClass.simpleName}(id=$id)"
}
