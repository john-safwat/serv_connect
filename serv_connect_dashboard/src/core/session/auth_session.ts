import type { RoleAssignment } from '../permissions/permission_keys';

export interface AuthSessionSnapshot {
  readonly accessToken: string | null;
  readonly userId: string | null;
  readonly orgId: string | null;
  readonly orgTimeZone: string;
  readonly roleAssignments: readonly RoleAssignment[];
  readonly isLocked: boolean;
}

type SessionListener = (snapshot: AuthSessionSnapshot) => void;

const INITIAL_SNAPSHOT: AuthSessionSnapshot = {
  accessToken: null,
  userId: null,
  orgId: null,
  orgTimeZone: 'Africa/Cairo',
  roleAssignments: [],
  isLocked: false,
};

let currentSnapshot: AuthSessionSnapshot = INITIAL_SNAPSHOT;
const listeners = new Set<SessionListener>();

function notifyListeners(): void {
  for (const listener of listeners) {
    listener(currentSnapshot);
  }
}

export const AuthSession = {
  getSnapshot(): AuthSessionSnapshot {
    return currentSnapshot;
  },

  getAccessToken(): string | null {
    return currentSnapshot.accessToken;
  },

  isAuthenticated(): boolean {
    return currentSnapshot.accessToken !== null && !currentSnapshot.isLocked;
  },

  setSession(params: {
    readonly accessToken: string;
    readonly userId: string;
    readonly orgId: string;
    readonly orgTimeZone?: string;
    readonly roleAssignments: readonly RoleAssignment[];
  }): void {
    currentSnapshot = {
      accessToken: params.accessToken,
      userId: params.userId,
      orgId: params.orgId,
      orgTimeZone: params.orgTimeZone ?? 'Africa/Cairo',
      roleAssignments: [...params.roleAssignments],
      isLocked: false,
    };
    notifyListeners();
  },

  updateAccessToken(newAccessToken: string): void {
    if (!currentSnapshot.userId) return;
    currentSnapshot = {
      ...currentSnapshot,
      accessToken: newAccessToken,
      isLocked: false,
    };
    notifyListeners();
  },

  lockSession(): void {
    currentSnapshot = {
      ...INITIAL_SNAPSHOT,
      isLocked: true,
    };
    notifyListeners();
  },

  clear(): void {
    currentSnapshot = INITIAL_SNAPSHOT;
    notifyListeners();
  },

  subscribe(listener: SessionListener): () => void {
    listeners.add(listener);
    return () => {
      listeners.delete(listener);
    };
  },
};
