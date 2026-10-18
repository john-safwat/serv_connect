package com.john.sev_connect_backend.common.audit

import com.john.sev_connect_backend.common.base.BaseEntity
import com.john.sev_connect_backend.common.security.UserPrincipal
import org.springframework.security.authentication.AnonymousAuthenticationToken
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken
import org.springframework.security.core.authority.AuthorityUtils
import org.springframework.security.core.context.SecurityContextHolder
import java.util.UUID
import kotlin.test.AfterTest
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFailsWith

class AuditorAwareImplTest {
    private val auditor = AuditorAwareImpl()

    private class Principal(
        override val userId: UUID,
    ) : UserPrincipal

    @AfterTest
    fun clear() = SecurityContextHolder.clearContext()

    @Test
    fun `unauthenticated caller is the system user`() {
        SecurityContextHolder.clearContext()
        assertEquals(BaseEntity.SYSTEM_USER_ID, auditor.currentAuditor.get())
    }

    @Test
    fun `anonymous caller is the system user`() {
        SecurityContextHolder.getContext().authentication =
            anonymousToken()
        assertEquals(BaseEntity.SYSTEM_USER_ID, auditor.currentAuditor.get())
    }

    @Test
    fun `authenticated caller is recorded by the typed principal user id`() {
        val userId = UUID.randomUUID()
        SecurityContextHolder.getContext().authentication =
            UsernamePasswordAuthenticationToken(Principal(userId), "n/a", emptyList())
        assertEquals(userId, auditor.currentAuditor.get())
    }

    @Test
    fun `a uuid-looking name is never trusted without a typed principal`() {
        SecurityContextHolder.getContext().authentication =
            UsernamePasswordAuthenticationToken(UUID.randomUUID().toString(), "n/a", emptyList())
        assertFailsWith<IllegalStateException> { auditor.currentAuditor }
    }

    @Test
    fun `authenticated principal without a user id fails instead of falling back`() {
        SecurityContextHolder.getContext().authentication =
            UsernamePasswordAuthenticationToken("not-a-uuid", "n/a", emptyList())
        assertFailsWith<IllegalStateException> { auditor.currentAuditor }
    }

    private fun anonymousToken() = AnonymousAuthenticationToken("key", "anonymous", AuthorityUtils.createAuthorityList("ROLE_ANONYMOUS"))
}
