import { FeatureModule, type FeatureModuleKey } from '../core/config/feature_flag_service';
import { type LocaleKey, LocaleKeys } from '../generated/locale_keys.g';
import { PermissionKeys } from '../core/permissions/permission_keys';

export interface NavItemConfig {
  readonly key: string;
  readonly path: string;
  readonly labelKey: LocaleKey;
  readonly featureModule?: FeatureModuleKey;
  readonly permissionKey?: string;
  readonly badgeCount?: number;
}

export interface NavGroupConfig {
  readonly groupKey: string;
  readonly titleKey: LocaleKey;
  readonly items: readonly NavItemConfig[];
}

export const SIDEBAR_NAV_GROUPS: readonly NavGroupConfig[] = [
  {
    groupKey: 'main',
    titleKey: LocaleKeys.nav_group_main,
    items: [
      { key: 'overview', path: '/', labelKey: LocaleKeys.nav_overview },
      {
        key: 'schedule',
        path: '/schedule',
        labelKey: LocaleKeys.nav_schedule,
        featureModule: FeatureModule.schedule,
        permissionKey: PermissionKeys.scheduleRead,
      },
      {
        key: 'attendance',
        path: '/attendance',
        labelKey: LocaleKeys.nav_attendance,
        featureModule: FeatureModule.attendance,
        permissionKey: PermissionKeys.attendanceRead,
        badgeCount: 6,
      },
      {
        key: 'tasks',
        path: '/tasks',
        labelKey: LocaleKeys.nav_tasks,
        featureModule: FeatureModule.tasks,
        permissionKey: PermissionKeys.tasksRead,
      },
    ],
  },
  {
    groupKey: 'people',
    titleKey: LocaleKeys.nav_group_people,
    items: [
      {
        key: 'members',
        path: '/members',
        labelKey: LocaleKeys.nav_members,
        featureModule: FeatureModule.members,
        permissionKey: PermissionKeys.membersReadSummary,
      },
      {
        key: 'groups',
        path: '/groups',
        labelKey: LocaleKeys.nav_groups,
        featureModule: FeatureModule.groups,
        permissionKey: PermissionKeys.groupsRead,
      },
    ],
  },
  {
    groupKey: 'service',
    titleKey: LocaleKeys.nav_group_service,
    items: [
      {
        key: 'communication',
        path: '/communication',
        labelKey: LocaleKeys.nav_communication,
        featureModule: FeatureModule.communication,
        permissionKey: PermissionKeys.communicationSend,
      },
      {
        key: 'content',
        path: '/content',
        labelKey: LocaleKeys.nav_content,
        featureModule: FeatureModule.content,
        permissionKey: PermissionKeys.contentRead,
      },
    ],
  },
  {
    groupKey: 'admin',
    titleKey: LocaleKeys.nav_group_admin,
    items: [
      {
        key: 'safeguarding',
        path: '/safeguarding',
        labelKey: LocaleKeys.nav_safeguarding,
        featureModule: FeatureModule.safeguarding,
        permissionKey: PermissionKeys.safeguardingRead,
      },
      {
        key: 'settings',
        path: '/settings',
        labelKey: LocaleKeys.nav_settings,
        featureModule: FeatureModule.admin,
        permissionKey: PermissionKeys.adminSettingsManage,
      },
    ],
  },
];
