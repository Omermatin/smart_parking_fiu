import '../models/garage.dart';
import '../models/building.dart';
import 'dart:math';

class ScoreCalculator {
  static double calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const double radius = 6378137; // Earth's radius in meters
    double dLat = _degToRad(lat2 - lat1);
    double dLon = _degToRad(lon2 - lon1);
    double a = pow(sin(dLat / 2), 2) +
        cos(_degToRad(lat1)) * cos(_degToRad(lat2)) * pow(sin(dLon / 2), 2);
    double c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return radius * c;
  }

  // Main scoring function
  static double calculateScore(Garage garage, Building classBuilding, DateTime classStartTime) {
    double distance = calculateDistance(
      classBuilding.latitude, classBuilding.longitude,
      garage.latitude, garage.longitude,
    );

    // Availability percentage
    double availabilityPercent = (garage.studentSpaces / garage.studentMaxSpaces) * 100;
    
    // Score calculation (Weights: 0.5 for distance, 0.3 for availability, 0.2 for urgency)
    double score = (0.5 / distance) + (0.5 * availabilityPercent);
    return score;
  }

  // Helper: Convert degrees to radians
  static double _degToRad(double deg) {
    return deg * (pi / 180);
  }

  // Recommend top three garages
  static List<Garage> recommendTopThreeGarages(
      List<Garage> garages, Building classBuilding, DateTime classStartTime) {
    for (var garage in garages) {
      garage.score = calculateScore(garage, classBuilding, classStartTime);
    }

    garages.sort((a, b) => b.score.compareTo(a.score));
    return garages.take(3).toList();
  }
}