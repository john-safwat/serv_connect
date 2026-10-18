import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:injectable/injectable.dart';
import 'package:__PKG__/core/storage/storage_keys.dart';

/// Facade over `flutter_secure_storage` (Keychain / EncryptedSharedPreferences).
/// Feature code goes through this — the raw plugin is not referenced elsewhere.
@lazySingleton
class SecureStorage {
  SecureStorage()
    : _backing = const FlutterSecureStorage(
        iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
      );

  /// Test-only constructor — pass a mock backing store.
  @visibleForTesting
  SecureStorage.test(FlutterSecureStorage backing) : _backing = backing;

  final FlutterSecureStorage _backing;

  Future<String?> read(StorageKey key) {
    _assertSensitive(key);
    return _backing.read(key: key.value);
  }

  Future<void> write(StorageKey key, String value) {
    _assertSensitive(key);
    return _backing.write(key: key.value, value: value);
  }

  Future<void> delete(StorageKey key) {
    _assertSensitive(key);
    return _backing.delete(key: key.value);
  }

  Future<void> deleteAll() => _backing.deleteAll();

  void _assertSensitive(StorageKey key) {
    if (!key.sensitive) {
      throw ArgumentError(
        'StorageKey ${key.value} is not sensitive — use Preferences instead.',
      );
    }
  }
}
