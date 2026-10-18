package com.john.sev_connect_backend.common.base

import org.springframework.data.jpa.repository.JpaRepository
import java.util.UUID

interface SyncProbeRepository : JpaRepository<SyncProbe, UUID>
