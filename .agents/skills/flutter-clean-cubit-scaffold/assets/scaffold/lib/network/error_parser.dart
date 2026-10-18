import 'dart:async';

import 'package:dio/dio.dart';
import 'package:__PKG__/network/errors.dart';

/// Maps thrown errors into the [Errors] sealed hierarchy.
///
/// Tune [_fromResponse] to your backend's error envelope. The default assumes
/// a JSON body of the shape `{"status": 401, "message": "SOME_CODE", ...}`
/// where the machine-readable code lives in `message`. Adjust the field
/// priority (`message` / `error` / `msg`) and the code-prefix stripping to
/// match your API.
class ErrorParser {
  const ErrorParser();

  /// Prefix stripped off server error codes so cubits can render
  /// `errors.api.<CODE>` translation keys directly. Set to '' to disable.
  static const _apiCodePrefix = 'API_';

  Errors parse(Object error) {
    if (error is DioException) {
      return _parseDio(error);
    }
    if (error is TimeoutException) {
      return TimeoutError(message: error.message);
    }
    if (error is FormatException) {
      return ParseError(message: error.message, cause: error);
    }
    if (error is Errors) {
      return error;
    }
    return Unknown(message: error.toString(), cause: error);
  }

  Errors _parseDio(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return TimeoutError(message: error.message);
      case DioExceptionType.connectionError:
      case DioExceptionType.badCertificate:
        return NetworkError(message: error.message);
      case DioExceptionType.cancel:
        return Unknown(message: error.message ?? 'Request cancelled');
      case DioExceptionType.unknown:
        if (error.response == null) {
          return NetworkError(message: error.message);
        }
        return _fromResponse(error);
      case DioExceptionType.badResponse:
        return _fromResponse(error);
    }
  }

  Errors _fromResponse(DioException error) {
    final response = error.response;
    final statusCode = response?.statusCode ?? 0;
    final data = response?.data;

    String? rawMessage;
    if (data is Map<String, dynamic>) {
      final raw = data['message'] ?? data['error'] ?? data['msg'];
      if (raw is String && raw.trim().isNotEmpty) {
        rawMessage = raw.trim();
      }
    }

    String? code;
    if (rawMessage != null &&
        _apiCodePrefix.isNotEmpty &&
        rawMessage.startsWith(_apiCodePrefix)) {
      code = rawMessage.substring(_apiCodePrefix.length);
    }

    return ServerError(
      statusCode: statusCode,
      code: code,
      message: rawMessage ?? error.message,
    );
  }
}
