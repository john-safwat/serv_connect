/// Sealed error hierarchy for all network, storage, sync, and platform failures
/// (`CLAUDE.md §16.1`).
sealed class Errors {
  const Errors({this.message});
  final String? message;
}

class NetworkError extends Errors {
  const NetworkError({super.message});
}

class TimeoutError extends Errors {
  const TimeoutError({super.message});
}

class ParseError extends Errors {
  const ParseError({super.message, this.cause});
  final Object? cause;
}

class ServerError extends Errors {
  const ServerError({
    required this.statusCode,
    this.code,
    this.fieldErrors = const <String, String>{},
    super.message,
  });

  final int statusCode;
  final String? code;
  final Map<String, String> fieldErrors;
}

class ForbiddenScopeError extends Errors {
  const ForbiddenScopeError({super.message});
}

class FeatureDisabledError extends Errors {
  const FeatureDisabledError({this.featureKey, super.message});
  final String? featureKey;
}

class SyncConflictError extends Errors {
  const SyncConflictError({this.serverCopy, super.message});
  final Map<String, dynamic>? serverCopy;
}

class LoginRequired extends Errors {
  const LoginRequired({this.forceLogout = false, super.message});
  final bool forceLogout;
}

class StorageError extends Errors {
  const StorageError({super.message, this.cause});
  final Object? cause;
}

class PlatformError extends Errors {
  const PlatformError({this.code, super.message});
  final String? code;
}

class JustMessage extends Errors {
  const JustMessage(String message) : super(message: message);
}

class Unknown extends Errors {
  const Unknown({super.message, this.cause});
  final Object? cause;
}
