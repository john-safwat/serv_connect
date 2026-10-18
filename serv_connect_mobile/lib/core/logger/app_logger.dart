import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';
import 'package:logger/logger.dart';

/// Sanctioned PII-scrubbing logger (`CLAUDE.md §7 & §16.3`).
///
/// Compiles to a no-op in release mode and automatically redacts sensitive
/// keys (`authorization`, `password`, `otp`, `token`, `phone`, `email`,
/// `medical`, `note`) from any logged message.
@singleton
class AppLogger {
  AppLogger()
    : _logger = Logger(
        printer: PrettyPrinter(methodCount: 0, errorMethodCount: 5),
      ),
      _enabled = kDebugMode;

  @visibleForTesting
  AppLogger.test(this._logger) : _enabled = true;

  final Logger _logger;
  final bool _enabled;

  static final RegExp _sensitiveKeyPattern = RegExp(
    r'(authorization|password|otp|token|phone|email|medical|note|name|photo|address|birth)\s*[:=]\s*([^\s,;}\]]+)',
    caseSensitive: false,
  );

  /// Redacts sensitive key-value pairs from [raw] text.
  static String scrub(String raw) {
    return raw.replaceAllMapped(
      _sensitiveKeyPattern,
      (match) => '${match.group(1)}: [REDACTED]',
    );
  }

  void d(Object? message) {
    if (_enabled) _logger.d(scrub(message.toString()));
  }

  void i(Object? message) {
    if (_enabled) _logger.i(scrub(message.toString()));
  }

  void w(Object? message) {
    if (_enabled) _logger.w(scrub(message.toString()));
  }

  void e(Object? message, {Object? error, StackTrace? stackTrace}) {
    if (!_enabled) return;
    final safeError = error == null ? null : scrub(error.toString());
    _logger.e(
      scrub(message.toString()),
      error: safeError,
      stackTrace: stackTrace,
    );
  }
}
