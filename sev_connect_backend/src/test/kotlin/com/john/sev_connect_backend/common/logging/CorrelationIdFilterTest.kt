package com.john.sev_connect_backend.common.logging

import jakarta.servlet.FilterChain
import org.slf4j.MDC
import org.springframework.mock.web.MockHttpServletRequest
import org.springframework.mock.web.MockHttpServletResponse
import java.util.UUID
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFailsWith
import kotlin.test.assertNotEquals
import kotlin.test.assertNull

class CorrelationIdFilterTest {
    private val filter = CorrelationIdFilter()

    @Test
    fun `valid client id is used in the mdc and echoed, then the mdc is cleared`() {
        val id = UUID.randomUUID().toString()
        val request = MockHttpServletRequest().apply { addHeader(CorrelationIdFilter.HEADER, id) }
        val response = MockHttpServletResponse()
        var inChain: String? = null
        filter.doFilter(request, response, FilterChain { _, _ -> inChain = MDC.get(CorrelationIdFilter.MDC_KEY) })
        assertEquals(id, inChain)
        assertEquals(id, response.getHeader(CorrelationIdFilter.HEADER))
        assertNull(MDC.get(CorrelationIdFilter.MDC_KEY))
    }

    @Test
    fun `invalid client id is replaced`() {
        val request = MockHttpServletRequest().apply { addHeader(CorrelationIdFilter.HEADER, "bad value") }
        val response = MockHttpServletResponse()
        filter.doFilter(request, response, FilterChain { _, _ -> })
        assertNotEquals("bad value", response.getHeader(CorrelationIdFilter.HEADER))
    }

    @Test
    fun `mdc is cleared when the chain throws`() {
        assertFailsWith<IllegalStateException> {
            filter.doFilter(MockHttpServletRequest(), MockHttpServletResponse(), FilterChain { _, _ -> error("boom") })
        }
        assertNull(MDC.get(CorrelationIdFilter.MDC_KEY))
    }
}
