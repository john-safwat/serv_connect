package com.john.sev_connect_backend.common.config

import org.springframework.boot.context.properties.EnableConfigurationProperties
import org.springframework.boot.test.context.runner.ApplicationContextRunner
import org.springframework.context.annotation.Configuration
import kotlin.test.Test
import kotlin.test.assertNotNull
import kotlin.test.assertNull

class RequiredSecretsPropertiesTest {
    @Configuration
    @EnableConfigurationProperties(RequiredSecretsProperties::class)
    class Config

    private val runner = ApplicationContextRunner().withUserConfiguration(Config::class.java)

    private val valid =
        arrayOf(
            "serveconnect.required.database-url=jdbc:postgresql://db/app",
            "serveconnect.required.database-username=app",
            "serveconnect.required.database-password=pw",
            "serveconnect.required.redis-host=redis",
            "serveconnect.required.redis-password=pw",
        )

    @Test
    fun `all values present starts`() {
        runner.withPropertyValues(*valid).run { assertNull(it.startupFailure) }
    }

    @Test
    fun `each blank value aborts startup`() {
        listOf("database-url", "database-username", "database-password", "redis-host", "redis-password").forEach { key ->
            runner
                .withPropertyValues(*valid, "serveconnect.required.$key=")
                .run { assertNotNull(it.startupFailure, "blank $key must fail startup") }
        }
    }

    @Test
    fun `missing values abort startup`() {
        runner.run { assertNotNull(it.startupFailure) }
    }
}
