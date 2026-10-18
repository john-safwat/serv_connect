package com.john.sev_connect_backend.common.config

import com.john.sev_connect_backend.common.i18n.SupportedLocales
import org.springframework.context.annotation.Bean
import org.springframework.context.annotation.Configuration
import org.springframework.web.servlet.LocaleResolver
import org.springframework.web.servlet.i18n.AcceptHeaderLocaleResolver

/** Resolves the request locale from `Accept-Language`, restricted to [SupportedLocales]. */
@Configuration
class LocalizationConfig {
    @Bean
    fun localeResolver(): LocaleResolver =
        AcceptHeaderLocaleResolver().apply {
            setSupportedLocales(SupportedLocales.ALL)
            setDefaultLocale(SupportedLocales.DEFAULT)
        }
}
