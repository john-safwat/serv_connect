import { render, screen } from '@testing-library/react';
import { describe, expect, it, vi } from 'vitest';
import { FeatureFlagService, FeatureModule } from '../config/feature_flag_service';
import { AuthEventBus } from '../event_bus/auth_event_bus';
import { PermissionChecker } from '../permissions/permission_checker';
import { PermissionKeys, type RoleAssignment } from '../permissions/permission_keys';
import { RequirePermission } from '../permissions/RequirePermission';
import { ScopeGuard } from '../permissions/scope_guard';
import { AuthSession } from './auth_session';
import { IdleLockWatcher } from './idle_lock_watcher';

const SAMPLE_ASSIGNMENTS: readonly RoleAssignment[] = [
  {
    id: 'role-1',
    roleName: 'STAGE_COORDINATOR',
    scopeType: 'STAGE',
    scopeTargetId: 'stage-primary-uuid',
    permissions: [PermissionKeys.membersReadFull, PermissionKeys.groupsAssignServants],
  },
];

describe('AuthSession, IdleLockWatcher & Permission/Scope Guards', () => {
  it('authSession_storesAccessTokenInMemoryOnly_neverWritesBrowserStorage', () => {
    AuthSession.setSession({
      accessToken: 'in-memory-jwt-token',
      userId: '00000000-0000-4000-8000-000000000001',
      orgId: '00000000-0000-4000-8000-000000000099',
      roleAssignments: SAMPLE_ASSIGNMENTS,
    });
    expect(AuthSession.isAuthenticated()).toBe(true);
    expect(AuthSession.getAccessToken()).toBe('in-memory-jwt-token');
    expect(window.localStorage.getItem('accessToken')).toBeNull();
    expect(window.sessionStorage.getItem('accessToken')).toBeNull();
  });

  it('idleLockWatcher_wallClockExpiry_locksSessionAndEmitsIdleLockEvent', () => {
    let nowMs = 1_000_000;
    const onLock = vi.fn();
    const events: string[] = [];
    AuthEventBus.subscribe((e) => events.push(e.type));
    AuthSession.setSession({
      accessToken: 'jwt-1',
      userId: 'u-1',
      orgId: 'o-1',
      roleAssignments: SAMPLE_ASSIGNMENTS,
    });

    const watcher = new IdleLockWatcher({
      timeoutMinutes: 15,
      onLock,
      nowProvider: () => nowMs,
    });
    watcher.start();
    nowMs += 10 * 60 * 1000;
    expect(watcher.evaluateTick()).toBe(false);
    watcher.recordActivity();
    nowMs += 10 * 60 * 1000;
    expect(watcher.evaluateTick()).toBe(false);
    nowMs += 6 * 60 * 1000;
    expect(watcher.evaluateTick()).toBe(true);
    expect(AuthSession.isAuthenticated()).toBe(false);
    expect(AuthSession.getSnapshot().isLocked).toBe(true);
    expect(onLock).toHaveBeenCalledTimes(1);
    expect(events).toContain('IDLE_LOCK');
    watcher.stop();
  });

  it('permissionChecker_evaluatesScopedAndOrgPermissions_withoutRoleBranching', () => {
    const checker = new PermissionChecker(SAMPLE_ASSIGNMENTS);
    expect(checker.hasAnyScope(PermissionKeys.membersReadFull)).toBe(true);
    expect(checker.hasAnyScope(PermissionKeys.auditRead)).toBe(false);
    expect(
      checker.hasPermission(PermissionKeys.groupsAssignServants, {
        scopeType: 'STAGE',
        targetId: 'stage-primary-uuid',
      }),
    ).toBe(true);
    expect(
      checker.hasPermission(PermissionKeys.groupsAssignServants, {
        scopeType: 'STAGE',
        targetId: 'stage-other-uuid',
      }),
    ).toBe(false);
    expect(checker.getAllowedTargets(PermissionKeys.membersReadFull, 'STAGE')).toEqual([
      'stage-primary-uuid',
    ]);
  });

  it('requirePermissionAndScopeGuard_hideOutOfScopeAndDisabledModules', () => {
    AuthSession.setSession({
      accessToken: 'jwt-1',
      userId: 'u-1',
      orgId: 'o-1',
      roleAssignments: SAMPLE_ASSIGNMENTS,
    });

    render(
      <div>
        <RequirePermission
          perm={PermissionKeys.groupsAssignServants}
          scopeType="STAGE"
          targetId="stage-primary-uuid"
        >
          <span>InScopeAction</span>
        </RequirePermission>
        <RequirePermission
          perm={PermissionKeys.groupsAssignServants}
          scopeType="STAGE"
          targetId="stage-unauthorized"
          fallback={<span>DeniedFallback</span>}
        >
          <span>SecretAction</span>
        </RequirePermission>
        <ScopeGuard
          perm={PermissionKeys.auditRead}
          featureModule={FeatureModule.audit}
          forbiddenFallback={<span>ForbiddenView</span>}
        >
          <span>AuditContent</span>
        </ScopeGuard>
      </div>,
    );

    expect(screen.getByText('InScopeAction')).toBeInTheDocument();
    expect(screen.queryByText('SecretAction')).not.toBeInTheDocument();
    expect(screen.getByText('DeniedFallback')).toBeInTheDocument();
    expect(screen.getByText('ForbiddenView')).toBeInTheDocument();

    FeatureFlagService.setFlags({ [FeatureModule.members]: false });
    render(
      <ScopeGuard
        featureModule={FeatureModule.members}
        forbiddenFallback={<span>ModuleDisabledView</span>}
      >
        <span>MembersView</span>
      </ScopeGuard>,
    );
    expect(screen.getByText('ModuleDisabledView')).toBeInTheDocument();
  });
});
