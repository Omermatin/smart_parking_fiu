// lib/util/building_parser.dart
import 'package:flutter/material.dart';
import '../models/building.dart';
import '../services/api_service.dart';

List<Building>? _cachedBuildings;

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

// Keep this to fetch and cache buildings
Future<List<Building>> getAllMMCBuildings() async {
  if (_cachedBuildings != null) {
    debugPrint('Returning cached buildings');
    return _cachedBuildings!;
  }

  debugPrint('Fetching buildings for the first time');
  final jsonData = await fetchBuilding();
  if (jsonData == null) return [];

  _cachedBuildings = BuildingParser.parseBuildings(jsonData);
  return _cachedBuildings!;
}

// This gets a single building by its code (e.g., "PG6")
Future<Building?> getBuildingByCode(String buildingCode) async {
  final buildings = await getAllMMCBuildings();
  try {
    return buildings.firstWhere(
      (b) => b.name.toUpperCase() == buildingCode.toUpperCase(),
    );
  } catch (e) {
    return null;
  }
}
