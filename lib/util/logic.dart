import '../models/garage.dart';
import '../services/api_service.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:smart_parking_fiu/util/garage_parser.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/class_schedule.dart';

class LocationService {
  static Position? _currentPosition;

  // Initialize location once
  static Future<void> initializeUserLocation() async {
    // Already have a cached position? Skip the expensive call.
    if (_currentPosition != null) return;
    try {
      _currentPosition = await _determinePosition();
      //debugPrint(
      //  "User Location Initialized: ${_currentPosition?.latitude}, ${_currentPosition?.longitude}",
      //);
    } catch (e) {
      //  debugPrint("Error initializing location: $e");
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

// Simple function to get ranked garages from n8n
Future<List<Garage>> getAIRecommendations(
  String pantherId,
  double longitude,
  double latitude,
  List<ClassSchedule> todaySchedule,
  Future<dynamic> parkingFuture,
  Future<dynamic> buildingFuture,
) async {
  try {
    debugPrint('🚀 Starting getAIRecommendations for student: $pantherId');

    // 1. Fetch parking & building together
    debugPrint('📋 Fetching parking + building in parallel…');
    // 1. Fetch parking & building together
    final results = await Future.wait([parkingFuture, buildingFuture]);

    final parkingResults = results[0];
    final buildingResults = results[1];

    if (parkingResults == null || buildingResults == null) {
      debugPrint('❌ Failed to fetch parking or building data');
      return [];
    }
    debugPrint('✅ Parking & Building data fetched');

    // 2. Parse available garages
    debugPrint('🏗️ Parsing garages...');
    final availableGarages = GarageParser.parseGarages(parkingResults);
    debugPrint('✅ Found ${availableGarages.length} garages');

    // 3. Get today's classes
    debugPrint('📚 Parsing today\'s classes...');
    final allTodayClasses = todaySchedule;
    debugPrint('✅ Found ${allTodayClasses.length} classes for today');

    // 4. Filter buildings to only those matching codes in today's classes
    final Set<String> todayBuildingCodes =
        allTodayClasses.map((c) => c.buildingCode.trim().toUpperCase()).toSet();

    final filteredBuildings =
        (buildingResults as List<dynamic>).where((b) {
          final code =
              (b['buildingCode'] ?? '').toString().trim().toUpperCase();
          return todayBuildingCodes.contains(code);
        }).toList();

    debugPrint('🏢 Filtered buildings count: ${filteredBuildings.length}');

    // 5. Send data to n8n
    final n8nUrl = dotenv.env['N8N_WEBHOOK_URL'];

    if (n8nUrl == null) {
      debugPrint('❌ N8N_WEBHOOK_URL not found in environment variables');
      return [];
    }
    debugPrint('🔗 N8N URL found: $n8nUrl');

    final requestBody = jsonEncode({
      'student_id': pantherId,
      'student_location': {'latitude': latitude, 'longitude': longitude},
      'today_classes':
          allTodayClasses
              .map(
                (c) => {
                  'building_code': c.buildingCode,
                  'meeting_time_start': c.meetingTimeStart,
                  'meeting_time_end': c.meetingTimeEnd,
                },
              )
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
    });

    final response = await http.post(
      Uri.parse(n8nUrl),
      headers: {'Content-Type': 'application/json'},
      body: requestBody,
    );

    if (response.statusCode == 200) {
      final List<dynamic> responseData = jsonDecode(response.body);
      //debugPrint('✅ Received ${responseData.length} items from n8n');

      // n8n returns: [{"output": [garage1, garage2...]}]
      // We need to access responseData[0]["output"]
      final List<dynamic> garageArray = responseData[0]['output'];
      //debugPrint('✅ Found ${garageArray.length} garages in output');

      // Create garage objects directly from n8n response data
      final sortedGarages = <Garage>[];
      for (final garageData in garageArray) {
        try {
          final garage = Garage(
            name: garageData['name'],
            type: garageData['type'],
            latitude: garageData['latitude'].toDouble(),
            longitude: garageData['longitude'].toDouble(),
            studentSpaces: garageData['student_spaces'],
            studentMaxSpaces: garageData['student_max_spaces'],
            availableSpaces: garageData['available_spaces'],
          );

          sortedGarages.add(garage);
          //debugPrint('✅ Created garage from n8n data: ${garage.name}');
        } catch (e) {
          //  debugPrint(
          //  '⚠️ Could not create garage from data: $garageData - Error: $e',
          //);
        }
      }

      //debugPrint(
      //  '🎯 Returning ${sortedGarages.length} garages created from n8n data',
      //);
      return sortedGarages;
    } else {
      //debugPrint('❌ n8n request failed with status: ${response.statusCode}');
      //debugPrint('❌ Response body: ${response.body}');
      return [];
    }
  } catch (e) {
    //debugPrint('💥 Error getting AI recommendations: $e');
    return [];
  }
}
