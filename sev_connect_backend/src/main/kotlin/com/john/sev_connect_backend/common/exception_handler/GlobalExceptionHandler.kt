package com.john.sev_connect_backend.common.exception_handler

import com.john.sev_connect_backend.common.exception.AlreadyExistsException
import com.john.sev_connect_backend.common.exception.BusinessRuleException
import com.john.sev_connect_backend.common.exception.EntityNotFoundException
import com.john.sev_connect_backend.common.exception.FeatureDisabledException
import com.john.sev_connect_backend.common.exception.InvalidCredentialsException
import com.john.sev_connect_backend.common.exception.LocalizedException
import com.john.sev_connect_backend.common.exception.StaleVersionException
import com.john.sev_connect_backend.common.i18n.MessageKeys
import com.john.sev_connect_backend.common.response.BaseResponseBody
import com.john.sev_connect_backend.common.response.FieldError
import jakarta.persistence.OptimisticLockException
import jakarta.servlet.http.HttpServletRequest
import jakarta.validation.ConstraintViolationException
import org.slf4j.LoggerFactory
import org.springframework.context.MessageSource
import org.springframework.core.Ordered
import org.springframework.core.annotation.Order
import org.springframework.dao.DataIntegrityViolationException
import org.springframework.http.HttpStatus
import org.springframework.http.MediaType
import org.springframework.http.ResponseEntity
import org.springframework.http.converter.HttpMessageNotReadableException
import org.springframework.orm.ObjectOptimisticLockingFailureException
import org.springframework.security.access.AccessDeniedException
import org.springframework.security.core.AuthenticationException
import org.springframework.web.HttpMediaTypeNotAcceptableException
import org.springframework.web.HttpMediaTypeNotSupportedException
import org.springframework.web.HttpRequestMethodNotSupportedException
import org.springframework.web.bind.MethodArgumentNotValidException
import org.springframework.web.bind.MissingRequestHeaderException
import org.springframework.web.bind.MissingServletRequestParameterException
import org.springframework.web.bind.annotation.ExceptionHandler
import org.springframework.web.bind.annotation.RestControllerAdvice
import org.springframework.web.method.annotation.HandlerMethodValidationException
import org.springframework.web.method.annotation.MethodArgumentTypeMismatchException
import org.springframework.web.multipart.support.MissingServletRequestPartException
import org.springframework.web.servlet.resource.NoResourceFoundException
import tools.jackson.core.JacksonException
import java.util.Locale

/**
 * Maps every thrown exception to a [BaseResponseBody.Fail] envelope. Client-facing messages are
 * localized and generic; raw messages and stack traces never reach the client. Detail is logged
 * server-side with the request path only (no bodies, no PII).
 */
@RestControllerAdvice
@Order(Ordered.HIGHEST_PRECEDENCE)
class GlobalExceptionHandler(
    private val messageSource: MessageSource,
) {
    private val log = LoggerFactory.getLogger(javaClass)

    private fun message(
        key: String,
        locale: Locale,
        vararg args: Any,
    ): String = messageSource.getMessage(key, args, key, locale) ?: key

    private fun fail(
        status: HttpStatus,
        key: String,
        locale: Locale,
        errors: List<FieldError>? = null,
        vararg args: Any,
    ): ResponseEntity<BaseResponseBody<Nothing>> =
        BaseResponseBody.toResponseEntity(BaseResponseBody.fail(status, message(key, locale, *args), errors))

    @ExceptionHandler(LocalizedException::class)
    fun handleDomain(
        exception: LocalizedException,
        request: HttpServletRequest,
        locale: Locale,
    ): ResponseEntity<BaseResponseBody<Nothing>> {
        val status =
            when (exception) {
                is EntityNotFoundException -> HttpStatus.NOT_FOUND
                is AlreadyExistsException -> HttpStatus.CONFLICT
                is StaleVersionException -> HttpStatus.CONFLICT
                is InvalidCredentialsException -> HttpStatus.UNAUTHORIZED
                is FeatureDisabledException -> HttpStatus.FORBIDDEN
                is BusinessRuleException -> if (exception.conflict) HttpStatus.CONFLICT else HttpStatus.BAD_REQUEST
                else -> HttpStatus.BAD_REQUEST
            }
        log.warn("{} on {}: {}", status.value(), request.requestURI, exception.messageKey)
        return fail(status, exception.messageKey, locale, null, *exception.args)
    }

    @ExceptionHandler(AuthenticationException::class)
    fun handleAuthentication(
        exception: AuthenticationException,
        request: HttpServletRequest,
        locale: Locale,
    ): ResponseEntity<BaseResponseBody<Nothing>> {
        log.warn("Authentication failed on {}: {}", request.requestURI, exception.javaClass.simpleName)
        return fail(HttpStatus.UNAUTHORIZED, MessageKeys.ERROR_UNAUTHORIZED, locale)
    }

    @ExceptionHandler(AccessDeniedException::class)
    fun handleAccessDenied(
        exception: AccessDeniedException,
        request: HttpServletRequest,
        locale: Locale,
    ): ResponseEntity<BaseResponseBody<Nothing>> {
        log.warn("Access denied on {}", request.requestURI)
        return fail(HttpStatus.FORBIDDEN, MessageKeys.ERROR_FORBIDDEN, locale)
    }

    @ExceptionHandler(MethodArgumentNotValidException::class)
    fun handleValidation(
        exception: MethodArgumentNotValidException,
        request: HttpServletRequest,
        locale: Locale,
    ): ResponseEntity<BaseResponseBody<Nothing>> {
        // Each default message is already localized by the validator's MessageSource interpolator.
        val errors =
            exception.bindingResult.fieldErrors.map { FieldError(it.field, it.defaultMessage.orEmpty()) } +
                exception.bindingResult.globalErrors.map { FieldError("", it.defaultMessage.orEmpty()) }
        log.warn("Validation failed on {}: fields={}", request.requestURI, errors.map { it.field })
        return fail(HttpStatus.BAD_REQUEST, MessageKeys.ERROR_VALIDATION, locale, errors)
    }

    @ExceptionHandler(HttpMessageNotReadableException::class)
    fun handleNotReadable(
        exception: HttpMessageNotReadableException,
        request: HttpServletRequest,
        locale: Locale,
    ): ResponseEntity<BaseResponseBody<Nothing>> {
        val field = (exception.cause as? JacksonException)?.fieldPath().orEmpty()
        log.warn("Unreadable request body on {}: field={}", request.requestURI, field)
        val errors = if (field.isBlank()) null else listOf(FieldError(field, message(MessageKeys.ERROR_FIELD_INVALID, locale)))
        return fail(HttpStatus.BAD_REQUEST, MessageKeys.ERROR_MALFORMED_REQUEST, locale, errors)
    }

    @ExceptionHandler(
        MethodArgumentTypeMismatchException::class,
        MissingServletRequestParameterException::class,
        MissingRequestHeaderException::class,
        MissingServletRequestPartException::class,
        HandlerMethodValidationException::class,
        ConstraintViolationException::class,
    )
    fun handleBadParameter(
        exception: Exception,
        request: HttpServletRequest,
        locale: Locale,
    ): ResponseEntity<BaseResponseBody<Nothing>> {
        log.warn("Bad request parameter on {}: {}", request.requestURI, exception.javaClass.simpleName)
        return fail(HttpStatus.BAD_REQUEST, MessageKeys.ERROR_MALFORMED_REQUEST, locale)
    }

    @ExceptionHandler(NoResourceFoundException::class)
    fun handleNoResource(
        exception: NoResourceFoundException,
        request: HttpServletRequest,
        locale: Locale,
    ): ResponseEntity<BaseResponseBody<Nothing>> {
        log.warn("No resource at {}", request.requestURI)
        return fail(HttpStatus.NOT_FOUND, MessageKeys.ERROR_NOT_FOUND, locale)
    }

    @ExceptionHandler(HttpRequestMethodNotSupportedException::class)
    fun handleMethodNotAllowed(
        exception: HttpRequestMethodNotSupportedException,
        request: HttpServletRequest,
        locale: Locale,
    ): ResponseEntity<BaseResponseBody<Nothing>> {
        log.warn("Method {} not allowed on {}", request.method, request.requestURI)
        return fail(HttpStatus.METHOD_NOT_ALLOWED, MessageKeys.ERROR_METHOD_NOT_ALLOWED, locale)
    }

    @ExceptionHandler(HttpMediaTypeNotSupportedException::class)
    fun handleUnsupportedMediaType(
        exception: HttpMediaTypeNotSupportedException,
        request: HttpServletRequest,
        locale: Locale,
    ): ResponseEntity<BaseResponseBody<Nothing>> {
        log.warn("Unsupported media type on {}", request.requestURI)
        return fail(HttpStatus.UNSUPPORTED_MEDIA_TYPE, MessageKeys.ERROR_UNSUPPORTED_MEDIA_TYPE, locale)
    }

    @ExceptionHandler(HttpMediaTypeNotAcceptableException::class)
    fun handleNotAcceptable(
        exception: HttpMediaTypeNotAcceptableException,
        request: HttpServletRequest,
        locale: Locale,
    ): ResponseEntity<BaseResponseBody<Nothing>> {
        log.warn("Not acceptable on {}", request.requestURI)
        // The client's Accept cannot be honoured, so pin the envelope to JSON instead of failing to render it.
        val body = BaseResponseBody.fail(HttpStatus.NOT_ACCEPTABLE, message(MessageKeys.ERROR_NOT_ACCEPTABLE, locale))
        return ResponseEntity.status(HttpStatus.NOT_ACCEPTABLE).contentType(MediaType.APPLICATION_JSON).body(body)
    }

    @ExceptionHandler(ObjectOptimisticLockingFailureException::class, OptimisticLockException::class)
    fun handleOptimisticLock(
        exception: Exception,
        request: HttpServletRequest,
        locale: Locale,
    ): ResponseEntity<BaseResponseBody<Nothing>> {
        log.warn("Optimistic lock conflict on {}", request.requestURI)
        return fail(HttpStatus.CONFLICT, MessageKeys.ERROR_STALE_VERSION, locale)
    }

    /** The exception message can contain row values (PII), so only the class and path are logged. */
    @ExceptionHandler(DataIntegrityViolationException::class)
    fun handleDataIntegrity(
        exception: DataIntegrityViolationException,
        request: HttpServletRequest,
        locale: Locale,
    ): ResponseEntity<BaseResponseBody<Nothing>> {
        log.warn("Data integrity violation on {}: {}", request.requestURI, exception.javaClass.simpleName)
        return fail(HttpStatus.CONFLICT, MessageKeys.ERROR_DATA_CONFLICT, locale)
    }

    @ExceptionHandler(Exception::class)
    fun handleUnexpected(
        exception: Exception,
        request: HttpServletRequest,
        locale: Locale,
    ): ResponseEntity<BaseResponseBody<Nothing>> {
        // Messages and causes can embed row values (PII): class + path only at error, full stack at debug.
        log.error("Unhandled {} on {}", exception.javaClass.name, request.requestURI)
        log.debug("Stack trace for unhandled exception", exception)
        return fail(HttpStatus.INTERNAL_SERVER_ERROR, MessageKeys.ERROR_GENERIC, locale)
    }

    private fun JacksonException.fieldPath(): String =
        path
            .mapNotNull { it.propertyName }
            .joinToString(".")
}
