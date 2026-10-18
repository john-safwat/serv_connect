import type React from 'react';
import type { ScopeType } from './permission_keys';
import { usePermissions } from './use_permissions';

export interface RequirePermissionProps {
  readonly perm: string;
  readonly scopeType?: ScopeType;
  readonly targetId?: string;
  readonly fallback?: React.ReactNode;
  readonly children: React.ReactNode;
}

export function RequirePermission({
  perm,
  scopeType,
  targetId,
  fallback = null,
  children,
}: RequirePermissionProps): React.JSX.Element {
  const checker = usePermissions();
  const allowed = scopeType
    ? checker.hasPermission(perm, { scopeType, targetId })
    : checker.hasAnyScope(perm);

  return <>{allowed ? children : fallback}</>;
}
