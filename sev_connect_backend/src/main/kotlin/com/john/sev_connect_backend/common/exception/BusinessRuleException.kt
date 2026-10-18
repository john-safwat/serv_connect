package com.john.sev_connect_backend.common.exception

import com.john.sev_connect_backend.common.i18n.MessageKeys

/** A business-rule violation raised by a service. Maps to 400, or 409 when [conflict] is true. */
class BusinessRuleException(
    messageKey: String = MessageKeys.ERROR_BUSINESS_RULE,
    args: Array<out Any> = emptyArray(),
    val conflict: Boolean = false,
) : LocalizedException(messageKey, args)
