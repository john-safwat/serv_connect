package com.example.app.common.exception_handler;

import com.example.app.common.exception.EmailAlreadyRegisteredException;
import com.example.app.common.exception.EntityNotFoundException;
import com.example.app.common.exception.InvalidCredentialsException;
import com.example.app.common.i18n.MessageKeys;
import com.example.app.common.response.BaseResponseBody;
import com.example.app.common.response.FieldError;
import java.util.List;
import java.util.Locale;
import java.util.stream.Collectors;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.context.MessageSource;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.AccessDeniedException;
import org.springframework.security.core.AuthenticationException;
import org.springframework.web.bind.MethodArgumentNotValidException;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.RestControllerAdvice;
import org.springframework.web.context.request.WebRequest;

/**
 * Global handler mapping every thrown exception to a {@link BaseResponseBody.Fail} envelope.
 * The client-facing message is generic and localized; raw messages and stack traces never reach
 * the client — detail is logged server-side only, with the request path (no PHI) as the identifier.
 *
 * <p>Add a handler per domain exception in {@code common/exception/}. Messages resolve from
 * {@code messageSource} using the request {@link Locale}, always passing the English string as the
 * default so a missing key degrades to that text rather than throwing a second exception.
 */
@Slf4j
@RestControllerAdvice
@RequiredArgsConstructor
public class GlobalExceptionHandler {

    private final MessageSource messageSource;

    private String messageFor(String key, String defaultMessage, Locale locale) {
        return messageSource.getMessage(key, null, defaultMessage, locale);
    }

    @ExceptionHandler(Exception.class)
    public ResponseEntity<BaseResponseBody<Object>> handleException(
            Exception exception, WebRequest webRequest, Locale locale) {
        log.error("Unhandled exception on {}", webRequest.getDescription(false), exception);
        return BaseResponseBody.toResponseEntity(BaseResponseBody.fail(
                HttpStatus.INTERNAL_SERVER_ERROR,
                messageFor(MessageKeys.ERROR_UNEXPECTED, "An unexpected error occurred.", locale),
                null));
    }

    @ExceptionHandler(AuthenticationException.class)
    public ResponseEntity<BaseResponseBody<Object>> handleAuthentication(
            Exception exception, WebRequest webRequest, Locale locale) {
        log.warn("Authentication failed on {}: {}", webRequest.getDescription(false), exception.getMessage());
        return BaseResponseBody.toResponseEntity(BaseResponseBody.fail(
                HttpStatus.UNAUTHORIZED,
                messageFor(MessageKeys.ERROR_UNAUTHORIZED, "Authentication failed.", locale),
                null));
    }

    @ExceptionHandler(AccessDeniedException.class)
    public ResponseEntity<BaseResponseBody<Object>> handleAccessDenied(
            Exception exception, WebRequest webRequest, Locale locale) {
        log.warn("Access denied on {}: {}", webRequest.getDescription(false), exception.getMessage());
        return BaseResponseBody.toResponseEntity(BaseResponseBody.fail(
                HttpStatus.FORBIDDEN,
                messageFor(MessageKeys.ERROR_FORBIDDEN,
                        "Access denied: you don't have permission to access this resource.", locale),
                null));
    }

    @ExceptionHandler(InvalidCredentialsException.class)
    public ResponseEntity<BaseResponseBody<Object>> handleInvalidCredentials(
            InvalidCredentialsException exception, WebRequest webRequest, Locale locale) {
        log.warn("Invalid credentials on {}", webRequest.getDescription(false));
        return BaseResponseBody.toResponseEntity(BaseResponseBody.fail(
                HttpStatus.UNAUTHORIZED,
                messageFor(MessageKeys.AUTH_INVALID_CREDENTIALS, "Invalid email or password.", locale),
                null));
    }

    @ExceptionHandler(EmailAlreadyRegisteredException.class)
    public ResponseEntity<BaseResponseBody<Object>> handleEmailAlreadyRegistered(
            EmailAlreadyRegisteredException exception, WebRequest webRequest, Locale locale) {
        log.warn("Duplicate email registration on {}", webRequest.getDescription(false));
        return BaseResponseBody.toResponseEntity(BaseResponseBody.fail(
                HttpStatus.CONFLICT,
                messageFor(MessageKeys.AUTH_EMAIL_ALREADY_REGISTERED,
                        "An account with this email already exists.", locale),
                null));
    }

    @ExceptionHandler(EntityNotFoundException.class)
    public ResponseEntity<BaseResponseBody<Object>> handleEntityNotFound(
            EntityNotFoundException exception, WebRequest webRequest, Locale locale) {
        log.warn("Entity not found on {}", webRequest.getDescription(false));
        return BaseResponseBody.toResponseEntity(BaseResponseBody.fail(
                HttpStatus.NOT_FOUND,
                messageFor(MessageKeys.ERROR_ENTITY_NOT_FOUND, "Resource not found.", locale),
                null));
    }

    @ExceptionHandler(MethodArgumentNotValidException.class)
    public ResponseEntity<BaseResponseBody<Object>> handleValidation(
            MethodArgumentNotValidException exception, WebRequest webRequest, Locale locale) {
        // Each FieldError's defaultMessage is already localized by the validator's interpolator.
        List<FieldError> errors = exception.getBindingResult().getFieldErrors().stream()
                .map(fe -> new FieldError(fe.getField(), fe.getDefaultMessage()))
                .collect(Collectors.toList());
        exception.getBindingResult().getGlobalErrors()
                .forEach(ge -> errors.add(new FieldError("", ge.getDefaultMessage())));
        log.warn("Validation failed on {}: {}", webRequest.getDescription(false), errors);
        return BaseResponseBody.toResponseEntity(BaseResponseBody.fail(
                HttpStatus.BAD_REQUEST,
                messageFor(MessageKeys.ERROR_VALIDATION, "Validation Error", locale),
                errors));
    }
}
