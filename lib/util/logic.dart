import 'dart:convert';
import 'package:flutter/material.dart';
import '../models/garage.dart';
import '../models/class_schedule.dart';
import '../models/building.dart';
import '../services/api_service.dart';
import 'dart:math';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:smart_parking_fiu/util/class_schedule_parser.dart';
import 'package:smart_parking_fiu/util/building_parser.dart';
import 'package:smart_parking_fiu/util/garage_parser.dart';

double _degToRad(double deg) => deg * (pi / 180);

double calculateDistance(double lat1, double lon1, double lat2, double lon2) {
  const double radius = 3958.8; // in miles
  double dLat = _degToRad(lat2 - lat1);
  double dLon = _degToRad(lon2 - lon1);
  double a =
      pow(sin(dLat / 2), 2) +
      cos(_degToRad(lat1)) * cos(_degToRad(lat2)) * pow(sin(dLon / 2), 2);
  double c = 2 * atan2(sqrt(a), sqrt(1 - a));
  return radius * c;
}

double calculateAvailability(Garage garage) {
  return (garage.studentMaxSpaces - garage.studentSpaces).toDouble();
}

void updateGaragesWithMetrics(
  List<Garage> garages,
  Building classBuilding,
  double originLat,
  double originLon,
) {
  for (var garage in garages) {
    garage.distanceToClass = calculateDistance(
      classBuilding.latitude,
      classBuilding.longitude,
      garage.latitude,
      garage.longitude,
    );

    garage.availableSpaces = calculateAvailability(garage);

    garage.distanceFromOrigin = calculateDistance(
      originLat,
      originLon,
      garage.latitude,
      garage.longitude,
    );
  }
}

List<Garage> sortGarages(List<Garage> garages) {
  const double classThreshold = 0.1;
  const double originThreshold = 0.05;

  garages.sort((a, b) {
    // Step 1: Compare distance to class
    double classDiff = (a.distanceToClass! - b.distanceToClass!).abs();
    if (classDiff > classThreshold) {
      return a.distanceToClass!.compareTo(b.distanceToClass!);
    }

    // Step 2: Compare distance from origin
    double originDiff = (a.distanceFromOrigin! - b.distanceFromOrigin!).abs();
    if (originDiff > originThreshold) {
      return a.distanceFromOrigin!.compareTo(b.distanceFromOrigin!);
    }

    // Step 3: Compare available spaces (higher is better)
    return b.availableSpaces!.compareTo(a.availableSpaces!);
  });

  return garages;
}

Future<dynamic> recommendations(
  String pantherid,
  double longitude,
  double latitude,
) async {
  await dotenv.load();

  List<dynamic> results = await fetchParking();

  List<Garage> availableGarages = GarageParser.parseGarages(results);

  Map<String, dynamic> classJson = await fetchUsers(pantherid);

  ClassSchedule? classSchedule = ClassScheduleParser.getCurrentOrUpcomingClass(
    classJson,
  );

  String classCode = classSchedule?.buildingCode ?? "No building code";

  Building? building = await getBuildingByCode(classCode);

  // Add longitude and latitude in the updateGarageWithMetrics call
  if (building != null) {
    updateGaragesWithMetrics(availableGarages, building, longitude, latitude);

    List<Garage> sorted = sortGarages(availableGarages);

    for (var g in availableGarages) {
      debugPrint(
        '${g.name} — Distance to Class: ${g.distanceToClass}, Distance from Origin: ${g.distanceFromOrigin}, Spaces: ${g.availableSpaces}',
      );
    }
    for (var garage in sorted) {
      debugPrint("Garage: ${garage.name}");
      debugPrint(
        "  Distance: ${garage.distanceToClass?.toStringAsFixed(2)} mi",
      );
      debugPrint("  Spaces: ${garage.availableSpaces?.toInt()}");
      debugPrint(
        "  Distance from Home: ${garage.distanceFromOrigin?.toStringAsFixed(2)} mi",
      );
    }
    return sorted;
  } else {
    debugPrint("Building not found.");
    return [];
  }
}
