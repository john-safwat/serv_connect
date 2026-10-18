import 'package:__PKG__/network/errors.dart';

/// The data-layer result envelope. Repositories and UseCases return
/// `Future<ApiResult<T>>`; thrown exceptions never escape the data layer —
/// [safeCall] converts them into [Failure]. Cubits `switch` on this.
sealed class ApiResult<T extends Object?> {
  const ApiResult();
}

class Success<T extends Object?> extends ApiResult<T> {
  const Success(this.data);
  final T? data;
}

class Failure<T extends Object?> extends ApiResult<T> {
  const Failure({required this.message, this.exception});
  final String message;
  final Errors? exception;
}

extension ApiResultX<T extends Object?> on ApiResult<T> {
  ApiResult<T> onSuccess(void Function(T? data) action) {
    if (this is Success<T>) {
      action((this as Success<T>).data);
    }
    return this;
  }

  ApiResult<T> onSuccessNotNull(void Function(T data) action) {
    if (this is Success<T> && (this as Success<T>).data != null) {
      action((this as Success<T>).data as T);
    }
    return this;
  }

  ApiResult<T> onFailure(
    void Function(String message, Errors? exception) action,
  ) {
    if (this is Failure<T>) {
      final f = this as Failure<T>;
      action(f.message, f.exception);
    }
    return this;
  }
}
