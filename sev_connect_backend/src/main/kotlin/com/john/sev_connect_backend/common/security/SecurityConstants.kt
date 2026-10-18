package com.john.sev_connect_backend.common.security

/** Paths reachable without authentication. Everything else is default-deny. */
object SecurityConstants {
    fun publicApis(): Array<String> = arrayOf("/", "/actuator/health", "/api/v1/auth/**")
}
