import '../models/class_schedule.dart';

class ClassScheduleParser {
  static List<ClassSchedule> parseClasses(Map<String, dynamic> studentJson) {
    final List<ClassSchedule> classList = [];
    final DateTime now = DateTime.now();

    final terms = studentJson['terms'] as List<dynamic>;

    for (var term in terms) {
      final classes = term['classes'] as List<dynamic>;

      for (var classItem in classes) {
        final meetings = classItem['meetings'] as List<dynamic>;
        final firstMeeting = meetings.isNotEmpty ? meetings.first : {};

        final modality = (classItem['modality'] ?? '').toString().toLowerCase();
        final today = firstMeeting['today']?.toString().toLowerCase() == 'true';

        // Parse and compare end time
        final endTimeStr = firstMeeting['meetingTimeEnd'] ?? '';
        final endTime = _parseTime(endTimeStr);

        // Filter out invalid classes
        // if (!today ||
        //     modality == 'online' ||
        //     (endTime != null && endTime.isBefore(now))) {
        //   continue;
        // }

        classList.add(
          ClassSchedule(
            courseName: classItem['courseName'] ?? '',
            meetingTimeStart: firstMeeting['meetingTimeStart'] ?? '',
            meetingTimeEnd: firstMeeting['meetingTimeEnd'] ?? '',
            buildingCode: firstMeeting['buildingCode'] ?? '',
            mode: classItem['modality'] ?? '',
            subject: classItem['subject'] ?? '',
            catalogNumber: classItem['catalogNumber'] ?? '',
            classSection: classItem['classSection'] ?? '',
            meetingDays: firstMeeting['meetingDays'] ?? '',
            today: today ? 'true' : 'false',
          ),
        );
      }
    }

    return classList;
  }

  static DateTime? _parseTime(String timeStr) {
    final match = RegExp(r'^(\d+):(\d+)(AM|PM)$').firstMatch(timeStr.trim());
    if (match == null) return null;

    int hour = int.parse(match.group(1)!);
    int minute = int.parse(match.group(2)!);
    String period = match.group(3)!;

    if (period == 'PM' && hour != 12) hour += 12;
    if (period == 'AM' && hour == 12) hour = 0;

    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day, hour, minute);
  }
}
