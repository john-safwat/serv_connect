package com.john.sev_connect_backend.common.security

import java.util.UUID

/** Implemented by the authenticated principal (identity feature) so auditing never parses a name. */
interface UserPrincipal {
    val userId: UUID
}
