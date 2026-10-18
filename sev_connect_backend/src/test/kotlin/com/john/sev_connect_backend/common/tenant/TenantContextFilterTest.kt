package com.john.sev_connect_backend.common.tenant

import jakarta.servlet.FilterChain
import org.springframework.mock.web.MockHttpServletRequest
import org.springframework.mock.web.MockHttpServletResponse
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken
import org.springframework.security.core.context.SecurityContextHolder
import java.util.UUID
import kotlin.test.AfterTest
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFailsWith
import kotlin.test.assertNull

class TenantContextFilterTest {
    private val filter = TenantContextFilter()

    private class Principal(
        override val orgId: UUID,
    ) : TenantPrincipal

    @AfterTest
    fun cleanup() {
        SecurityContextHolder.clearContext()
        TenantContext.clear()
    }

    private fun authenticate(principal: Any) {
        SecurityContextHolder.getContext().authentication = UsernamePasswordAuthenticationToken(principal, "n/a", emptyList())
    }

    @Test
    fun `binds the org from a tenant principal for the duration of the request and clears it`() {
        val orgId = UUID.randomUUID()
        authenticate(Principal(orgId))
        var seen: UUID? = null
        filter.doFilter(MockHttpServletRequest(), MockHttpServletResponse(), FilterChain { _, _ -> seen = TenantContext.orgId() })
        assertEquals(orgId, seen)
        assertNull(TenantContext.orgId())
    }

    @Test
    fun `binds nothing for a plain principal`() {
        authenticate("someone")
        var seen: UUID? = UUID.randomUUID()
        filter.doFilter(MockHttpServletRequest(), MockHttpServletResponse(), FilterChain { _, _ -> seen = TenantContext.orgId() })
        assertNull(seen)
    }

    @Test
    fun `clears the tenant even when the chain throws`() {
        authenticate(Principal(UUID.randomUUID()))
        assertFailsWith<IllegalStateException> {
            filter.doFilter(
                MockHttpServletRequest(),
                MockHttpServletResponse(),
                FilterChain { _, _ -> error("boom") },
            )
        }
        assertNull(TenantContext.orgId())
    }
}
