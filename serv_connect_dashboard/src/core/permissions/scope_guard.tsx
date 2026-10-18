import type React from 'react';
import { FeatureFlagService, type FeatureModuleKey } from '../config/feature_flag_service';
import type { ScopeType } from './permission_keys';
import { usePermissions } from './use_permissions';

export interface ScopeGuardProps {
  readonly perm?: string;
  readonly scopeType?: ScopeType;
  readonly targetId?: string;
  readonly featureModule?: FeatureModuleKey;
  readonly forbiddenFallback: React.ReactNode;
  readonly children: React.ReactNode;
}

export function ScopeGuard({
  perm,
  scopeType,
  targetId,
  featureModule,
  forbiddenFallback,
  children,
}: ScopeGuardProps): React.JSX.Element {
  const checker = usePermissions();
  const featureAllowed = featureModule ? FeatureFlagService.isEnabled(featureModule) : true;
  const permAllowed = !perm
    ? true
    : scopeType
      ? checker.hasPermission(perm, { scopeType, targetId })
      : checker.hasAnyScope(perm);

  if (!featureAllowed || !permAllowed) {
    return <>{forbiddenFallback}</>;
  }
  return <>{children}</>;
}
