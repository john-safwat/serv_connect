package com.john.sev_connect_backend.common.exception

import com.john.sev_connect_backend.common.i18n.MessageKeys

/** Optimistic-lock or stale client version. Maps to 409. */
class StaleVersionException(
    messageKey: String = MessageKeys.ERROR_STALE_VERSION,
    args: Array<out Any> = emptyArray(),
) : LocalizedException(messageKey, args)
