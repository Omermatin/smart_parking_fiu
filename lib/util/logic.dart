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

class LocationService {
  static Position? _currentPosition;

  // Initialize location once
  static Future<void> initializeUserLocation() async {
    try {
      _currentPosition = await _determinePosition();
      debugPrint("User Location Initialized: ${_currentPosition?.latitude}, ${_currentPosition?.longitude}");
    } catch (e) {
      print("Error initializing location: $e");
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
    debugPrint("Distance: ${garage.distanceFromOrigin}");

    garage.distanceFromOrigin = calculateDistance(
      originLat,
      originLon,
      garage.latitude,
      garage.longitude,
    );
    debugPrint("Distance: ${garage.distanceFromOrigin}");
  }
}

List<Garage> sortGarages(List<Garage> garages) {
  // Constants for threshold distances (in miles)
  const double classDistanceThreshold = 0.2; // When distances to class are considered "trivially close"
  const double originDistanceThreshold = 0.2; // When distances from origin are considered "trivially close"

  // Sort the garages according to the prioritized scheme
  garages.sort((a, b) {
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

  // Debug log sorted results
  for (var garage in garages) {
    debugPrint('Garage: ${garage.name}');
    debugPrint('  Class Distance: ${garage.distanceToClass?.toStringAsFixed(2)} mi');
    debugPrint('  Origin Distance: ${garage.distanceFromOrigin?.toStringAsFixed(2)} mi');
    debugPrint('  Available Spaces: ${garage.availableSpaces?.toInt()}');
  }

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
