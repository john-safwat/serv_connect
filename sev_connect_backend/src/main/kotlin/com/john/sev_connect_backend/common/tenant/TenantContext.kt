package com.john.sev_connect_backend.common.tenant

import java.util.UUID

/** Holds the caller's organization for the current request thread. Cleared by [TenantContextFilter]. */
object TenantContext {
    private val current = ThreadLocal<UUID?>()

    fun orgId(): UUID? = current.get()

    /** For services that write tenant-scoped rows; an absent tenant is a programming error. */
    fun requireOrgId(): UUID = checkNotNull(current.get()) { "No tenant bound to the current request" }

    fun set(orgId: UUID) = current.set(orgId)

    fun clear() = current.remove()
}
