import '../models/garage.dart';
import 'package:flutter/foundation.dart';

class GarageParser {
  static List<Garage> parseGarages(List<dynamic> jsonList) {
    final List<Garage> garages = [];

    for (final entry in jsonList) {
      try {
        final garage = Garage.fromJson(entry);

        // Only include garages with available spaces
        if (garage.hasAvailableSpaces()) {
          garages.add(garage);
        }
      } catch (e) {
        debugPrint('⚠️ Error parsing garage: $e');
        debugPrint('Entry data: $entry');
      }
    }

    debugPrint('✅ Parsed ${garages.length} garages with available spaces');
    return garages;
  }
}
