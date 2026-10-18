import 'dart:async';

import 'package:injectable/injectable.dart';

/// Authentication lifecycle events (`CLAUDE.md §15`).
sealed class AuthBusEvent {
  const AuthBusEvent();
}

/// Emitted when the server explicitly returns 401 on `/api/v1/auth/refresh`
/// or the user signs out.
class ForceLogoutEvent extends AuthBusEvent {
  const ForceLogoutEvent({this.reason});
  final String? reason;
}

/// Emitted when token refresh fails offline and the session transitions to
/// `OfflineGraceExpired` (`FR-1.3`).
class OfflineGraceExpiredEvent extends AuthBusEvent {
  const OfflineGraceExpiredEvent();
}

@lazySingleton
class AuthEventBus {
  AuthEventBus() : _controller = StreamController<AuthBusEvent>.broadcast();

  final StreamController<AuthBusEvent> _controller;

  Stream<AuthBusEvent> get stream => _controller.stream;

  Stream<E> on<E extends AuthBusEvent>() =>
      _controller.stream.where((event) => event is E).cast<E>();

  void emit(AuthBusEvent event) {
    if (!_controller.isClosed) {
      _controller.add(event);
    }
  }

  Future<void> close() => _controller.close();
}
