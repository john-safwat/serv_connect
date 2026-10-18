import type { RoleAssignment, ScopeTarget, ScopeType } from './permission_keys';

function matchesScope(assignment: RoleAssignment, requiredScope?: ScopeTarget): boolean {
  if (!requiredScope) return true;
  if (assignment.scopeType === 'ORG') return true;
  if (assignment.scopeType !== requiredScope.scopeType) return false;
  if (!requiredScope.targetId) return true;
  return assignment.scopeTargetId === requiredScope.targetId;
}

function matchesPermission(assignment: RoleAssignment, permissionKey: string): boolean {
  return assignment.permissions.includes(permissionKey) || assignment.permissions.includes('*');
}

export class PermissionChecker {
  private readonly assignments: readonly RoleAssignment[];

  public constructor(assignments: readonly RoleAssignment[]) {
    this.assignments = assignments;
  }

  public hasAnyScope(permissionKey: string): boolean {
    return this.assignments.some((a) => matchesPermission(a, permissionKey));
  }

  public hasPermission(permissionKey: string, requiredScope?: ScopeTarget): boolean {
    return this.assignments.some(
      (a) => matchesPermission(a, permissionKey) && matchesScope(a, requiredScope),
    );
  }

  public getAllowedTargets(permissionKey: string, scopeType: ScopeType): readonly string[] {
    const targets: string[] = [];
    for (const assignment of this.assignments) {
      if (!matchesPermission(assignment, permissionKey)) continue;
      if (assignment.scopeType === scopeType && assignment.scopeTargetId) {
        targets.push(assignment.scopeTargetId);
      }
    }
    return targets;
  }
}
