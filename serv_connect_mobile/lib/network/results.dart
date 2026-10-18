import 'package:serv_connect_mobile/network/errors.dart';

/// Domain / data result envelope (`CLAUDE.md §11.1`).
///
/// Never use `Either`, `dartz`, or `fpdart`. Switch exhaustively on [Success]
/// and [Failure].
sealed class ApiResult<T extends Object?> {
  const ApiResult();
}

class Success<T extends Object?> extends ApiResult<T> {
  const Success(this.data);
  final T? data;
}

class Failure<T extends Object?> extends ApiResult<T> {
  const Failure({required this.message, this.exception});
  final Errors? exception;
  final String message;
}
