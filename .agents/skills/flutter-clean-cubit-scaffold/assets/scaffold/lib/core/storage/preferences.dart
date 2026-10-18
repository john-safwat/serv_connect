import 'package:__PKG__/core/storage/storage_keys.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Facade over `shared_preferences`. Non-sensitive flags / single values only —
/// language preference, first-run flags, device token. Sensitive data belongs
/// in [SecureStorage].
class Preferences {
  Preferences(this._prefs);

  final SharedPreferences _prefs;

  String? getString(StorageKey key) {
    _assertNotSensitive(key);
    return _prefs.getString(key.value);
  }

  Future<bool> setString(StorageKey key, String value) {
    _assertNotSensitive(key);
    return _prefs.setString(key.value, value);
  }

  bool? getBool(StorageKey key) {
    _assertNotSensitive(key);
    return _prefs.getBool(key.value);
  }

  Future<bool> setBool(StorageKey key, {required bool value}) {
    _assertNotSensitive(key);
    return _prefs.setBool(key.value, value);
  }

  Future<bool> remove(StorageKey key) {
    _assertNotSensitive(key);
    return _prefs.remove(key.value);
  }

  void _assertNotSensitive(StorageKey key) {
    if (key.sensitive) {
      throw ArgumentError(
        'StorageKey ${key.value} is sensitive — use SecureStorage instead.',
      );
    }
  }
}
