package com.john.sev_connect_backend.common.i18n

import java.util.Locale

/** Locales the API can answer in. English is the default and the fallback for anything else. */
object SupportedLocales {
    val ENGLISH: Locale = Locale.ENGLISH
    val ARABIC: Locale = Locale.forLanguageTag("ar")
    val DEFAULT: Locale = ENGLISH
    val ALL: List<Locale> = listOf(ENGLISH, ARABIC)
}
