// lib/util/building_parser.dart
import 'package:flutter/material.dart';
import '../models/building.dart';
import '../services/api_service.dart';

class BuildingCache {
  static List<Building>? _buildings;
  static bool _isInitialized = false;

  /// Initialize the building cache. Should be called once at app startup.
  static Future<void> initialize() async {
    if (_isInitialized) return;

    debugPrint('Initializing building cache');
    final jsonData = await fetchBuilding();
    if (jsonData == null) {
      _buildings = [];
    } else {
      _buildings = BuildingParser.parseBuildings(jsonData);
    }
    _isInitialized = true;
    debugPrint(
      'Building cache initialized with ${_buildings?.length ?? 0} buildings',
    );
  }

  /// Get all buildings. Must call initialize() first.
  static List<Building> getBuildings() {
    if (!_isInitialized) {
      throw Exception(
        'BuildingCache not initialized. Call initialize() first.',
      );
    }
    return _buildings ?? [];
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
            latitude: double.tryParse(entry['latitude'] ?? '0') ?? 0,
            longitude: double.tryParse(entry['longitude'] ?? '0') ?? 0,
          ),
        )
        .toList();
  }
}

// This gets a single building by its code (e.g., "PG6")
Building? getBuildingByCode(String buildingCode) {
  if (!BuildingCache._isInitialized) {
    throw Exception('BuildingCache not initialized. Call initialize() first.');
  }

  try {
    return BuildingCache.getBuildings().firstWhere(
      (b) => b.name.toUpperCase() == buildingCode.toUpperCase(),
    );
  } catch (e) {
    return null;
  }
}
