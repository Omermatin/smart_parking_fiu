import '../models/garage.dart';

class GarageParser {
  static List<Garage> parseGarages(List<dynamic> jsonList) {
    return jsonList
        .where((entry) {
          // Accept both garages and lots
          bool isValidType =
              entry['type'] == 'garage' || entry['type'] == 'lot';
          if (!isValidType) return false;

          if (entry['type'] == 'garage') {
            // For garages, check student spaces
            int current = int.tryParse(entry['studentSpaces'] ?? '0') ?? 0;
            int max = int.tryParse(entry['studentMaxSpaces'] ?? '1') ?? 1;
            return (max - current) > 0;
          } else {
            // For lots, check otherSpaces
            int current = int.tryParse(entry['lotOtherSpaces'] ?? '0') ?? 0;
            int max = int.tryParse(entry['lotOtherMaxSpaces'] ?? '1') ?? 1;
            return (max - current) > 0;
          }
        })
        .map((entry) {
          final garage = Garage.fromJson(entry);

          // For lots, set specific lot fields
          if (garage.isLot) {
            garage.lotOtherSpaces =
                int.tryParse(entry['lotOtherSpaces'] ?? '0') ?? 0;
            garage.lotOtherMaxSpaces =
                int.tryParse(entry['lotOtherMaxSpaces'] ?? '1') ?? 1;
          }

          return garage;
        })
        .toList();
  }
}
