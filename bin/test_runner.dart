import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:smart_parking_fiu/util/data.dart';
import 'package:smart_parking_fiu/util/class_schedule_parser.dart';

Future<void> main() async {
  await dotenv.load();

  final rawJson = await fetchUsers("4444444");
  final classList = ClassScheduleParser.parseClasses(rawJson);

  for (var c in classList) {
    print(
      '${c.subject}${c.catalogNumber} - ${c.courseName} | ${c.meetingTimeStart}–${c.meetingTimeEnd}',
    );
  }
}
