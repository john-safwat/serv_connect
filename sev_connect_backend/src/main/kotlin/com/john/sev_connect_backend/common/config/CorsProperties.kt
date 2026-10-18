package com.john.sev_connect_backend.common.config

import jakarta.validation.constraints.NotEmpty
import org.springframework.boot.context.properties.ConfigurationProperties
import org.springframework.validation.annotation.Validated

/** Dashboard origins allowed by CORS. Never `*`; a missing value aborts startup. */
@Validated
@ConfigurationProperties(prefix = "serveconnect.cors")
data class CorsProperties(
    @field:NotEmpty
    val allowedOrigins: List<String>,
) {
    init {
        require(allowedOrigins.none { it.trim() == "*" }) { "serveconnect.cors.allowed-origins must not contain '*'" }
    }
}
