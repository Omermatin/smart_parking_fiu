import '../models/garage.dart';
import '../services/api_service.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:smart_parking_fiu/util/garage_parser.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/class_schedule.dart';
import 'dart:math';
import '../util/building_parser.dart';
import '../util/constants.dart';

class LocationService {
  static Position? _currentPosition;
  static bool _isInitializing = false;

  // Initialize location once
  static Future<void> initializeUserLocation() async {
    // Already have a cached position or currently initializing? Skip
    if (_currentPosition != null || _isInitializing) return;

    _isInitializing = true;
    try {
      _currentPosition = await _determinePosition();
      debugPrint(
        "✅ User Location Initialized: ${_currentPosition?.latitude}, ${_currentPosition?.longitude}",
      );
    } catch (e) {
      debugPrint("❌ Error initializing location: $e");
      _currentPosition = null;
    } finally {
      _isInitializing = false;
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
    return await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
      timeLimit: const Duration(seconds: 5),
    );
  }

  // Get the current stored location
  static Position? get currentPosition => _currentPosition;
}

// Function to calculate the distance between two points using the Haversine formula
num calculateDistance(double? lat1, double? lon1, double? lat2, double? lon2) {
  if (lat1 == null || lon1 == null || lat2 == null || lon2 == null) return 0;
  const earthRadius = 6371000;
  final dLat = (lat2 - lat1) * (pi / 180);
  final dLon = (lon2 - lon1) * (pi / 180);

  final a =
      sin(dLat / 2) * sin(dLat / 2) +
      cos(lat1 * (pi / 180)) *
          cos(lat2 * (pi / 180)) *
          sin(dLon / 2) *
          sin(dLon / 2);

  final c = 2 * atan2(sqrt(a), sqrt(1 - a));
  return earthRadius * c;
}

// Optimized function that takes already fetched data
Future<List<Garage>> getAIRecommendationsOptimized(
  String pantherId,
  double longitude,
  double latitude,
  List<ClassSchedule> todaySchedule,
  dynamic parkingResults,
  dynamic buildingResults,
) async {
  try {
    debugPrint(
      '🚀 Starting getAIRecommendationsOptimized for student: $pantherId',
    );

    if (parkingResults == null || buildingResults == null) {
      debugPrint('❌ Parking or building data is null');
      return [];
    }

    // Parse available garages
    debugPrint('🏗️ Parsing garages...');
    final availableGarages = GarageParser.parseGarages(parkingResults);
    debugPrint(
      '✅ Found ${availableGarages.length} garages with available spaces',
    );

    if (availableGarages.isEmpty) {
      debugPrint('❌ No garages with available spaces');
      return [];
    }

    // Filter buildings for today's classes
    final Set<String> todayBuildingCodes =
        todaySchedule.map((c) => c.buildingCode.trim().toUpperCase()).toSet();

    debugPrint('📚 Today\'s building codes: ${todayBuildingCodes.join(", ")}');

    final filteredBuildings =
        buildingResults.where((b) {
          final code =
              (b['buildingCode'] ?? '').toString().trim().toUpperCase();
          return todayBuildingCodes.contains(code);
        }).toList();

    debugPrint(
      '🏛️ Filtered ${filteredBuildings.length} buildings for today\'s classes',
    );

    // Prepare n8n request
    final n8nUrl = dotenv.env['N8N_WEBHOOK_URL'];
    if (n8nUrl == null) {
      debugPrint('❌ N8N_WEBHOOK_URL not found in environment variables');
      return [];
    }

    // Build request payload with pre-calculated distances
    final requestPayload = {
      'student_id': pantherId,
      'student_location': {'latitude': latitude, 'longitude': longitude},
      'today_classes':
          todaySchedule
              .map((c) {
                final building = getBuildingByCode(c.buildingCode);
                if (building == null) {
                  debugPrint(
                    '⚠️ Building ${c.buildingCode} not found in cache',
                  );
                  return null;
                }

                return {
                  'building_code': c.buildingCode,
                  'meeting_time_start': c.meetingTimeStart,
                  'meeting_time_end': c.meetingTimeEnd,
                  'distances_to_garages':
                      availableGarages
                          .map(
                            (g) => {
                              'garage_name': g.name,
                              'distance': calculateDistance(
                                building.latitude,
                                building.longitude,
                                g.latitude,
                                g.longitude,
                              ),
                            },
                          )
                          .toList(),
                };
              })
              .where((c) => c != null)
              .toList(),
      'available_garages':
          availableGarages
              .map(
                (g) => {
                  'name': g.name,
                  'type': g.type,
                  'latitude': g.latitude,
                  'longitude': g.longitude,
                  'available_spaces': g.calculateAvailableSpaces(),
                  'availability_percentage':
                      g.calculateAvailabilityPercentage(),
                  'studentMaxSpaces': g.studentMaxSpaces,
                },
              )
              .toList(),
      'buildings':
          filteredBuildings
              .map(
                (b) => {
                  'building_code': b['buildingCode'],
                  'latitude': b['latitude'],
                  'longitude': b['longitude'],
                },
              )
              .toList(),
    };

    debugPrint('📤 Sending request to n8n...');

    // Make n8n request with timeout
    try {
      final response = await http
          .post(
            Uri.parse(n8nUrl),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(requestPayload),
          )
          .timeout(
            AppConstants.n8nRequestTimeout,
            onTimeout: () {
              throw Exception('n8n request timeout');
            },
          );

      debugPrint('📥 Response status code: ${response.statusCode}');

      if (response.statusCode == 200) {
        final List<dynamic> responseData = jsonDecode(response.body);

        if (responseData.isEmpty) {
          debugPrint('❌ No garages returned from n8n');
          return [];
        }

        // Parse n8n response into Garage objects
        final sortedGarages = <Garage>[];
        for (final garageData in responseData) {
          try {
            final String type = garageData['type'];
            final int? studentMaxSpaces =
                type == "lot"
                    ? garageData['other_max_spaces']
                    : garageData['student_max_spaces'];

            // Find matching garage from available garages to get location data
            final matchingGarage = availableGarages.firstWhere(
              (g) => g.name == garageData['name'],
              orElse: () => Garage(name: '', type: ''),
            );

            final garage = Garage(
              name: garageData['name'],
              type: type,
              studentMaxSpaces: studentMaxSpaces,
              availableSpaces: garageData['available_spaces'],
              score: garageData['score']?.toDouble(),
              // Include location data from matching garage
              latitude:
                  matchingGarage.name.isNotEmpty
                      ? matchingGarage.latitude
                      : null,
              longitude:
                  matchingGarage.name.isNotEmpty
                      ? matchingGarage.longitude
                      : null,
              distanceFromOrigin:
                  matchingGarage.name.isNotEmpty
                      ? calculateDistance(
                            latitude,
                            longitude,
                            matchingGarage.latitude,
                            matchingGarage.longitude,
                          ).toDouble() /
                          1609.34
                      // Convert to miles
                      : null,
            );

            sortedGarages.add(garage);
          } catch (e) {
            debugPrint(
              '⚠️ Could not create garage from data: $garageData - Error: $e',
            );
          }
        }

        debugPrint('🎯 Returning ${sortedGarages.length} recommended garages');
        return sortedGarages;
      } else {
        debugPrint('❌ n8n request failed with status: ${response.statusCode}');
        debugPrint('❌ Response body: ${response.body}');
        return [];
      }
    } catch (e) {
      debugPrint('💥 Error making n8n request: $e');
      throw e;
    }
  } catch (e) {
    debugPrint('💥 Error getting AI recommendations: $e');
    rethrow;
  }
}

// Utility function for retry logic

// Sorting functions
List<Garage> sortGaragesByAvailability(List<Garage> garages) {
  final sorted = List<Garage>.from(garages);
  sorted.sort(
    (a, b) =>
        b.calculateAvailableSpaces().compareTo(a.calculateAvailableSpaces()),
  );
  return sorted;
}

List<Garage> sortGaragesByDistanceFromYou(List<Garage> garages) {
  final sorted = List<Garage>.from(garages);
  sorted.sort((a, b) {
    final distA = a.distanceFromOrigin ?? double.infinity;
    final distB = b.distanceFromOrigin ?? double.infinity;

    return distA.compareTo(distB);
  });
  return sorted;
}

List<Garage> sortGaragesByDistanceFromClass(List<Garage> garages) {
  final sorted = List<Garage>.from(garages);
  sorted.sort((a, b) {
    final distA = a.distanceToClass ?? double.infinity;
    final distB = b.distanceToClass ?? double.infinity;
    return distA.compareTo(distB);
  });
  return sorted;
}

List<Garage> resetToOriginalOrder(List<Garage> garages) {
  // Just return a copy of the original list without sorting
  return List<Garage>.from(garages);
}
