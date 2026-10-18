export type ScopeType = 'ORG' | 'STAGE' | 'GROUP' | 'SELF' | 'CHILDREN';

export interface ScopeTarget {
  readonly scopeType: ScopeType;
  readonly targetId?: string;
}

export interface RoleAssignment {
  readonly id: string;
  readonly roleName: string;
  readonly scopeType: ScopeType;
  readonly scopeTargetId?: string;
  readonly permissions: readonly string[];
}

export const PermissionKeys = {
  overviewRead: 'overview.read',
  membersReadSummary: 'members.read.summary',
  membersReadFull: 'members.read.full',
  membersWrite: 'members.write',
  membersNotesRead: 'members.notes.read',
  membersNotesWrite: 'members.notes.write',
  groupsRead: 'groups.read',
  groupsWrite: 'groups.write',
  groupsAssignServants: 'groups.assign-servants',
  groupsPromote: 'groups.promote',
  scheduleRead: 'schedule.read',
  scheduleWrite: 'schedule.write',
  attendanceRead: 'attendance.read',
  attendanceFollowUpManage: 'attendance.followup.manage',
  tasksRead: 'tasks.read',
  tasksWrite: 'tasks.write',
  communicationSend: 'communication.send',
  curriculumRead: 'curriculum.read',
  curriculumApprove: 'lessons.approve',
  contentRead: 'content.read',
  contentWrite: 'content.write',
  engagementRead: 'engagement.read',
  tripsRead: 'trips.read',
  tripsConsentVerify: 'trips.consent.verify',
  prayerModerate: 'prayer.moderate',
  analyticsRead: 'analytics.read',
  safeguardingRead: 'safeguarding.read',
  auditRead: 'audit.read',
  adminRolesManage: 'admin.roles.manage',
  adminSettingsManage: 'admin.settings.manage',
} as const;

export type PermissionKey = (typeof PermissionKeys)[keyof typeof PermissionKeys];
