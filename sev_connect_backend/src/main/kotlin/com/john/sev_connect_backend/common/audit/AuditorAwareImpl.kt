package com.john.sev_connect_backend.common.audit

import com.john.sev_connect_backend.common.base.BaseEntity
import com.john.sev_connect_backend.common.security.UserPrincipal
import org.springframework.data.domain.AuditorAware
import org.springframework.security.authentication.AnonymousAuthenticationToken
import org.springframework.security.core.context.SecurityContextHolder
import org.springframework.stereotype.Component
import java.util.Optional
import java.util.UUID

/**
 * Resolves the acting user's UUID for JPA auditing. No authentication, or an anonymous one, is the
 * system user. An authenticated caller must expose a [UserPrincipal]; anything else is a bug and
 * fails loudly rather than attributing writes to the system user.
 */
@Component
class AuditorAwareImpl : AuditorAware<UUID> {
    override fun getCurrentAuditor(): Optional<UUID> {
        val authentication = SecurityContextHolder.getContext().authentication
        if (authentication == null || !authentication.isAuthenticated || authentication is AnonymousAuthenticationToken) {
            return Optional.of(BaseEntity.SYSTEM_USER_ID)
        }
        val principal =
            authentication.principal as? UserPrincipal
                ?: throw IllegalStateException("Authenticated principal does not expose a user id")
        return Optional.of(principal.userId)
    }
}
