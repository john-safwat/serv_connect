package com.john.sev_connect_backend.common.response

/**
 * A single field-level validation error carried inside [BaseResponseBody.Fail.errors].
 * [field] is empty for class-level constraint violations that aren't tied to one field.
 */
data class FieldError(
    val field: String,
    val message: String,
)
