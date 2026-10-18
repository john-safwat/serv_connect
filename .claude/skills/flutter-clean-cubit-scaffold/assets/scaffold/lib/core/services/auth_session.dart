import 'package:injectable/injectable.dart';
import 'package:__PKG__/core/services/app_event_bus.dart';
import 'package:__PKG__/core/storage/preferences.dart';
import 'package:__PKG__/core/storage/secure_storage.dart';
import 'package:__PKG__/core/storage/storage_keys.dart';

/// Singleton session state. Read by `AuthGuard` to decide route protection;
/// written by `AuthRepositoryImpl` after login/logout. The user payload is
/// held as raw JSON — wrap it in a typed model as the auth feature grows.
@lazySingleton
class AuthSession {
  AuthSession({
    required SecureStorage secureStorage,
    required AppEventBus eventBus,
    required Preferences preferences,
  }) : _secureStorage = secureStorage,
       _eventBus = eventBus,
       _preferences = preferences;

  final SecureStorage _secureStorage;
  final AppEventBus _eventBus;
  final Preferences _preferences;

  String? _accessToken;
  String? _userJson;
  bool _initialised = false;

  bool get isAuthenticated =>
      (_accessToken?.isNotEmpty ?? false) && (_userJson?.isNotEmpty ?? false);

  String? get accessToken => _accessToken;
  String? get userJson => _userJson;
  bool get isInitialised => _initialised;

  /// Hydrates from [SecureStorage]. Called once during bootstrap before
  /// `runApp`.
  Future<void> hydrate() async {
    _accessToken = await _secureStorage.read(StorageKey.accessToken);
    _userJson = await _secureStorage.read(StorageKey.user);
    _initialised = true;
  }

  Future<void> signIn({
    required String accessToken,
    required String refreshToken,
    required String userJson,
  }) async {
    await _secureStorage.write(StorageKey.accessToken, accessToken);
    await _secureStorage.write(StorageKey.refreshToken, refreshToken);
    await _secureStorage.write(StorageKey.user, userJson);
    _accessToken = accessToken;
    _userJson = userJson;
  }

  Future<void> signOut({bool forceLogout = false, String? reason}) async {
    await _secureStorage.delete(StorageKey.accessToken);
    await _secureStorage.delete(StorageKey.refreshToken);
    await _secureStorage.delete(StorageKey.user);
    await _preferences.remove(StorageKey.deviceToken);
    _accessToken = null;
    _userJson = null;
    if (forceLogout) {
      _eventBus.emit(ForceLogout(reason: reason));
    }
  }
}
