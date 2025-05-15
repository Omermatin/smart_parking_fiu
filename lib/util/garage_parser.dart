import '../models/garage.dart';

class GarageParser {
  static List<Garage> parseGarages(List<dynamic> jsonList) {
    return jsonList
        .map((entry) => Garage.fromJson(entry))
        .where((garage) => garage.hasAvailableSpaces())
        .toList();
  }
}