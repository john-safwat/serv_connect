package com.john.sev_connect_backend.common.config

import jakarta.validation.constraints.NotBlank
import org.springframework.boot.context.properties.ConfigurationProperties
import org.springframework.context.annotation.Profile
import org.springframework.validation.annotation.Validated

/**
 * Prod-only guard: `${VAR}` placeholders accept a set-but-empty value, so these are re-bound and
 * validated to abort startup when a required connection secret is blank.
 */
@Validated
@Profile("prod")
@ConfigurationProperties(prefix = "serveconnect.required")
data class RequiredSecretsProperties(
    @field:NotBlank val databaseUrl: String,
    @field:NotBlank val databaseUsername: String,
    @field:NotBlank val databasePassword: String,
    @field:NotBlank val redisHost: String,
    @field:NotBlank val redisPassword: String,
)
