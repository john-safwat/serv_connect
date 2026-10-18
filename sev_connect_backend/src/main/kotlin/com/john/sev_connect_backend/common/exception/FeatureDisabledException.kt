package com.john.sev_connect_backend.common.exception

import com.john.sev_connect_backend.common.i18n.MessageKeys

/** Maps to 403. */
class FeatureDisabledException(
    messageKey: String = MessageKeys.ERROR_FEATURE_DISABLED,
    args: Array<out Any> = emptyArray(),
) : LocalizedException(messageKey, args)
