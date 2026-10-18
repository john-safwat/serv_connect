package com.john.sev_connect_backend.common.tenant

import java.util.UUID

/** Implemented by the authenticated principal (identity feature) so the filter can bind the tenant. */
interface TenantPrincipal {
    val orgId: UUID
}
