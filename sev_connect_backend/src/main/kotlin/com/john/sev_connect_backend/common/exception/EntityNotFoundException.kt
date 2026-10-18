package com.john.sev_connect_backend.common.exception

import com.john.sev_connect_backend.common.i18n.MessageKeys

/** Maps to 404. */
class EntityNotFoundException(
    messageKey: String = MessageKeys.ERROR_NOT_FOUND,
    args: Array<out Any> = emptyArray(),
) : LocalizedException(messageKey, args)
