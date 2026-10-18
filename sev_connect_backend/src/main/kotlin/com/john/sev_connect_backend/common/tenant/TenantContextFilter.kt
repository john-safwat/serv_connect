package com.john.sev_connect_backend.common.tenant

import jakarta.servlet.FilterChain
import jakarta.servlet.http.HttpServletRequest
import jakarta.servlet.http.HttpServletResponse
import org.springframework.security.core.context.SecurityContextHolder
import org.springframework.web.filter.OncePerRequestFilter

/**
 * Binds the caller's `orgId` into [TenantContext] after authentication. It reads the org from a
 * [TenantPrincipal]; until the identity feature supplies one, no tenant is bound.
 */
class TenantContextFilter : OncePerRequestFilter() {
    override fun doFilterInternal(
        request: HttpServletRequest,
        response: HttpServletResponse,
        filterChain: FilterChain,
    ) {
        try {
            (SecurityContextHolder.getContext().authentication?.principal as? TenantPrincipal)
                ?.let { TenantContext.set(it.orgId) }
            filterChain.doFilter(request, response)
        } finally {
            TenantContext.clear()
        }
    }
}
