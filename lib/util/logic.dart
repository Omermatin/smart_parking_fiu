import '../models/garage.dart';
import '../models/class_schedule.dart';
import '../models/building.dart';
import '../services/api_service.dart';
import 'dart:math';
import 'package:flutter_dotenv/flutter_dotenv.dart';
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

/// Format a distance in miles to a string with 2 decimal places
String formatDistance(double? distance) {
  if (distance == null) return 'N/A';
  return '${distance.toStringAsFixed(2)} mi';
}

int calculateAvailability(Garage garage) {
  return garage.calculateAvailableSpaces();
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

double calculateAdaptiveScore(
  Garage garage,
  double minClassDistance,
  double maxClassDistance,
  double minOriginDistance,
  double maxOriginDistance,
  int minSpaces,
  int maxSpaces, {
  double classWeight = 0.63, // Increased weight for class distance
  double originWeight = 0.1, // Moderate weight for origin distance
  double spacesWeight = 0.27, // Reduced weight for spaces
}) {
  // Define what we consider "sufficient" spaces
  const int sufficientSpaces =
      100; // Minimum number of spaces to be considered sufficient

  // Calculate distance scores with exponential decay
  double classDistanceScore = exp(
    -2 * (garage.distanceToClass! / maxClassDistance),
  );
  double originDistanceScore = exp(
    -2 * (garage.distanceFromOrigin! / maxOriginDistance),
  );

  // Calculate space score with a threshold
  double spaceScore;
  if (garage.availableSpaces! >= sufficientSpaces) {
    // If we have sufficient spaces, give a high score
    spaceScore = 1.0;
  } else {
    // Otherwise, scale based on available spaces
    spaceScore = garage.availableSpaces! / sufficientSpaces;
  }

  // Calculate final score with adjusted weights
  double score =
      (classWeight * classDistanceScore) +
      (originWeight * originDistanceScore) +
      (spacesWeight * spaceScore);

  // Apply proximity bonus
  const double proximityThreshold = 0.5; // 0.5 miles
  if (garage.distanceToClass! <= proximityThreshold &&
      garage.availableSpaces! >= sufficientSpaces) {
    score *= 1.5; // 50% bonus for very close garages with sufficient spaces
  }

  return score;
}

List<Garage> sortGaragesByAdaptiveScores(List<Garage> garages) {
  if (garages.isEmpty) return [];

  // Calculate min and max values for each factor
  double minClassDistance = garages
      .map((g) => g.distanceToClass!)
      .reduce((a, b) => a < b ? a : b);
  double maxClassDistance = garages
      .map((g) => g.distanceToClass!)
      .reduce((a, b) => a > b ? a : b);

  double minOriginDistance = garages
      .map((g) => g.distanceFromOrigin!)
      .reduce((a, b) => a < b ? a : b);
  double maxOriginDistance = garages
      .map((g) => g.distanceFromOrigin!)
      .reduce((a, b) => a > b ? a : b);

  int minSpaces = garages
      .map((g) => g.availableSpaces!)
      .reduce((a, b) => a < b ? a : b);
  int maxSpaces = garages
      .map((g) => g.availableSpaces!)
      .reduce((a, b) => a > b ? a : b);

  // Calculate and store scores
  final scoredGarages =
      garages.map((garage) {
        double score = calculateAdaptiveScore(
          garage,
          minClassDistance,
          maxClassDistance,
          minOriginDistance,
          maxOriginDistance,
          minSpaces,
          maxSpaces,
        );
        return MapEntry(garage, score);
      }).toList();

  // Sort based on the calculated scores (descending)
  scoredGarages.sort((a, b) {
    if (a.value != b.value) {
      return b.value.compareTo(a.value);
    }
    // If scores are equal, prioritize by:
    // 1. Distance to class
    if (a.key.distanceToClass != b.key.distanceToClass) {
      return a.key.distanceToClass!.compareTo(b.key.distanceToClass!);
    }
    // 2. Available spaces
    return b.key.availableSpaces!.compareTo(a.key.availableSpaces!);
  });

  return scoredGarages.map((entry) => entry.key).toList();
}

List<Garage> sortGaragesByDistance(List<Garage> garages) {
  garages.sort((a, b) => a.distanceToClass!.compareTo(b.distanceToClass!));
  return garages;
}

List<Garage> sortGaragesByAvailability(List<Garage> garages) {
  garages.sort((a, b) => b.availableSpaces!.compareTo(a.availableSpaces!));
  return garages;
}

List<Garage> sortGaragesByDistanceFromYou(List<Garage> garages) {
  garages.sort((a, b) => a.distanceFromOrigin!.compareTo(b.distanceFromOrigin!));
  return garages;
}


Future<List<Garage>> recommendations(
  String pantherid,
  double longitude,
  double latitude,
  ClassSchedule classSchedule,
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

  // Get class code from the passed classSchedule
  final classCode = classSchedule.buildingCode;

  // Find building for the class
  final building = getBuildingByCode(classCode);
  if (building == null) {
    debugPrint("Building not found for class code: $classCode");
    return [];
  }

  // Update metrics and sort garages
  updateGaragesWithMetrics(availableGarages, building, latitude, longitude);

  // Use compute for sorting to avoid UI jank
  final sorted = await compute(sortGaragesByAdaptiveScores, availableGarages);

  for (var garage in sorted) {
    debugPrint('Garage: ${garage.name}');
    debugPrint('Distance: ${garage.distanceToClass} miles');
    debugPrint('Spaces Available: ${garage.availableSpaces}');
    debugPrint('Distance to Origin: ${garage.distanceFromOrigin} miles\n');
  }

  return sorted;
}
