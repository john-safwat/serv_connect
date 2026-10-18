package com.john.sev_connect_backend.common.config

import com.john.sev_connect_backend.common.security.RestAccessDeniedHandler
import com.john.sev_connect_backend.common.security.RestAuthenticationEntryPoint
import com.john.sev_connect_backend.common.security.SecurityConstants
import com.john.sev_connect_backend.common.tenant.TenantContextFilter
import org.springframework.boot.context.properties.EnableConfigurationProperties
import org.springframework.context.annotation.Bean
import org.springframework.context.annotation.Configuration
import org.springframework.http.HttpHeaders
import org.springframework.security.config.annotation.method.configuration.EnableMethodSecurity
import org.springframework.security.config.annotation.web.builders.HttpSecurity
import org.springframework.security.config.annotation.web.configurers.AbstractHttpConfigurer
import org.springframework.security.config.http.SessionCreationPolicy
import org.springframework.security.core.userdetails.UserDetailsService
import org.springframework.security.core.userdetails.UsernameNotFoundException
import org.springframework.security.web.SecurityFilterChain
import org.springframework.security.web.access.intercept.AuthorizationFilter
import org.springframework.web.cors.CorsConfiguration
import org.springframework.web.cors.CorsConfigurationSource
import org.springframework.web.cors.UrlBasedCorsConfigurationSource

/**
 * Default-deny, stateless security. JWT authentication, permissions and scopes arrive with the
 * identity feature; until then every path outside [SecurityConstants.publicApis] returns 401.
 * CSRF is off because auth is stateless Bearer tokens (no session cookies).
 */
@Configuration
@EnableMethodSecurity
@EnableConfigurationProperties(CorsProperties::class)
class SecurityConfig {
    @Bean
    fun securityFilterChain(
        http: HttpSecurity,
        entryPoint: RestAuthenticationEntryPoint,
        accessDeniedHandler: RestAccessDeniedHandler,
        corsConfigurationSource: CorsConfigurationSource,
    ): SecurityFilterChain =
        http
            .csrf(AbstractHttpConfigurer<*, *>::disable)
            .cors { it.configurationSource(corsConfigurationSource) }
            .exceptionHandling {
                it.authenticationEntryPoint(entryPoint).accessDeniedHandler(accessDeniedHandler)
            }.authorizeHttpRequests {
                it
                    .requestMatchers(*SecurityConstants.publicApis())
                    .permitAll()
                    .anyRequest()
                    .authenticated()
            }.sessionManagement { it.sessionCreationPolicy(SessionCreationPolicy.STATELESS) }
            .addFilterBefore(TenantContextFilter(), AuthorizationFilter::class.java)
            .build()

    /** Deny-all placeholder so Boot does not create a default user with a generated password. Replaced by identity. */
    @Bean
    fun userDetailsService(): UserDetailsService = UserDetailsService { throw UsernameNotFoundException("No users") }

    @Bean
    fun corsConfigurationSource(properties: CorsProperties): CorsConfigurationSource {
        val configuration =
            CorsConfiguration().apply {
                allowedOrigins = properties.allowedOrigins
                allowedMethods = listOf("GET", "POST", "PUT", "PATCH", "DELETE", "OPTIONS")
                allowedHeaders =
                    listOf(
                        HttpHeaders.AUTHORIZATION,
                        HttpHeaders.CONTENT_TYPE,
                        HttpHeaders.ACCEPT_LANGUAGE,
                        "Idempotency-Key",
                        "X-Correlation-Id",
                    )
                exposedHeaders = listOf("X-Correlation-Id", HttpHeaders.LOCATION)
                maxAge = 3600
            }
        return UrlBasedCorsConfigurationSource().apply { registerCorsConfiguration("/**", configuration) }
    }
}
