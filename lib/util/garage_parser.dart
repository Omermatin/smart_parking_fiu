import '../models/garage.dart';

class GarageParser {
  static List<Garage> parseGarages(List<dynamic> jsonList) {
    return jsonList
        .where((entry) => entry['type'] == 'garage')
        .map((entry) => Garage.fromJson(entry))
        .toList();
  }
}
