package com.john.sev_connect_backend.common.config

import org.springframework.context.annotation.Bean
import org.springframework.context.annotation.Configuration
import tools.jackson.module.kotlin.KotlinModule

/** Registers the Jackson 3 Kotlin module so Kotlin classes (de)serialize; Boot adds Module beans to the mapper. */
@Configuration
class JacksonConfig {
    @Bean
    fun kotlinModule(): KotlinModule = KotlinModule.Builder().build()
}
