package com.john.sev_connect_backend.common.config

import jakarta.validation.Validation
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFailsWith

class CorsPropertiesTest {
    @Test
    fun `wildcard origin is rejected`() {
        assertFailsWith<IllegalArgumentException> { CorsProperties(listOf("*")) }
    }

    @Test
    fun `empty origin list is rejected by validation`() {
        val violations = Validation.buildDefaultValidatorFactory().validator.validate(CorsProperties(emptyList()))
        assertEquals(1, violations.size)
    }
}
