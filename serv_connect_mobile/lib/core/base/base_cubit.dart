import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

/// Base Cubit for all screen and feature controllers.
///
/// User intents enter exclusively via [doAction] switching on a sealed [A]
/// hierarchy; one-shot UI effects (navigation, toasts, bottom sheets) emit
/// through [navigation].
abstract class BaseCubit<T, A, NE> extends Cubit<T> {
  BaseCubit(super.initialState);

  final StreamController<NE> _navigationStream =
      StreamController<NE>.broadcast();

  Stream<NE> get navigation => _navigationStream.stream;

  Future<void> doAction(A action);

  void emitNavigation(NE effect) {
    if (!_navigationStream.isClosed) {
      _navigationStream.add(effect);
    }
  }

  @override
  Future<void> close() async {
    await _navigationStream.close();
    return super.close();
  }
}
