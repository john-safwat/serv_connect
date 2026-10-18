package com.john.sev_connect_backend.common.exception

/**
 * Base of every typed domain exception. Carries a [com.john.sev_connect_backend.common.i18n.MessageKeys]
 * key plus message arguments, never a raw user-facing string.
 */
abstract class LocalizedException(
    val messageKey: String,
    val args: Array<out Any> = emptyArray(),
) : RuntimeException(messageKey)
