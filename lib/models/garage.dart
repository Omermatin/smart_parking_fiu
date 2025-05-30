class Garage {
  final String type;
  final String name;
  final int studentSpaces;
  final int studentMaxSpaces;
  final double latitude;
  final double longitude;
  int? availableSpaces;
  double? distanceToClass;
  double? distanceFromOrigin;
  int? lotOtherMaxSpaces;
  int? lotOtherSpaces;
  double? score;

  Garage({
    required this.type,
    required this.name,
    required this.studentSpaces,
    required this.studentMaxSpaces,
    required this.latitude,
    required this.longitude,
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
    if (isGarage) {
      return studentMaxSpaces - studentSpaces;
    } else if (isLot) {
      return (lotOtherMaxSpaces ?? 1) - (lotOtherSpaces ?? 0);
    }
    return 0;
  }

  double calculateAvailabilityPercentage() {
    if (isGarage) {
      return studentMaxSpaces > 0
          ? calculateAvailableSpaces() / studentMaxSpaces
          : 0.0;
    } else if (isLot) {
      return lotOtherMaxSpaces != null && lotOtherMaxSpaces! > 0
          ? calculateAvailableSpaces() / lotOtherMaxSpaces!
          : 0.0;
    }
    return 0.0;
  }

  bool hasAvailableSpaces() {
    return calculateAvailableSpaces() > 0;
  }

  factory Garage.fromJson(Map<String, dynamic> jsonData) {
    final bool isLot = jsonData['type']?.toString().toLowerCase() == 'lot';
    return Garage(
      type: jsonData['type'] ?? '',
      name: jsonData['name'] ?? '',
      studentSpaces: int.tryParse(jsonData['studentSpaces'] ?? '0') ?? 0,
      studentMaxSpaces: int.tryParse(jsonData['studentMaxSpaces'] ?? '1') ?? 1,
      latitude: double.tryParse(jsonData['Latitude'] ?? '0') ?? 0.0,
      longitude: double.tryParse(jsonData['Longitude'] ?? '0') ?? 0.0,
      lotOtherSpaces:
          isLot ? int.tryParse(jsonData['otherSpaces'] ?? '0') ?? 0 : 0,
      lotOtherMaxSpaces:
          isLot ? int.tryParse(jsonData['otherMaxSpaces'] ?? '1') ?? 1 : 0,
    );
  }
}
