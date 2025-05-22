// garage_recommendation_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:smart_parking_fiu/models/garage.dart';
import 'package:smart_parking_fiu/services/api_service.dart';
import 'package:smart_parking_fiu/util/garage_parser.dart';
import 'package:smart_parking_fiu/util/logic.dart';

// MMC buildings data for testing
final List<Map<String, dynamic>> mmcBuildingsData = [
  {
    'code': 'AHC1',
    'name': 'Academic Health Center 1',
    'latitude': 25.757627,
    'longitude': -80.371426,
  },
  {
    'code': 'AHC2',
    'name': 'Academic Health Center 2',
    'latitude': 25.7581,
    'longitude': -80.371276,
  },
  {
    'code': 'AHC3',
    'name': 'Academic Health Center 3',
    'latitude': 25.758859,
    'longitude': -80.371412,
  },
  {
    'code': 'AHC4',
    'name': 'Academic Health Center 4',
    'latitude': 25.759294,
    'longitude': -80.372191,
  },
  {
    'code': 'AHC5',
    'name': 'Academic Health Center 5',
    'latitude': 25.759282,
    'longitude': -80.371247,
  },
  {
    'code': 'ASTRO',
    'name': 'Stocker Astroscience Center',
    'latitude': 25.757895,
    'longitude': -80.372487,
  },
  {
    'code': 'BBS',
    'name': 'FIU Baseball Stadium',
    'latitude': 25.754078,
    'longitude': -80.381326,
  },
  {
    'code': 'CBC',
    'name': 'College Of Business Complex',
    'latitude': 25.758028,
    'longitude': -80.377019,
  },
  {
    'code': 'CASE',
    'name': 'Computing, Arts, Sciences & Education',
    'latitude': 25.759031,
    'longitude': -80.373898,
  },
  {
    'code': 'CP',
    'name': 'Chemistry & Physics',
    'latitude': 25.75844,
    'longitude': -80.37223,
  },
  {
    'code': 'DM',
    'name': 'Deuxieme Maison',
    'latitude': 25.756161,
    'longitude': -80.374675,
  },
  {
    'code': 'EH',
    'name': 'Everglades Hall',
    'latitude': 25.753775,
    'longitude': -80.37538,
  },
  {
    'code': 'GC',
    'name': 'Ernest R. Graham University Center',
    'latitude': 25.756358,
    'longitude': -80.37273,
  },
  {
    'code': 'GL',
    'name': 'Steven & Dorothea Green Library',
    'latitude': 25.757201,
    'longitude': -80.373829,
  },
  {
    'code': 'OE',
    'name': 'Owa Ehan',
    'latitude': 25.758061,
    'longitude': -80.372847,
  },
  {
    'code': 'PC',
    'name': 'Charles E. Perry Primera Casa',
    'latitude': 25.755525,
    'longitude': -80.373781,
  },
  {
    'code': 'SASC',
    'name': 'Student Academic Success Center',
    'latitude': 25.755493,
    'longitude': -80.37145,
  },
  {
    'code': 'SIPA',
    'name': 'School of International & Public Affairs 1',
    'latitude': 25.756528,
    'longitude': -80.376029,
  },
  {
    'code': 'SIPA2',
    'name': 'School of International & Public Affairs 2',
    'latitude': 25.756493,
    'longitude': -80.376679,
  },
  {
    'code': 'VH',
    'name': 'Viertes Haus',
    'latitude': 25.757977,
    'longitude': -80.374735,
  },
  {
    'code': 'PBST',
    'name': 'Pitbull Stadium',
    'latitude': 25.752522,
    'longitude': -80.377879,
  },
  {
    'code': 'RDB',
    'name': 'Rafael Diaz-Balart Hall',
    'latitude': 25.756768,
    'longitude': -80.37786,
  },
  {
    'code': 'WRC',
    'name': 'Wellness And Recreation Center',
    'latitude': 25.755977,
    'longitude': -80.378057,
  },
  {
    'code': 'PCA',
    'name': 'Paul Cejas Architecture',
    'latitude': 25.758965,
    'longitude': -80.37545,
  },
  {
    'code': 'PPFAM',
    'name': 'Patricia and Phillip Frost Art Museum',
    'latitude': 25.753668,
    'longitude': -80.373085,
  },
  {
    'code': 'ZEB',
    'name': 'Sanford L. Ziff Family Education Building',
    'latitude': 25.759017,
    'longitude': -80.376746,
  },
];

// Simplified Building class for testing
class TestBuilding {
  final String code;
  final String name;
  final double latitude;
  final double longitude;

  TestBuilding({
    required this.code,
    required this.name,
    required this.latitude,
    required this.longitude,
  });
}

// Convert data to TestBuilding objects
TestBuilding convertToTestBuilding(Map<String, dynamic> data) {
  return TestBuilding(
    code: data['code'],
    name: data['name'],
    latitude: data['latitude'],
    longitude: data['longitude'],
  );
}

// Modified version of updateGaragesWithMetrics for TestBuilding
void updateGaragesWithTestBuilding(
  List<Garage> garages,
  TestBuilding building,
  double originLat,
  double originLon,
) {
  for (var garage in garages) {
    garage.distanceToClass = calculateDistance(
      building.latitude,
      building.longitude,
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

// Main test function
Future<void> testGarageRecommendationsForAllBuildings() async {
  // Load environment variables if needed
  if (dotenv.env.isEmpty) {
    await dotenv.load();
  }

  // Define a fixed user location (e.g., main entrance of FIU)
  double userLatitude = 25.7617; // Main entrance
  double userLongitude = -80.1918;

  debugPrint('\nTESTING GARAGE RECOMMENDATIONS FOR ALL MMC BUILDINGS');
  debugPrint('User location: ($userLatitude, $userLongitude)');
  debugPrint('==================================================\n');

  // Fetch real-time parking data once
  final parkingData = await fetchParking();
  if (parkingData == null) {
    debugPrint("Failed to fetch parking data from API");
    return;
  }

  // Parse garages using your existing parser
  final garages = GarageParser.parseGarages(parkingData);
  debugPrint('Fetched data for ${garages.length} garages\n');

  // Store results for analysis
  List<Map<String, dynamic>> testResults = [];

  // Test each building
  for (var buildingData in mmcBuildingsData) {
    // Convert to TestBuilding object
    TestBuilding building = convertToTestBuilding(buildingData);

    debugPrint('---------------------------------------------');
    debugPrint('TESTING FOR: ${building.name} (${building.code})');
    debugPrint('---------------------------------------------');

    // Make a copy of the garages to avoid modifying the originals
    List<Garage> garageCopy = [...garages];

    // Update metrics for this building using our custom function
    updateGaragesWithTestBuilding(
      garageCopy,
      building,
      userLatitude,
      userLongitude,
    );

    // Sort garages using your existing algorithm
    List<Garage> sortedGarages = sortGaragesByAdaptiveScores(garageCopy);

    if (sortedGarages.isEmpty) {
      debugPrint('NO RECOMMENDATIONS AVAILABLE');
      continue;
    }

    // Save results
    Map<String, dynamic> result = {
      'buildingCode': building.code,
      'buildingName': building.name,
      'topRecommendation': sortedGarages.first.name,
      'recommendations':
          sortedGarages
              .map(
                (g) => {
                  'name': g.name,
                  'distanceToClass': g.distanceToClass,
                  'availableSpaces': g.availableSpaces,
                  'distanceFromOrigin': g.distanceFromOrigin,
                },
              )
              .toList(),
    };
    testResults.add(result);

    // Print best recommendation
    debugPrint('BEST GARAGE: ${sortedGarages.first.name}');
    debugPrint(
      '  Distance to building: ${formatDistance(sortedGarages.first.distanceToClass)}',
    );
    debugPrint('  Available spaces: ${sortedGarages.first.availableSpaces}');
    debugPrint(
      '  Distance from user: ${formatDistance(sortedGarages.first.distanceFromOrigin)}',
    );

    // Print all recommendations
    debugPrint('\nALL RECOMMENDATIONS (in order):');
    for (int i = 0; i < sortedGarages.length; i++) {
      var garage = sortedGarages[i];
      debugPrint(
        '  ${i + 1}. ${garage.name}: ${formatDistance(garage.distanceToClass)} to building, '
        '${garage.availableSpaces} spaces available, '
        '${formatDistance(garage.distanceFromOrigin)} from user',
      );
    }
    debugPrint('');
  }

  // Generate summary
  debugPrint('==================================================');
  debugPrint('SUMMARY OF ALL TESTS');
  debugPrint('==================================================');

  // Count frequency of top recommendations
  Map<String, int> topChoiceCounts = {};
  for (var result in testResults) {
    String garageName = result['topRecommendation'];
    topChoiceCounts[garageName] = (topChoiceCounts[garageName] ?? 0) + 1;
  }

  // Sort by frequency
  var sortedCounts =
      topChoiceCounts.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));

  debugPrint('Top recommended garages by frequency:');
  for (var entry in sortedCounts) {
    double percentage = entry.value / testResults.length * 100;
    debugPrint(
      '  ${entry.key}: ${entry.value} times (${percentage.toStringAsFixed(1)}%)',
    );
  }

  debugPrint('\nTotal buildings tested: ${testResults.length}');

  // Generate table of buildings and their recommended garages
  debugPrint('\nDetailed Recommendations:');
  debugPrint(
    '-------------------------------------------------------------------------',
  );
  debugPrint(
    '| Building Code | Building Name                    | Top Recommendation |',
  );
  debugPrint(
    '-------------------------------------------------------------------------',
  );

  for (var result in testResults) {
    String buildingCode = result['buildingCode'].padRight(14);
    String buildingName = result['buildingName'];
    if (buildingName.length > 30) {
      buildingName = buildingName.substring(0, 27) + '...';
    } else {
      buildingName = buildingName.padRight(30);
    }
    String topRec = result['topRecommendation'];

    debugPrint('| $buildingCode | $buildingName | $topRec');
  }
  debugPrint(
    '-------------------------------------------------------------------------',
  );
}

// Helper function for formatting distance
String formatDistance(double? distance) {
  if (distance == null) return 'N/A';
  return '${distance.toStringAsFixed(2)} mi';
}

// Call this function from your app to run the test
void runGarageRecommendationTest() async {
  await testGarageRecommendationsForAllBuildings();
}
