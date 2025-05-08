class ClassSchedule {
  final String courseName;
  final String meetingTimeStart;
  final String meetingTimeEnd;
  final String buildingCode;
  final String mode;
  final String subject;
  final String catalogNumber;
  final String classSection;
  final String meetingDays;
  final String today;

  ClassSchedule({
    required this.courseName,
    required this.meetingTimeStart,
    required this.meetingTimeEnd,
    required this.buildingCode,
    required this.mode,
    required this.subject,
    required this.catalogNumber,
    required this.classSection,
    required this.meetingDays,
    required this.today,
  });

  factory ClassSchedule.fromJson(Map<String, dynamic> json) {
    return ClassSchedule(
      courseName: json['courseName'] ?? '',
      meetingTimeStart: json['meetingTimeStart'] ?? '',
      meetingTimeEnd: json['meetingTimeEnd'] ?? '',
      buildingCode: json['buildingCode'] ?? '',
      mode: json['mode'] ?? '',
      subject: json['subject'] ?? '',
      catalogNumber: json['catalogNumber'] ?? '',
      classSection: json['classSection'] ?? '',
      meetingDays: json['meetingDays'] ?? '',
      today:
          json['today']?.toString().toLowerCase() == 'true' ? 'true' : 'false',
    );
  }
}
