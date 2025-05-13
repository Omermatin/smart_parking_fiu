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
@override
  String toString() {
    return '''
    📚 Course: $courseName
    📌 Subject: $subject $catalogNumber - Section $classSection
    📅 Days: $meetingDays
    ⏰ Time: $meetingTimeStart - $meetingTimeEnd
    🏛️ Location: $buildingCode
    🌐 Mode: $mode
    🌞 Today: ${today == 'true' ? 'Yes' : 'No'}
    ''';
  }
  }
