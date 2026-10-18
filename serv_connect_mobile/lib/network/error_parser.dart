import 'dart:async';

import 'package:dio/dio.dart';
import 'package:hive_ce/hive.dart';
import 'package:serv_connect_mobile/network/errors.dart';

/// Maps thrown exceptions and HTTP error envelopes into the sealed [Errors]
/// hierarchy (`CLAUDE.md §16.1`).
class ErrorParser {
  const ErrorParser();

  Errors parse(Object error) {
    if (error is Errors) return error;
    if (error is DioException) return _parseDio(error);
    if (error is TimeoutException) return TimeoutError(message: error.message);
    if (error is FormatException) {
      return ParseError(message: error.message, cause: error);
    }
    if (error is HiveError) {
      return StorageError(message: error.message, cause: error);
    }
    return Unknown(message: error.toString(), cause: error);
  }

  Errors _parseDio(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.transformTimeout:
        return TimeoutError(message: error.message);
      case DioExceptionType.connectionError:
      case DioExceptionType.badCertificate:
        return NetworkError(message: error.message);
      case DioExceptionType.cancel:
        return Unknown(message: error.message ?? 'Request cancelled');
      case DioExceptionType.unknown:
        return error.response == null
            ? NetworkError(message: error.message)
            : _fromResponse(error);
      case DioExceptionType.badResponse:
        return _fromResponse(error);
    }
  }

  Errors _fromResponse(DioException error) {
    final response = error.response;
    final statusCode = response?.statusCode ?? 0;
    final map = response?.data is Map<String, dynamic>
        ? response!.data as Map<String, dynamic>
        : const <String, dynamic>{};
    final message = _extractMessage(map) ?? error.message;
    final code = map['code'] as String?;

    if (statusCode == 401) {
      return LoginRequired(message: message);
    }
    if (statusCode == 403) {
      return _parseForbidden(code: code, map: map, message: message);
    }
    if (statusCode == 409 && code == 'ERR_SYNC_CONFLICT') {
      final serverCopy = map['data'] is Map<String, dynamic>
          ? map['data'] as Map<String, dynamic>
          : null;
      return SyncConflictError(serverCopy: serverCopy, message: message);
    }
    return ServerError(
      statusCode: statusCode,
      code: code,
      fieldErrors: _extractFieldErrors(map),
      message: message,
    );
  }

  Errors _parseForbidden({
    required String? code,
    required Map<String, dynamic> map,
    required String? message,
  }) {
    if (code == 'ERR_FEATURE_DISABLED') {
      return FeatureDisabledError(
        featureKey: map['featureKey'] as String?,
        message: message,
      );
    }
    return ForbiddenScopeError(message: message);
  }

  String? _extractMessage(Map<String, dynamic> map) {
    final raw = map['message'] ?? map['error'];
    if (raw is String && raw.trim().isNotEmpty) {
      return raw.trim();
    }
    return null;
  }

  Map<String, String> _extractFieldErrors(Map<String, dynamic> map) {
    final raw = map['fieldErrors'];
    if (raw is! Map) return const <String, String>{};
    return raw.map((key, value) => MapEntry(key.toString(), value.toString()));
  }
}
