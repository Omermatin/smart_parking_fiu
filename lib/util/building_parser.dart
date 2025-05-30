import '../models/building.dart';

class BuildingCache {
  static List<Building> _buildings = [];
  static bool _isInitialized = false;

  static void initialize(List<dynamic> buildingData) {
    _buildings = BuildingParser.parseBuildings(buildingData);
    _isInitialized = true;
  }

  static List<Building> getBuildings() {
    if (!_isInitialized) {
      return [];
    }
    return _buildings;
  }
}

class BuildingParser {
  static List<Building> parseBuildings(List<dynamic> jsonList) {
    return jsonList
        .where(
          (entry) => entry['campusCode']?.toString().toUpperCase() == 'MMC',
        )
        .map(
          (entry) => Building(
            name: entry['buildingCode'] ?? '',
            latitude:
                double.tryParse(entry['latitude']?.toString() ?? '0') ?? 0,
            longitude:
                double.tryParse(entry['longitude']?.toString() ?? '0') ?? 0,
          ),
        )
        .toList();
  }
}

Building? getBuildingByCode(String buildingCode) {
  try {
    return BuildingCache.getBuildings().firstWhere(
      (b) => b.name.toUpperCase() == buildingCode.toUpperCase(),
    );
  } catch (e) {
    return null;
  }
}
