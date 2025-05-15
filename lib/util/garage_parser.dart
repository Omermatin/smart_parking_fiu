import '../models/garage.dart';

class GarageParser {
  static List<Garage> parseGarages(List<dynamic> jsonList) {
    return jsonList
        .where((entry) {
          if (entry['type'] == 'garage') {
            // For garages, check student spaces
            int current = int.tryParse(entry['studentSpaces'] ?? '0') ?? 0;
            int max = int.tryParse(entry['studentMaxSpaces'] ?? '1') ?? 1;
            return (max - current) > 0;
          } else {
            // For lots, check otherSpaces (from "otherSpaces" in JSON)
            int current = int.tryParse(entry['otherSpaces'] ?? '0') ?? 0;
            int max = int.tryParse(entry['otherMaxSpaces'] ?? '1') ?? 1;
            return (max - current) > 0;
          }
        })
        .map((entry) {
          final garage = Garage.fromJson(entry);
          return garage;
        })
        .toList();
  }
}
