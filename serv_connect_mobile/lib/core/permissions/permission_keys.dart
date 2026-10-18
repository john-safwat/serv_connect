/// Canonical permission keys (`<feature>.<action>[.<qualifier>]`) matching
/// BRD §6 and `docs/04-security.md`.
abstract final class PermissionKeys {
  static const String membersReadSummary = 'members.read.summary';
  static const String membersReadFull = 'members.read.full';
  static const String membersWrite = 'members.write';
  static const String membersNotesRead = 'members.notes.read';
  static const String membersNotesWrite = 'members.notes.write';
  static const String membersMedicalRead = 'members.medical.read';

  static const String groupsRead = 'groups.read';
  static const String groupsWrite = 'groups.write';
  static const String groupsAssignServants = 'groups.assign-servants';
  static const String groupsPromote = 'groups.promote';

  static const String scheduleRead = 'schedule.read';
  static const String scheduleWrite = 'schedule.write';

  static const String attendanceRecord = 'attendance.record';
  static const String attendanceRead = 'attendance.read';
  static const String followUpWrite = 'followup.write';

  static const String tasksRead = 'tasks.read';
  static const String tasksWrite = 'tasks.write';

  static const String contentRead = 'content.read';
  static const String lessonsApprove = 'lessons.approve';

  static const String auditRead = 'audit.read';
  static const String adminConfigure = 'admin.configure';
}
