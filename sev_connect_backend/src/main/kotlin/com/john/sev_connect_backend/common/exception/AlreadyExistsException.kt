package com.john.sev_connect_backend.common.exception

import com.john.sev_connect_backend.common.i18n.MessageKeys

/** Maps to 409. */
class AlreadyExistsException(
    messageKey: String = MessageKeys.ERROR_ALREADY_EXISTS,
    args: Array<out Any> = emptyArray(),
) : LocalizedException(messageKey, args)
