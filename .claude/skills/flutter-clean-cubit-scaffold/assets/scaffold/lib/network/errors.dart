/// The single error hierarchy for the whole app. Every failure — network,
/// server, parse, auth — is represented as an [Errors] subclass, never a raw
/// `Exception` / `DioException`. Plain Dart sealed classes, no freezed.
sealed class Errors implements Exception {
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
  const ServerError({required this.statusCode, this.code, super.message});
  final int statusCode;
  final String? code;
}

/// Emitted by the network layer when the session can no longer be refreshed.
/// The routing layer listens for this and bounces the user to the login route.
class LoginRequired extends Errors {
  const LoginRequired({this.forceLogout = false, super.message});
  final bool forceLogout;
}

/// A raw server message surfaced verbatim to the user (already localised or
/// not translatable). Keep these rare.
class JustMessage extends Errors {
  const JustMessage(String message) : super(message: message);
}

class Unknown extends Errors {
  const Unknown({super.message, this.cause});
  final Object? cause;
}
