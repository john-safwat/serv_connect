package com.example.app.common.response;

/**
 * A single field-level validation error carried inside {@link BaseResponseBody.Fail#errors()}.
 * {@code field} is empty for class-level / global constraint violations that aren't tied to one field.
 */
public record FieldError(String field, String message) {}
