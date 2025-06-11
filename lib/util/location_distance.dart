import 'package:geolocator/geolocator.dart';
import 'package:flutter/foundation.dart';
import 'dart:math';

class LocationService {
  static Position? _currentPosition;
  static bool _isInitializing = false;

  // Initialize location once
  static Future<void> initializeUserLocation() async {
    if (_currentPosition != null || _isInitializing) return;

    _isInitializing = true;
    try {
      _currentPosition = await _determinePosition();
    } catch (e) {
      debugPrint("Error initializing location: $e");
      _currentPosition = null;
    } finally {
      _isInitializing = false;
    }
  }

  // Fetch user's location
  static Future<Position> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Check location
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('Location services are disabled.');
    }

    // Request permission
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

    return await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
      timeLimit: const Duration(seconds: 5),
    );
  }

  static Position? get currentPosition => _currentPosition;
}

// Function to calculate distance
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
