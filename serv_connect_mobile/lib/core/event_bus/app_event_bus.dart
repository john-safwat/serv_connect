import 'dart:async';

import 'package:injectable/injectable.dart';

/// Cross-feature broadcast signal bus (`CLAUDE.md §17.2 & §20`).
sealed class AppEvent {
  const AppEvent();
}

class LanguageChangedEvent extends AppEvent {
  const LanguageChangedEvent(this.languageCode);
  final String languageCode;
}

class ScopeRevokedEvent extends AppEvent {
  const ScopeRevokedEvent({required this.scopeType, required this.targetId});
  final String scopeType;
  final String targetId;
}

class SyncCompletedEvent extends AppEvent {
  const SyncCompletedEvent({required this.appliedCount});
  final int appliedCount;
}

class AppForegroundedEvent extends AppEvent {
  const AppForegroundedEvent();
}

@lazySingleton
class AppEventBus {
  AppEventBus() : _controller = StreamController<AppEvent>.broadcast();

  final StreamController<AppEvent> _controller;

  Stream<AppEvent> get stream => _controller.stream;

  Stream<E> on<E extends AppEvent>() =>
      _controller.stream.where((event) => event is E).cast<E>();

  void emit(AppEvent event) {
    if (!_controller.isClosed) {
      _controller.add(event);
    }
  }

  Future<void> close() => _controller.close();
}
