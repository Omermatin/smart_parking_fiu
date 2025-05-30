class ClassSchedule {
  final String courseName;
  final String meetingTimeStart;
  final String meetingTimeEnd;
  final String buildingCode;
  final String? mode;
  final String subject;
  final String meetingDays;
  final String? today;
  final String pantherId;

  ClassSchedule({
    required this.courseName,
    required this.meetingTimeStart,
    required this.meetingTimeEnd,
    required this.buildingCode,
    this.mode,
    required this.subject,
    required this.meetingDays,
    this.today,
    required this.pantherId,
  });
}
