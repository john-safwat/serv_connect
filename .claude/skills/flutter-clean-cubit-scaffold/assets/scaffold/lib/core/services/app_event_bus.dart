import 'dart:async';

import 'package:injectable/injectable.dart';

/// Cross-feature signal bus. Carries fire-and-forget events. Subscribers
/// re-read state from storage / repositories on receive — events only signal
/// *that* something happened, not the new state. Add your own [AppEvent]
/// subclasses as the app grows.
sealed class AppEvent {
  const AppEvent();
}

class LanguageChanged extends AppEvent {
  const LanguageChanged(this.languageCode);
  final String languageCode;
}

/// Emitted by the network layer (or [AuthSession]) when the session can no
/// longer be refreshed. The root widget listens and bounces to the login route.
class ForceLogout extends AppEvent {
  const ForceLogout({this.reason});
  final String? reason;
}

class AppForegrounded extends AppEvent {
  const AppForegrounded();
}

class AppBackgrounded extends AppEvent {
  const AppBackgrounded();
}

@lazySingleton
class AppEventBus {
  AppEventBus() : _controller = StreamController<AppEvent>.broadcast();

  final StreamController<AppEvent> _controller;

  Stream<AppEvent> get stream => _controller.stream;

  /// Typed sub-stream, e.g. `bus.on<ForceLogout>().listen(...)`.
  Stream<E> on<E extends AppEvent>() =>
      _controller.stream.where((e) => e is E).cast<E>();

  void emit(AppEvent event) => _controller.add(event);

  Future<void> close() => _controller.close();
}
