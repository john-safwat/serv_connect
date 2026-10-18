export const FeatureModule = {
  identity: 'identity',
  members: 'members',
  groups: 'groups',
  schedule: 'schedule',
  attendance: 'attendance',
  tasks: 'tasks',
  communication: 'communication',
  curriculum: 'curriculum',
  content: 'content',
  engagement: 'engagement',
  trips: 'trips',
  notifications: 'notifications',
  safeguarding: 'safeguarding',
  audit: 'audit',
  analytics: 'analytics',
  prayer: 'prayer',
  admin: 'admin',
} as const;

export type FeatureModuleKey = (typeof FeatureModule)[keyof typeof FeatureModule];

const DEFAULT_ENABLED_MODULES: ReadonlySet<FeatureModuleKey> = new Set([
  FeatureModule.identity,
  FeatureModule.members,
  FeatureModule.groups,
  FeatureModule.schedule,
  FeatureModule.attendance,
  FeatureModule.tasks,
  FeatureModule.communication,
  FeatureModule.content,
  FeatureModule.notifications,
  FeatureModule.safeguarding,
  FeatureModule.audit,
  FeatureModule.admin,
]);

let activeFlags: Readonly<Partial<Record<FeatureModuleKey, boolean>>> = {};

export const FeatureFlagService = {
  isEnabled(moduleKey: FeatureModuleKey): boolean {
    const explicit = activeFlags[moduleKey];
    if (typeof explicit === 'boolean') return explicit;
    return DEFAULT_ENABLED_MODULES.has(moduleKey);
  },
  setFlags(flags: Readonly<Partial<Record<FeatureModuleKey, boolean>>>): void {
    activeFlags = { ...flags };
  },
  resetToDefaults(): void {
    activeFlags = {};
  },
};
