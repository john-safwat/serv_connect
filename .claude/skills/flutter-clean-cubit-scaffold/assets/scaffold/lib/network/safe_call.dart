import 'dart:async';

import 'package:dio/dio.dart';
import 'package:__PKG__/core/logger/app_logger.dart';
import 'package:__PKG__/di/di.dart';
import 'package:__PKG__/network/error_parser.dart';
import 'package:__PKG__/network/errors.dart';
import 'package:__PKG__/network/results.dart';

const _defaultParser = ErrorParser();

/// Wraps a data-source call so thrown exceptions become [Failure] instead of
/// escaping the data layer. Every RepositoryImpl method body is
/// `return safeCall(() async => dataSource.x(...));`.
Future<ApiResult<T>> safeCall<T>(
  Future<T> Function() block, {
  ErrorParser parser = _defaultParser,
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
    return _toFailure<T>(parser, e, fallback: 'Timeout');
  } on Errors catch (e) {
    return Failure<T>(exception: e, message: e.message ?? 'Error');
  } on Object catch (e, st) {
    _logUnexpected('safeCall Unknown(${e.runtimeType})', e, st);
    return _toFailure<T>(parser, e, fallback: 'Unknown error');
  }
}

void _logUnexpected(String tag, Object error, StackTrace stack) {
  if (!getIt.isRegistered<AppLogger>()) return;
  getIt<AppLogger>().e(tag, error: error, stackTrace: stack);
}

Failure<T> _toFailure<T>(
  ErrorParser parser,
  Object error, {
  required String fallback,
}) {
  final parsed = parser.parse(error);
  return Failure<T>(exception: parsed, message: parsed.message ?? fallback);
}
