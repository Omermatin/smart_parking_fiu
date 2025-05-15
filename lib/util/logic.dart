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
import 'package:geolocator/geolocator.dart';
import 'package:flutter/foundation.dart';

class LocationService {
  static Position? _currentPosition;

  // Initialize location once
  static Future<void> initializeUserLocation() async {
    try {
      _currentPosition = await _determinePosition();
      debugPrint(
        "User Location Initialized: ${_currentPosition?.latitude}, ${_currentPosition?.longitude}",
      );
    } catch (e) {
      debugPrint("Error initializing location: $e");
      _currentPosition = null;
    }
  }

  // Directly fetch the user's current location (with permissions)
  static Future<Position> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Check if location services are enabled
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('Location services are disabled.');
    }

    // Request permission if not already granted
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception('Location permissions are permanently denied');
    }

    // If permissions are granted, get the location
    return await Geolocator.getCurrentPosition();
  }

  // Get the current stored location
  static Position? get currentPosition => _currentPosition;
}

double _degToRad(double deg) => deg * (pi / 180);

double calculateDistance(double lat1, double lon1, double lat2, double lon2) {
  const double radius = 3963.1; // in miles
  double dLat = _degToRad(lat2 - lat1);
  double dLon = _degToRad(lon2 - lon1);
  double a =
      pow(sin(dLat / 2), 2) +
      cos(_degToRad(lat1)) * cos(_degToRad(lat2)) * pow(sin(dLon / 2), 2);
  double c = 2 * atan2(sqrt(a), sqrt(1 - a));
  return radius * c;
}

int calculateAvailability(Garage garage) {
  if (garage.isLot) {
    final other = garage.lotOtherSpaces?.toInt() ?? 0;
    final max = garage.lotOtherMaxSpaces?.toInt() ?? 0;
    return max - other;
  }
  return garage.studentMaxSpaces.toInt() - garage.studentSpaces.toInt();
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
  // Constants for threshold distances (in miles)

  const double classDistanceThreshold =
      0.2; // When distances to class are considered "trivially close"
  const double originDistanceThreshold =
      0.2; // When distances from origin are considered "trivially close"

  // Filter out garages with missing data
  final filteredGarages =
      garages.where((garage) {
        return garage.distanceToClass != null &&
            garage.distanceFromOrigin != null &&
            garage.availableSpaces != null;
      }).toList();

  // Sort the garages according to the prioritized scheme
  filteredGarages.sort((a, b) {
    // PRIORITY 1: Distance to class (primary factor)
    final classDiff = (a.distanceToClass! - b.distanceToClass!).abs();
    if (classDiff > classDistanceThreshold) {
      // If difference is significant, sort by closest to class
      return a.distanceToClass!.compareTo(b.distanceToClass!);
    }

    // PRIORITY 2: Distance from origin (secondary factor, when class distances are close)
    final originDiff = (a.distanceFromOrigin! - b.distanceFromOrigin!).abs();
    if (originDiff > originDistanceThreshold) {
      // If difference is significant, sort by closest from origin
      return a.distanceFromOrigin!.compareTo(b.distanceFromOrigin!);
    }

    // PRIORITY 3: Available spaces (when both distances are trivially close)
    // Higher available spaces is better, so reverse the comparison
    return b.availableSpaces!.compareTo(a.availableSpaces!);
  });

  return filteredGarages;
}

Future<List<Garage>> recommendations(
  String pantherid,
  double longitude,
  double latitude,
) async {
  // Load environment variables if needed
  if (dotenv.env.isEmpty) {
    await dotenv.load();
  }

  // Fetch parking data
  final results = await fetchParking();
  if (results == null) {
    debugPrint("Failed to fetch parking data");
    return [];
  }

  // Parse garages
  final availableGarages = GarageParser.parseGarages(results);

  // Fetch user schedule
  final classJson = await fetchUsers(pantherid);
  if (classJson == null) {
    debugPrint("Failed to fetch class schedule");
    return [];
  }

  // Get current or upcoming class
  final classSchedule = ClassScheduleParser.getCurrentOrUpcomingClass(
    classJson,
  );

  // If no class is found, return empty list
  if (classSchedule == null) {
    debugPrint("No current or upcoming class found");
    return [];
  }

  final classCode = classSchedule.buildingCode;

  // Find building for the class
  final building = await getBuildingByCode(classCode);
  if (building == null) {
    debugPrint("Building not found for class code: $classCode");
    return [];
  }

  // Update metrics and sort garages
  updateGaragesWithMetrics(availableGarages, building, latitude, longitude);

  // Use compute for sorting to avoid UI jank
  final sorted = await compute(sortGarages, availableGarages);

  for (var garage in sorted) {
    debugPrint('Garage: ${garage.name}');
    debugPrint('Distance: ${garage.distanceToClass} miles');
    debugPrint('Spaces Available: ${garage.availableSpaces}');
    debugPrint('Distance to Origin: ${garage.distanceFromOrigin} miles\n');
  }

  return sorted;
}

// Wrapper for compute to run sorting off the main thread
Future<List<Garage>> computeSortGarages(List<Garage> garages) {
  return compute(sortGarages, garages);
}
