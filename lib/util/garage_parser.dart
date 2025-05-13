import '../models/garage.dart';

class GarageParser {
  static List<Garage> parseGarages(List<dynamic> jsonList) {
    return jsonList
        .where((entry) {
          if (entry['type'] != 'garage') return false;

          int current = int.tryParse(entry['studentSpaces'] ?? '0') ?? 0;
          int max = int.tryParse(entry['studentMaxSpaces'] ?? '1') ?? 1;
          return (max - current) > 0;
        })
        .map((entry) => Garage.fromJson(entry))
        .toList();
  }
}
