package com.john.sev_connect_backend.common.base

import jakarta.persistence.Column
import jakarta.persistence.EntityListeners
import jakarta.persistence.MappedSuperclass
import org.springframework.data.annotation.CreatedBy
import org.springframework.data.annotation.CreatedDate
import org.springframework.data.annotation.LastModifiedBy
import org.springframework.data.annotation.LastModifiedDate
import org.springframework.data.jpa.domain.support.AuditingEntityListener
import java.time.Instant
import java.util.UUID

/** Audit columns shared by every entity. Populated by JPA auditing; never set by callers. */
@MappedSuperclass
@EntityListeners(AuditingEntityListener::class)
abstract class BaseEntity {
    @CreatedDate
    @Column(name = "created_at", nullable = false, updatable = false)
    var createdAt: Instant = Instant.EPOCH

    @LastModifiedDate
    @Column(name = "updated_at", nullable = false)
    var updatedAt: Instant = Instant.EPOCH

    @CreatedBy
    @Column(name = "created_by", nullable = false, updatable = false)
    var createdBy: UUID = SYSTEM_USER_ID

    @LastModifiedBy
    @Column(name = "updated_by", nullable = false)
    var updatedBy: UUID = SYSTEM_USER_ID

    companion object {
        /** Auditor recorded when no user is authenticated (system jobs, migrations, tests). */
        val SYSTEM_USER_ID: UUID = UUID(0L, 0L)
    }
}
