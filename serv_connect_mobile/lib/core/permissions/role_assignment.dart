import 'package:serv_connect_mobile/core/permissions/scope_type.dart';

/// Represents a single role assignment granted to the signed-in user within a
/// specific [ScopeType] and optional [scopeTargetId] (`CLAUDE.md §17.1`).
class RoleAssignment {
  const RoleAssignment({
    required this.roleCode,
    required this.scopeType,
    required this.permissions,
    this.scopeTargetId,
  });

  factory RoleAssignment.fromJson(Map<String, dynamic> json) {
    final rawPerms = json['permissions'] as List<dynamic>? ?? const <dynamic>[];
    return RoleAssignment(
      roleCode: json['roleCode'] as String? ?? '',
      scopeType: ScopeType.fromWire(json['scopeType'] as String? ?? 'SELF'),
      scopeTargetId: json['scopeTargetId'] as String?,
      permissions: rawPerms.map((item) => item.toString()).toSet(),
    );
  }

  final String roleCode;
  final ScopeType scopeType;
  final String? scopeTargetId;
  final Set<String> permissions;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'roleCode': roleCode,
      'scopeType': scopeType.wireValue,
      'scopeTargetId': scopeTargetId,
      'permissions': permissions.toList(),
    };
  }
}
