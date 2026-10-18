package com.john.sev_connect_backend.common.config

import org.springframework.mock.web.MockHttpServletRequest
import java.util.Locale
import kotlin.test.Test
import kotlin.test.assertEquals

class LocalizationConfigTest {
    private val resolver = LocalizationConfig().localeResolver()

    private fun resolve(header: String?): Locale {
        val request = MockHttpServletRequest()
        if (header != null) request.addHeader("Accept-Language", header)
        return resolver.resolveLocale(request)
    }

    @Test
    fun `arabic header resolves to arabic`() = assertEquals("ar", resolve("ar").language)

    @Test
    fun `english header resolves to english`() = assertEquals("en", resolve("en-US").language)

    @Test
    fun `unsupported language falls back to english`() = assertEquals("en", resolve("fr").language)

    @Test
    fun `missing header falls back to english`() = assertEquals("en", resolve(null).language)

    @Test
    fun `weighted header picks the best supported language`() = assertEquals("ar", resolve("fr;q=0.9, ar;q=0.8").language)
}
