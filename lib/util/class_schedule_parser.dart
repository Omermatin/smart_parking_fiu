import '../models/class_schedule.dart';

class ClassScheduleParser {
  static ClassSchedule? getCurrentOrUpcomingClass(
    Map<String, dynamic> studentJson,
  ) {
    final now = DateTime.now();
    final todayClasses = getAllTodayClasses(studentJson);

    for (final classSchedule in todayClasses) {
      final startTime = parseTime(classSchedule.meetingTimeStart);
      final endTime = parseTime(classSchedule.meetingTimeEnd);

      if (startTime == null || endTime == null) {
        continue;
      }

      if (now.isAfter(startTime) && now.isBefore(endTime)) {
        return classSchedule;
      }

      if (now.isBefore(startTime)) {
        return classSchedule;
      }
    }

    return null;
  }

  static DateTime? parseTime(String timeStr) {
    if (timeStr.isEmpty) return null;

    final match = RegExp(
      r'^(\d{1,2}):(\d{2})(AM|PM)$',
    ).firstMatch(timeStr.trim());
    if (match == null) return null;

    int hour = int.parse(match.group(1)!);
    int minute = int.parse(match.group(2)!);
    String period = match.group(3)!;

    if (period == 'PM' && hour != 12) hour += 12;
    if (period == 'AM' && hour == 12) hour = 0;

    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day, hour, minute);
  }

  static List<ClassSchedule> getAllTodayClasses(
    Map<String, dynamic> studentJson,
  ) {
    final List<ClassSchedule> todayClasses = [];
    final terms = studentJson['terms'] as List<dynamic>;
    final now = DateTime.now();
    for (var term in terms) {
      final classes = term['classes'] as List<dynamic>;

      for (var classItem in classes) {
        if ((classItem['modality'] ?? '').toString() != 'In Person') {
          continue;
        }

        final meetings = classItem['meetings'] as List<dynamic>;

        final validMeetings =
            meetings
                .where(
                  (meeting) =>
                      meeting['today']?.toString().toLowerCase() == 'true',
                )
                .toList();

        for (var meeting in validMeetings) {
          final start = parseTime(meeting['meetingTimeStart'] ?? '');
          final end = parseTime(meeting['meetingTimeEnd'] ?? '');

          if (start == null || end == null) continue;
          if (now.isAfter(end)) continue;

          final classSchedule = ClassSchedule(
            courseName: classItem['courseName'] ?? '',
            meetingTimeStart: meeting['meetingTimeStart'] ?? '',
            meetingTimeEnd: meeting['meetingTimeEnd'] ?? '',
            buildingCode: meeting['buildingCode'] ?? '',
            subject: classItem['subject'] ?? '',
            meetingDays: meeting['meetingDays'] ?? '',
            pantherId: studentJson['pantherId'] ?? '',
          );
          todayClasses.add(classSchedule);
        }
      }
    }

    todayClasses.sort((a, b) {
      final aTime = parseTime(a.meetingTimeStart);
      final bTime = parseTime(b.meetingTimeStart);
      if (aTime == null || bTime == null) return 0;
      return aTime.compareTo(bTime);
    });

    return todayClasses;
  }
}
