import 'package:injectable/injectable.dart';
import 'package:serv_connect_mobile/core/permissions/role_assignment.dart';
import 'package:serv_connect_mobile/core/permissions/scope_type.dart';
import 'package:serv_connect_mobile/core/services/auth_session.dart';

/// Scope-aware permission evaluator (`CLAUDE.md §17.1`).
///
/// Feature code and route guards query [PermissionChecker] by permission key
/// and scope — never by branching on role names.
@lazySingleton
class PermissionChecker {
  PermissionChecker(this._authSession);

  final AuthSession _authSession;

  /// Returns `true` if the user holds [permissionKey] in any assigned scope.
  bool hasAnyScope(String permissionKey) {
    for (final assignment in _authSession.roleAssignments) {
      if (_grantsPermission(assignment, permissionKey)) {
        return true;
      }
    }
    return false;
  }

  /// Returns `true` if the user holds [permissionKey] covering [scopeType] and
  /// [targetId]. An `ORG`-scoped grant covers all stages/groups within the org.
  bool hasPermission(
    String permissionKey, {
    required ScopeType scopeType,
    String? targetId,
  }) {
    for (final assignment in _authSession.roleAssignments) {
      if (_matchesAssignment(assignment, permissionKey, scopeType, targetId)) {
        return true;
      }
    }
    return false;
  }

  bool _matchesAssignment(
    RoleAssignment assignment,
    String permissionKey,
    ScopeType requestedScope,
    String? targetId,
  ) {
    if (!_grantsPermission(assignment, permissionKey)) {
      return false;
    }
    if (assignment.scopeType == ScopeType.org) {
      return true;
    }
    if (assignment.scopeType != requestedScope) {
      return false;
    }
    if (targetId == null || targetId.isEmpty) {
      return true;
    }
    return assignment.scopeTargetId == targetId;
  }

  bool _grantsPermission(RoleAssignment assignment, String permissionKey) {
    return assignment.permissions.contains('*') ||
        assignment.permissions.contains(permissionKey);
  }
}
