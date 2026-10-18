import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

/// Base class for every screen Cubit.
///
/// Replaces Bloc's `Event` API with a single [doAction] entry-point that
/// switches on a sealed `A` (Action) type, and routes one-shot side effects
/// (navigation, toasts, dialogs) through a dedicated `Stream<NE>` instead of
/// leaking `BuildContext` into the Cubit.
///
/// - `T`  — the State (a plain class with a hand-written `copyWith`).
/// - `A`  — the sealed Action union dispatched from the View.
/// - `NE` — the sealed NavigationAction union consumed by the View.
abstract class BaseCubit<T, A, NE> extends Cubit<T> {
  BaseCubit(super.initialState);

  /// Single entry-point for every UI-driven action. Implementations switch
  /// on the sealed `A` type and delegate to a private handler per case.
  Future<void> doAction(A action);

  final StreamController<NE> _navigationStream =
      StreamController<NE>.broadcast();

  /// Consumed by the View in `initState` to react to one-shot effects.
  Stream<NE> get navigation => _navigationStream.stream;

  /// Emit a one-shot navigation/effect event. Never mutates state.
  void emitNavigation(NE navigationEvent) {
    _navigationStream.add(navigationEvent);
  }

  @override
  Future<void> close() async {
    await _navigationStream.close();
    return super.close();
  }
}
