import 'dart:convert';

import 'package:injectable/injectable.dart';
import 'package:serv_connect_mobile/core/config/app_environment.dart';
import 'package:serv_connect_mobile/core/event_bus/auth_event_bus.dart';
import 'package:serv_connect_mobile/core/permissions/role_assignment.dart';
import 'package:serv_connect_mobile/core/storage/hive_storage.dart';
import 'package:serv_connect_mobile/core/storage/secure_storage.dart';
import 'package:serv_connect_mobile/core/storage/storage_keys.dart';

/// Authentication & offline grace lifecycle states (`FR-1.3`, `CLAUDE.md §15`).
enum AuthSessionStatus {
  unauthenticated,
  authenticatedOnline,
  authenticatedOffline,
  offlineGraceExpired,
}

/// Manages the active user session, role/scope assignments, and the offline
/// session grace window (`FR-1.3`).
@lazySingleton
class AuthSession {
  AuthSession(
    this._secureStorage,
    this._hiveStorage,
    this._authEventBus,
    this._environment,
  );

  final SecureStorage _secureStorage;
  final HiveStorage _hiveStorage;
  final AuthEventBus _authEventBus;
  final AppEnvironment _environment;

  AuthSessionStatus _status = AuthSessionStatus.unauthenticated;
  String? _accessToken;
  String? _userId;
  String? _orgId;
  DateTime? _lastServerAuthAt;
  List<RoleAssignment> _roleAssignments = const <RoleAssignment>[];
  bool _initialised = false;

  AuthSessionStatus get status => _status;
  String? get accessToken => _accessToken;
  String? get userId => _userId;
  String? get orgId => _orgId;
  DateTime? get lastServerAuthAt => _lastServerAuthAt;
  List<RoleAssignment> get roleAssignments => _roleAssignments;
  bool get isInitialised => _initialised;

  bool get isAuthenticated => _status != AuthSessionStatus.unauthenticated;
  bool get canMutateOffline =>
      _status == AuthSessionStatus.authenticatedOnline ||
      _status == AuthSessionStatus.authenticatedOffline;
  bool get isGraceExpired => _status == AuthSessionStatus.offlineGraceExpired;

  /// Rehydrates session tokens and role assignments from [SecureStorage].
  Future<void> hydrate({DateTime? nowUtc}) async {
    _accessToken = await _secureStorage.read(StorageKey.accessToken);
    final rawAuthAt = await _secureStorage.read(StorageKey.lastServerAuthAt);
    final rawSession = await _secureStorage.read(StorageKey.userSessionJson);
    _lastServerAuthAt = _parseUtc(rawAuthAt);
    _restoreUserSession(rawSession);
    _evaluateStatus(nowUtc: nowUtc ?? DateTime.now().toUtc(), isOnline: true);
    _initialised = true;
  }

  /// Persists a freshly authenticated session from the backend.
  Future<void> signIn({
    required String accessToken,
    required String refreshToken,
    required String userId,
    required String orgId,
    required List<RoleAssignment> assignments,
    DateTime? authenticatedAtUtc,
  }) async {
    final authInstant = (authenticatedAtUtc ?? DateTime.now()).toUtc();
    await _writeTokens(accessToken, refreshToken, authInstant);
    await _writeSessionSnapshot(userId, orgId, assignments);
    _accessToken = accessToken;
    _userId = userId;
    _orgId = orgId;
    _roleAssignments = List<RoleAssignment>.unmodifiable(assignments);
    _lastServerAuthAt = authInstant;
    _status = AuthSessionStatus.authenticatedOnline;
  }

  /// Updates tokens after a successful `/api/v1/auth/refresh` rotation.
  Future<void> updateTokens({
    required String accessToken,
    required String refreshToken,
    DateTime? refreshedAtUtc,
  }) async {
    final authInstant = (refreshedAtUtc ?? DateTime.now()).toUtc();
    await _writeTokens(accessToken, refreshToken, authInstant);
    _accessToken = accessToken;
    _lastServerAuthAt = authInstant;
    _status = AuthSessionStatus.authenticatedOnline;
  }

  /// Evaluates the offline grace window when token refresh fails due to a
  /// network, timeout, or 5xx error (`FR-1.3`). Never wipes the outbox!
  Future<AuthSessionStatus> handleOfflineRefreshFailure({
    DateTime? nowUtc,
  }) async {
    _evaluateStatus(
      nowUtc: (nowUtc ?? DateTime.now()).toUtc(),
      isOnline: false,
    );
    if (_status == AuthSessionStatus.offlineGraceExpired) {
      await _hiveStorage.clearSensitiveRecords();
      _authEventBus.emit(const OfflineGraceExpiredEvent());
    }
    return _status;
  }

  /// Signs out and clears credentials while preserving unsynced outbox items.
  Future<void> signOut({bool forceLogout = false, String? reason}) async {
    await _secureStorage.delete(StorageKey.accessToken);
    await _secureStorage.delete(StorageKey.refreshToken);
    await _secureStorage.delete(StorageKey.userSessionJson);
    await _secureStorage.delete(StorageKey.lastServerAuthAt);
    await _hiveStorage.clearUserScopePreservingOutbox();
    _clearInMemory();
    if (forceLogout) {
      _authEventBus.emit(ForceLogoutEvent(reason: reason));
    }
  }

  void _evaluateStatus({required DateTime nowUtc, required bool isOnline}) {
    final hasToken = _accessToken != null && _accessToken!.isNotEmpty;
    if (!hasToken || _lastServerAuthAt == null) {
      _status = AuthSessionStatus.unauthenticated;
      return;
    }
    final elapsed = nowUtc.difference(_lastServerAuthAt!);
    final graceWindow = Duration(days: _environment.defaultOfflineGraceDays);
    if (elapsed > graceWindow) {
      _status = AuthSessionStatus.offlineGraceExpired;
      return;
    }
    _status = isOnline
        ? AuthSessionStatus.authenticatedOnline
        : AuthSessionStatus.authenticatedOffline;
  }

  Future<void> _writeTokens(
    String access,
    String refresh,
    DateTime authInstant,
  ) async {
    await _secureStorage.write(StorageKey.accessToken, access);
    await _secureStorage.write(StorageKey.refreshToken, refresh);
    await _secureStorage.write(
      StorageKey.lastServerAuthAt,
      authInstant.toIso8601String(),
    );
  }

  Future<void> _writeSessionSnapshot(
    String userId,
    String orgId,
    List<RoleAssignment> assignments,
  ) async {
    final payload = jsonEncode(<String, dynamic>{
      'userId': userId,
      'orgId': orgId,
      'assignments': assignments.map((item) => item.toJson()).toList(),
    });
    await _secureStorage.write(StorageKey.userSessionJson, payload);
  }

  void _restoreUserSession(String? rawSession) {
    if (rawSession == null || rawSession.isEmpty) return;
    final decoded = jsonDecode(rawSession) as Map<String, dynamic>;
    _userId = decoded['userId'] as String?;
    _orgId = decoded['orgId'] as String?;
    final rawList =
        decoded['assignments'] as List<dynamic>? ?? const <dynamic>[];
    _roleAssignments = rawList
        .whereType<Map<String, dynamic>>()
        .map(RoleAssignment.fromJson)
        .toList(growable: false);
  }

  DateTime? _parseUtc(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    return DateTime.tryParse(raw)?.toUtc();
  }

  void _clearInMemory() {
    _accessToken = null;
    _userId = null;
    _orgId = null;
    _lastServerAuthAt = null;
    _roleAssignments = const <RoleAssignment>[];
    _status = AuthSessionStatus.unauthenticated;
  }
}
