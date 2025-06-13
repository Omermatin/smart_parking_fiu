import '../models/garage.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:smart_parking_fiu/util/garage_parser.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/class_schedule.dart';
import '../util/building_parser.dart';
import '../util/constants.dart';
import '../util/location_distance.dart';

Future<List<Garage>> getAIRecommendationsOptimized(
  String pantherId,
  double longitude,
  double latitude,
  List<ClassSchedule> todaySchedule,
  dynamic parkingResults,
  dynamic buildingResults,
) async {
  try {
    if (parkingResults == null || buildingResults == null) {
      debugPrint('Parking or building data is null');
      return [];
    }

    // Parse available garages
    final availableGarages = GarageParser.parseGarages(parkingResults);

    if (availableGarages.isEmpty) {
      debugPrint('No garages with available spaces');
      return [];
    }

    // Parse building data
    final buildings = BuildingParser.parseBuildings(buildingResults);

    if (buildings.isEmpty) {
      debugPrint('No buildings found');
      return [];
    }

    // Filter buildings for today's classes
    final Set<String> todayBuildingCodes =
        todaySchedule.map((c) => c.buildingCode.trim().toUpperCase()).toSet();

    // Buildings
    final filteredBuildings =
        buildingResults.where((b) {
          final code =
              (b['buildingCode'] ?? '').toString().trim().toUpperCase();
          return todayBuildingCodes.contains(code);
        }).toList();

    // Prepare n8n request
    final n8nUrl = dotenv.env['N8N_WEBHOOK_URL'];
    if (n8nUrl == null) {
      debugPrint('N8N_WEBHOOK_URL not found in environment variables');
      return [];
    }

    // Build request payload with pre-calculated distances
    final requestPayload = {
      'student_location': {'latitude': latitude, 'longitude': longitude},
      'today_classes':
          todaySchedule
              .map((c) {
                final building = getBuildingByCode(c.buildingCode);
                if (building == null) {
                  debugPrint('Building ${c.buildingCode} not found in cache');
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
                  'available_spaces': g.calculateAvailableSpaces(),
                  'availability_percentage':
                      g.calculateAvailabilityPercentage(),
                  'max_spaces':
                      g.type.toLowerCase() == 'lot'
                          ? g.lotOtherMaxSpaces
                          : g.studentMaxSpaces,
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

      debugPrint('Response status code: ${response.statusCode}');

      if (response.statusCode == 200) {
        final List<dynamic> responseData = jsonDecode(response.body);

        if (responseData.isEmpty) {
          debugPrint('No garages returned from n8n');
          return [];
        }

        // Parse n8n response into Garage objects & match them with existing objects
        final sortedGarages = <Garage>[];
        for (final garageData in responseData) {
          try {
            final String type = garageData['type'];
            final int? maxSpaces = garageData['max_spaces'];

            // Find matching garage from available garages to get location data
            final matchingGarage = availableGarages.firstWhere(
              (g) => g.name == garageData['name'],
              orElse: () => Garage(name: '', type: ''),
            );

            final garage = Garage(
              name: garageData['name'],
              type: type,
              studentSpaces:
                  matchingGarage.name.isNotEmpty
                      ? matchingGarage.studentSpaces
                      : null,
              studentMaxSpaces:
                  matchingGarage.name.isNotEmpty
                      ? matchingGarage.studentMaxSpaces
                      : null,
              lotOtherSpaces:
                  matchingGarage.name.isNotEmpty
                      ? matchingGarage.lotOtherSpaces
                      : 0,
              lotOtherMaxSpaces:
                  matchingGarage.name.isNotEmpty
                      ? matchingGarage.lotOtherMaxSpaces
                      : 0,

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
                      : null,
            );

            sortedGarages.add(garage);
          } catch (e) {
            debugPrint(
              'Could not create garage from data: $garageData - Error: $e',
            );
          }
        }

        return sortedGarages;
      } else {
        debugPrint('n8n request failed with status: ${response.statusCode}');
        debugPrint('Response body: ${response.body}');
        return [];
      }
    } catch (e) {
      debugPrint('Error making n8n request: $e');
      throw e;
    }
  } catch (e) {
    debugPrint('Error getting AI recommendations: $e');
    rethrow;
  }
}
