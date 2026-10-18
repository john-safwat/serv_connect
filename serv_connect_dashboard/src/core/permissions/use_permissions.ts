import { useSyncExternalStore } from 'react';
import { AuthSession } from '../session/auth_session';
import { PermissionChecker } from './permission_checker';

export function usePermissions(): PermissionChecker {
  const snapshot = useSyncExternalStore(AuthSession.subscribe, AuthSession.getSnapshot);
  return new PermissionChecker(snapshot.roleAssignments);
}
