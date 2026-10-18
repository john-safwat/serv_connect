package com.john.sev_connect_backend.common.base

import jakarta.persistence.Column
import jakarta.persistence.Entity
import jakarta.persistence.Table
import java.util.UUID

/** Test-only syncable entity (table created by the test-only migration). */
@Entity
@Table(name = "sync_probes")
class SyncProbe(
    id: UUID,
    orgId: UUID,
    @Column(name = "label", nullable = false)
    var label: String,
) : SyncableEntity(id, orgId)
