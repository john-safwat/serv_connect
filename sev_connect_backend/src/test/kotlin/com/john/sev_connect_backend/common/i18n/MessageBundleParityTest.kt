package com.john.sev_connect_backend.common.i18n

import java.util.Properties
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertTrue

class MessageBundleParityTest {
    private fun load(name: String): Properties =
        Properties().apply {
            checkNotNull(MessageBundleParityTest::class.java.getResourceAsStream("/i18n/$name")).reader(Charsets.UTF_8).use { load(it) }
        }

    private val en = load("messages.properties")
    private val ar = load("messages_ar.properties")

    @Test
    fun `both bundles have identical key sets`() {
        assertEquals(en.stringPropertyNames().sorted(), ar.stringPropertyNames().sorted())
    }

    @Test
    fun `every message key constant exists in both bundles`() {
        val constants =
            MessageKeys::class.java.declaredFields
                .filter {
                    it.type == String::class.java &&
                        java.lang.reflect.Modifier
                            .isStatic(it.modifiers)
                }.map { it.get(null) as String }
        assertTrue(constants.isNotEmpty())
        constants.forEach {
            assertTrue(en.containsKey(it), "missing in en: $it")
            assertTrue(ar.containsKey(it), "missing in ar: $it")
        }
    }

    @Test
    fun `no value is blank`() {
        (en.values + ar.values).forEach { assertTrue(it.toString().isNotBlank()) }
    }
}
