import 'package:injectable/injectable.dart';
import 'package:__PKG__/core/storage/preferences.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Bindings that need factory methods (async or constructor-arg-driven).
/// Pure-class bindings (`SecureStorage`, `HiveStorage`) live next to their
/// implementations with `@lazySingleton` annotations.
@module
abstract class StorageModule {
  @preResolve
  @lazySingleton
  Future<SharedPreferences> sharedPreferences() =>
      SharedPreferences.getInstance();

  @lazySingleton
  Preferences preferences(SharedPreferences prefs) => Preferences(prefs);
}
