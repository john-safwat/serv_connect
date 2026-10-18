import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:serv_connect_mobile/core/permissions/permission_checker.dart';
import 'package:serv_connect_mobile/core/permissions/permission_keys.dart';
import 'package:serv_connect_mobile/core/permissions/role_assignment.dart';
import 'package:serv_connect_mobile/core/permissions/scope_type.dart';
import 'package:serv_connect_mobile/core/services/auth_session.dart';

class _MockAuthSession extends Mock implements AuthSession {}

void main() {
  late _MockAuthSession authSession;
  late PermissionChecker checker;

  setUp(() {
    authSession = _MockAuthSession();
    checker = PermissionChecker(authSession);
  });

  group('PermissionChecker & RoleAssignment', () {
    test('roleAssignment_jsonRoundTrip_preservesFields', () {
      final assignment = RoleAssignment.fromJson(<String, dynamic>{
        'roleCode': 'SERVANT',
        'scopeType': 'GROUP',
        'scopeTargetId': 'group-uuid-1',
        'permissions': <String>[PermissionKeys.attendanceRecord],
      });
      final json = assignment.toJson();
      expect(json['roleCode'], 'SERVANT');
      expect(json['scopeType'], 'GROUP');
      expect(json['scopeTargetId'], 'group-uuid-1');
    });

    test('hasPermission_inScopeGroup_returnsTrueAndOutOfScopeReturnsFalse', () {
      when(() => authSession.roleAssignments).thenReturn(<RoleAssignment>[
        const RoleAssignment(
          roleCode: 'SERVANT',
          scopeType: ScopeType.group,
          scopeTargetId: 'group-1',
          permissions: <String>{
            PermissionKeys.attendanceRecord,
            PermissionKeys.membersReadSummary,
          },
        ),
      ]);

      expect(checker.hasAnyScope(PermissionKeys.attendanceRecord), isTrue);
      expect(checker.hasAnyScope(PermissionKeys.auditRead), isFalse);
      expect(
        checker.hasPermission(
          PermissionKeys.attendanceRecord,
          scopeType: ScopeType.group,
          targetId: 'group-1',
        ),
        isTrue,
      );
      expect(
        checker.hasPermission(
          PermissionKeys.attendanceRecord,
          scopeType: ScopeType.group,
          targetId: 'group-2',
        ),
        isFalse,
      );
    });

    test('hasPermission_orgScopeGrant_coversAllStagesAndGroups', () {
      when(() => authSession.roleAssignments).thenReturn(<RoleAssignment>[
        const RoleAssignment(
          roleCode: 'ORG_ADMIN',
          scopeType: ScopeType.org,
          permissions: <String>{'*'},
        ),
      ]);

      expect(
        checker.hasPermission(
          PermissionKeys.membersNotesRead,
          scopeType: ScopeType.group,
          targetId: 'any-group-id',
        ),
        isTrue,
      );
    });
  });
}
