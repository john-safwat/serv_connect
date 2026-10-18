package com.john.sev_connect_backend.common.response

import com.fasterxml.jackson.annotation.JsonIgnore
import com.fasterxml.jackson.annotation.JsonInclude
import com.fasterxml.jackson.annotation.JsonProperty
import org.springframework.http.HttpStatus
import org.springframework.http.ResponseEntity

/**
 * Closed hierarchy of response bodies returned by every controller and the global exception
 * handler. [Success] carries the data; [Fail] carries an optional list of [FieldError]s.
 *
 * There is deliberately no 204 path: a void success is a [Success] with `data == null`.
 */
@JsonInclude(JsonInclude.Include.NON_NULL)
sealed interface BaseResponseBody<out T> {
    val code: Int
    val status: HttpStatus
    val message: String

    data class Success<out T>(
        override val code: Int,
        @get:JsonIgnore override val status: HttpStatus,
        override val message: String,
        val data: T? = null,
    ) : BaseResponseBody<T> {
        /** Wire name of the status (`OK`), independent of how Jackson renders the enum. */
        @get:JsonProperty("status")
        val statusName: String get() = status.name
    }

    data class Fail(
        override val code: Int,
        @get:JsonIgnore override val status: HttpStatus,
        override val message: String,
        val errors: List<FieldError>? = null,
    ) : BaseResponseBody<Nothing> {
        /** Wire name of the status (`BAD_REQUEST`), independent of how Jackson renders the enum. */
        @get:JsonProperty("status")
        val statusName: String get() = status.name
    }

    companion object {
        fun <T> success(
            data: T?,
            message: String,
            status: HttpStatus = HttpStatus.OK,
        ): Success<T> = Success(status.value(), status, message, data)

        fun fail(
            status: HttpStatus,
            message: String,
            errors: List<FieldError>? = null,
        ): Fail = Fail(status.value(), status, message, errors)

        fun <T> toResponseEntity(body: BaseResponseBody<T>): ResponseEntity<BaseResponseBody<T>> =
            ResponseEntity.status(body.status).body(body)
    }
}
