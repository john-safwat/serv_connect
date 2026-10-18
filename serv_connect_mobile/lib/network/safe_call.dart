import 'dart:async';

import 'package:dio/dio.dart';
import 'package:serv_connect_mobile/core/logger/app_logger.dart';
import 'package:serv_connect_mobile/di/injection.dart';
import 'package:serv_connect_mobile/network/error_parser.dart';
import 'package:serv_connect_mobile/network/errors.dart';
import 'package:serv_connect_mobile/network/results.dart';

const ErrorParser _defaultErrorParser = ErrorParser();

/// Safely executes an asynchronous repository/datasource operation and maps any
/// thrown exception into a typed [Failure] (`CLAUDE.md §11`).
Future<ApiResult<T>> safeCall<T>(
  Future<T> Function() block, {
  ErrorParser parser = _defaultErrorParser,
}) async {
  try {
    final value = await block();
    return Success<T>(value);
  } on DioException catch (e) {
    return _toFailure<T>(parser, e, fallback: 'Network error');
  } on FormatException catch (e, st) {
    _logUnexpected('safeCall FormatException', e, st);
    return _toFailure<T>(parser, e, fallback: 'Parse error');
  } on TimeoutException catch (e) {
    return _toFailure<T>(parser, e, fallback: 'Request timed out');
  } on Errors catch (e) {
    return Failure<T>(exception: e, message: e.message ?? 'Operation failed');
  } on Object catch (e, st) {
    _logUnexpected('safeCall (${e.runtimeType})', e, st);
    return _toFailure<T>(parser, e, fallback: 'Unexpected error');
  }
}

void _logUnexpected(String tag, Object error, StackTrace stackTrace) {
  if (!getIt.isRegistered<AppLogger>()) return;
  getIt<AppLogger>().e(tag, error: error, stackTrace: stackTrace);
}

Failure<T> _toFailure<T>(
  ErrorParser parser,
  Object error, {
  required String fallback,
}) {
  final parsed = parser.parse(error);
  return Failure<T>(exception: parsed, message: parsed.message ?? fallback);
}
