package com.john.sev_connect_backend.common.config

import org.springframework.context.MessageSource
import org.springframework.context.annotation.Bean
import org.springframework.context.annotation.Configuration
import org.springframework.validation.beanvalidation.LocalValidatorFactoryBean

/** Bean Validation resolves constraint messages from the app `MessageSource` (en + ar bundles). */
@Configuration
class ValidationConfig {
    @Bean
    fun validator(messageSource: MessageSource): LocalValidatorFactoryBean =
        LocalValidatorFactoryBean().apply { setValidationMessageSource(messageSource) }
}
