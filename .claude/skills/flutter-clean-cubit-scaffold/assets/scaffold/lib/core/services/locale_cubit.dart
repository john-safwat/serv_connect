import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:__PKG__/core/services/app_event_bus.dart';

/// Holds the active [Locale] outside the widget tree so `MaterialApp.router`
/// rebuilds on language change. Seeded from `easy_localization`'s restored
/// locale in `bootstrap.dart`; `setLocale` also emits [LanguageChanged] so
/// non-widget subscribers (mappers, cubits) can re-run locale-dependent work.
@lazySingleton
class LocaleCubit extends Cubit<Locale> {
  LocaleCubit(this._eventBus) : super(const Locale('en'));

  final AppEventBus _eventBus;

  void hydrate(Locale locale) => emit(locale);

  void setLocale(Locale locale) {
    if (locale == state) return;
    emit(locale);
    _eventBus.emit(LanguageChanged(locale.languageCode));
  }
}
