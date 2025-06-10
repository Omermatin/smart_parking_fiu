class Garage {
  final String type;
  final String name;
  final int? studentSpaces;
  final int? studentMaxSpaces;
  final double? latitude;
  final double? longitude;
  int? availableSpaces;
  double? distanceToClass;
  double? distanceFromOrigin;
  final int? lotOtherMaxSpaces;
  final int? lotOtherSpaces;
  double? score;

  // Cached values
  int? _cachedAvailableSpaces;
  double? _cachedAvailabilityPercentage;

  Garage({
    required this.type,
    required this.name,
    this.studentSpaces,
    this.studentMaxSpaces,
    this.latitude,
    this.longitude,
    this.availableSpaces,
    this.distanceToClass,
    this.distanceFromOrigin,
    this.lotOtherMaxSpaces = 0,
    this.lotOtherSpaces = 0,
    this.score,
  });

  bool get isLot => type.toLowerCase() == 'lot';
  bool get isGarage => type.toLowerCase() == 'garage';

  int calculateAvailableSpaces() {
    // Return cached value if available
    if (_cachedAvailableSpaces != null) return _cachedAvailableSpaces!;

    // If availableSpaces is already set (from AI), use it
    if (availableSpaces != null) {
      _cachedAvailableSpaces = availableSpaces;
      return availableSpaces!;
    }

    // Calculate based on type
    if (isGarage) {
      _cachedAvailableSpaces =
          studentMaxSpaces != null && studentMaxSpaces! > 0
              ? studentMaxSpaces! - (studentSpaces ?? 0)
              : 0;
    } else if (isLot) {
      _cachedAvailableSpaces = (lotOtherMaxSpaces ?? 1) - (lotOtherSpaces ?? 0);
    } else {
      _cachedAvailableSpaces = 0;
    }

    return _cachedAvailableSpaces!;
  }

  double calculateAvailabilityPercentage() {
    // Return cached value if available
    if (_cachedAvailabilityPercentage != null)
      return _cachedAvailabilityPercentage!;

    final available = calculateAvailableSpaces();

    if (isGarage) {
      _cachedAvailabilityPercentage =
          studentMaxSpaces != null && studentMaxSpaces! > 0
              ? available / studentMaxSpaces!
              : 0.0;
    } else if (isLot) {
      _cachedAvailabilityPercentage =
          lotOtherMaxSpaces != null && lotOtherMaxSpaces! > 0
              ? available / lotOtherMaxSpaces!
              : 0.0;
    } else {
      _cachedAvailabilityPercentage = 0.0;
    }

    return _cachedAvailabilityPercentage!;
  }

  bool hasAvailableSpaces() {
    return calculateAvailableSpaces() > 0;
  }

  factory Garage.fromJson(Map<String, dynamic> jsonData) {
    final bool isLot = jsonData['type']?.toString().toLowerCase() == 'lot';

    return Garage(
      type: jsonData['type']?.toString() ?? '',
      name: jsonData['name']?.toString() ?? '',
      studentSpaces: _parseIntSafely(jsonData['studentSpaces']),
      studentMaxSpaces: _parseIntSafely(jsonData['studentMaxSpaces']) ?? 1,
      latitude: _parseDoubleSafely(jsonData['Latitude']),
      longitude: _parseDoubleSafely(jsonData['Longitude']),
      lotOtherSpaces: isLot ? _parseIntSafely(jsonData['otherSpaces']) ?? 0 : 0,
      lotOtherMaxSpaces:
          isLot ? _parseIntSafely(jsonData['otherMaxSpaces']) ?? 1 : 0,
    );
  }

  // Helper methods for safe parsing
  static int? _parseIntSafely(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is String) return int.tryParse(value);
    return null;
  }

  static double? _parseDoubleSafely(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  @override
  String toString() {
    return 'Garage(name: $name, student spaces: $studentSpaces, Max Space: $studentMaxSpaces, lot max Space: $lotOtherMaxSpaces, lot Spaces: $lotOtherSpaces,type: $type, score: $score)';
  }
}
