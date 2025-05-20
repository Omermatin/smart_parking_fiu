// parsers/class_schedule_parser.dart
import '../models/class_schedule.dart';

class ClassScheduleParser {
  static ClassSchedule? getCurrentOrUpcomingClass(
    Map<String, dynamic> studentJson,
  ) {
    final now = DateTime.now();
    ClassSchedule? nextClass;

    final terms = studentJson['terms'] as List<dynamic>;

    for (var term in terms) {
      final classes = term['classes'] as List<dynamic>;

      for (var classItem in classes) {
        final meetings = classItem['meetings'] as List<dynamic>;

        // Only consider meetings marked as "today": "true"
        final validMeetings =
            meetings
                .where(
                  (meeting) =>
                      meeting['today']?.toString().toLowerCase() == 'true',
                )
                .toList();

        if (validMeetings.isEmpty) {
          continue; // Skip if no valid meetings for today
        }

        for (var meeting in validMeetings) {
          final startTimeStr = meeting['meetingTimeStart'] ?? '';
          final endTimeStr = meeting['meetingTimeEnd'] ?? '';

          final startTime = parseTime(startTimeStr);
          final endTime = parseTime(endTimeStr);

          // Create a temporary class object with only the relevant meeting
          final temporaryClass = ClassSchedule(
            courseName: classItem['courseName'] ?? '',
            meetingTimeStart: startTimeStr,
            meetingTimeEnd: endTimeStr,
            buildingCode: meeting['buildingCode'] ?? '',
            mode: classItem['modality'] ?? '',
            subject: classItem['subject'] ?? '',
            catalogNumber: classItem['catalogNumber'] ?? '',
            classSection: classItem['classSection'] ?? '',
            meetingDays: meeting['meetingDays'] ?? '',
            today: meeting['today'] = "true",
            pantherId: studentJson['pantherId'] ?? '',
          );

          // If the class is ongoing, we immediately return it
          if (startTime != null && endTime != null) {
            if (now.isAfter(startTime) && now.isBefore(endTime)) {
              return temporaryClass; // Ongoing class with valid meeting
            }

            // If not ongoing, but it is upcoming
            if (now.isBefore(startTime)) {
              if (nextClass == null ||
                  parseTime(nextClass.meetingTimeStart)!.isAfter(startTime)) {
                nextClass = temporaryClass;
              }
            }
          }
        }
      }
    }

    // If no ongoing class is found, return the next upcoming class
    return nextClass; // This will be null if no upcoming classes exist
  }

  // Public method for parsing time
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
}
