import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/garage.dart';
import '../util/garage_parser.dart';
import '../util/class_schedule_parser.dart';
import '../util/building_parser.dart';
import '../models/building.dart';


class GarageService {
  static Future<List<Garage>> validateAndFetchGarages(String pantherId) async {
    // Validate ID
    if (pantherId.isEmpty || !RegExp(r'^[0-9]{7}\$').hasMatch(pantherId)) {
      throw Exception("Invalid Panther ID. Must be a 7-digit number.");
    }

    // Fetch User Data
    final userData = await fetchUsers(pantherId);
    if (userData == null) {
      throw Exception("Failed to fetch user data.");
    }

    // Get the class building
    final classSchedule = ClassScheduleParser.getCurrentOrUpcomingClass(userData);
    if (classSchedule == null) {
      throw Exception("No upcoming class found.");
    }

    final buildingData = await getAllMMCBuildings();
    final classBuilding = buildingData.firstWhere(
      (building) => building.name == classSchedule.buildingCode,
      orElse: () => Building(name: "Unknown", latitude: 0.0, longitude: 0.0),
    );

    if (classBuilding.name == "Unknown") {
      throw Exception("Class building not found.");
    }

    // Fetch Garage Data
    final parkingData = await fetchParking();
    if (parkingData == null) {
      throw Exception("Failed to load garages.");
    }

    // Parse and Return Garages
    List<Garage> garages = GarageParser.parseGarages(parkingData);
    return garages;
  }
}