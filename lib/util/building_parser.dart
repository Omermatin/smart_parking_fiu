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

Future<List<Building>> refreshMMCBuildings() async {
  _cachedBuildings = null;
  return getAllMMCBuildings();
}
