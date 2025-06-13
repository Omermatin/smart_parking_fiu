import '../models/building.dart';
import 'package:flutter/foundation.dart';

class BuildingCache {
  static List<Building> _buildings = [];
  static bool _isInitialized = false;
  static final Map<String, Building> _buildingMap = {};

  static bool get isInitialized => _isInitialized;

  static void initialize(List<dynamic> buildingData) {
    if (_isInitialized) {
      return;
    }

    _buildings = BuildingParser.parseBuildings(buildingData);

    _buildingMap.clear();
    for (final building in _buildings) {
      _buildingMap[building.name.toUpperCase()] = building;
    }

    _isInitialized = true;
  }

  static List<Building> getBuildings() {
    if (!_isInitialized) {
      return [];
    }
    return List.unmodifiable(_buildings);
  }

  static Building? getBuildingByCode(String code) {
    if (!_isInitialized) {
      return null;
    }
    return _buildingMap[code.toUpperCase()];
  }

  static void clear() {
    _buildings.clear();
    _buildingMap.clear();
    _isInitialized = false;
  }
}

class BuildingParser {
  static List<Building> parseBuildings(List<dynamic> jsonList) {
    return jsonList
        .where(
          (entry) => entry['campusCode']?.toString().toUpperCase() == 'MMC',
        )
        .map((entry) {
          try {
            return Building(
              name: entry['buildingCode'] ?? '',
              latitude:
                  double.tryParse(entry['latitude']?.toString() ?? '0') ?? 0,
              longitude:
                  double.tryParse(entry['longitude']?.toString() ?? '0') ?? 0,
            );
          } catch (e) {
            debugPrint('⚠️ Error parsing building: $e');
            return null;
          }
        })
        .whereType<Building>()
        .toList();
  }
}

Building? getBuildingByCode(String buildingCode) {
  return BuildingCache.getBuildingByCode(buildingCode);
}
