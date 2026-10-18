package com.john.sev_connect_backend.common.config

import org.springframework.context.annotation.Configuration
import org.springframework.data.jpa.repository.config.EnableJpaAuditing

/** Kept off the application class so web-slice tests don't need a JPA metamodel. */
@Configuration
@EnableJpaAuditing(auditorAwareRef = "auditorAwareImpl")
class JpaAuditingConfig
