package com.john.sev_connect_backend.common.exception

import com.john.sev_connect_backend.common.i18n.MessageKeys

/** Maps to 401. */
class InvalidCredentialsException(
    messageKey: String = MessageKeys.ERROR_INVALID_CREDENTIALS,
    args: Array<out Any> = emptyArray(),
) : LocalizedException(messageKey, args)
