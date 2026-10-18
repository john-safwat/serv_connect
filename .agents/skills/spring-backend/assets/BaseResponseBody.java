package com.example.app.common.response;

import com.fasterxml.jackson.annotation.JsonInclude;
import java.util.List;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;

/**
 * Closed hierarchy of response bodies returned by every controller and the global exception
 * handler, plus the static factories used to build them. {@link Success} carries the response
 * data; {@link Fail} carries an optional list of field/bean-validation error messages.
 *
 * <p>The permitted subtypes are fixed at compile time via {@code sealed} — adding a new response
 * shape is a deliberate, reviewed change rather than something any controller can introduce.
 *
 * <p>{@link JsonInclude.Include#NON_NULL} keeps optional fields off the wire: a success with no
 * data serialises as {@code {code, status, message}}; a fail with no errors omits the array.
 * There is deliberately no 204 path — a void success is a {@link Success} with {@code data == null}.
 */
@JsonInclude(JsonInclude.Include.NON_NULL)
public sealed interface BaseResponseBody<T> permits BaseResponseBody.Success, BaseResponseBody.Fail {

    int code();

    HttpStatus status();

    String message();

    static <T> Success<T> success(T data, String message, HttpStatus status) {
        return new Success<>(status.value(), status, message, data);
    }

    static <T> Fail<T> fail(HttpStatus status, String message, List<FieldError> errors) {
        return new Fail<>(status.value(), status, message, errors);
    }

    static <T> ResponseEntity<BaseResponseBody<T>> toResponseEntity(BaseResponseBody<T> body) {
        return ResponseEntity.status(body.status()).body(body);
    }

    /** Shared fields + fluent setters for the per-record builders. */
    abstract class Builder<T, B extends Builder<T, B>> {
        protected int code;
        protected HttpStatus status;
        protected String message;

        @SuppressWarnings("unchecked")
        private B self() {
            return (B) this;
        }

        public B code(int code) {
            this.code = code;
            return self();
        }

        public B status(HttpStatus status) {
            this.status = status;
            return self();
        }

        public B message(String message) {
            this.message = message;
            return self();
        }

        public abstract BaseResponseBody<T> build();

        public final ResponseEntity<BaseResponseBody<T>> toResponseEntity() {
            return BaseResponseBody.toResponseEntity(build());
        }
    }

    /** A successful response. {@code data} is null only for no-content-style successes. */
    record Success<T>(int code, HttpStatus status, String message, T data) implements BaseResponseBody<T> {

        public static <T> Builder<T> builder() {
            return Builder.builder();
        }

        public static final class Builder<T> extends BaseResponseBody.Builder<T, Builder<T>> {
            private T data;

            private Builder() {
            }

            public static <T> Builder<T> builder() {
                return new Builder<>();
            }

            public Builder<T> data(T data) {
                this.data = data;
                return this;
            }

            @Override
            public Success<T> build() {
                return new Success<>(code, status, message, data);
            }
        }
    }

    /** A failed response. {@code errors} carries field/bean-validation messages when available. */
    record Fail<T>(int code, HttpStatus status, String message, List<FieldError> errors) implements BaseResponseBody<T> {

        public static <T> Builder<T> builder() {
            return Builder.builder();
        }

        public static final class Builder<T> extends BaseResponseBody.Builder<T, Builder<T>> {
            private List<FieldError> errors;

            private Builder() {
            }

            public static <T> Builder<T> builder() {
                return new Builder<>();
            }

            public Builder<T> errors(List<FieldError> errors) {
                this.errors = errors;
                return this;
            }

            @Override
            public Fail<T> build() {
                return new Fail<>(code, status, message, errors);
            }
        }
    }
}
