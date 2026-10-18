import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';
import 'package:logger/logger.dart';

/// The only sanctioned logger. Wraps `package:logger` and compiles to a no-op
/// in release mode. Never use `print` / `debugPrint` in feature code.
@singleton
class AppLogger {
  AppLogger()
    : _logger = Logger(
        printer: PrettyPrinter(methodCount: 0, errorMethodCount: 8),
      );

  final Logger _logger;

  void d(Object? message) {
    if (kDebugMode) _logger.d(message);
  }

  void i(Object? message) {
    if (kDebugMode) _logger.i(message);
  }

  void w(Object? message) {
    if (kDebugMode) _logger.w(message);
  }

  void e(Object? message, {Object? error, StackTrace? stackTrace}) {
    if (kDebugMode) _logger.e(message, error: error, stackTrace: stackTrace);
  }
}
