import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:serv_connect_mobile/core/event_bus/app_event_bus.dart';
import 'package:serv_connect_mobile/core/storage/preferences.dart';
import 'package:serv_connect_mobile/core/storage/storage_keys.dart';

/// Holds and persists the active application [Locale] (`ar` or `en`)
/// (`CLAUDE.md §5 & §20`).
@lazySingleton
class LocaleCubit extends Cubit<Locale> {
  LocaleCubit(this._preferences, this._eventBus) : super(const Locale('en'));

  final Preferences _preferences;
  final AppEventBus _eventBus;

  bool get isRtl => state.languageCode == 'ar';
  String get languageCode => state.languageCode;

  void hydrate({Locale? fallback}) {
    final saved = _preferences.getString(StorageKey.appLanguage);
    if (saved == 'ar' || saved == 'en') {
      emit(Locale(saved!));
      return;
    }
    if (fallback != null) {
      emit(Locale(fallback.languageCode == 'ar' ? 'ar' : 'en'));
    }
  }

  Future<void> setLocale(Locale locale) async {
    final normalized = Locale(locale.languageCode == 'ar' ? 'ar' : 'en');
    if (normalized == state) return;
    await _preferences.setString(
      StorageKey.appLanguage,
      normalized.languageCode,
    );
    emit(normalized);
    _eventBus.emit(LanguageChangedEvent(normalized.languageCode));
  }

  Future<void> toggleLocale() async {
    final next = state.languageCode == 'ar'
        ? const Locale('en')
        : const Locale('ar');
    await setLocale(next);
  }
}
