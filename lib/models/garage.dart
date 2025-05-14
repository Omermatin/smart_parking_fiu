class Garage {
  final String type;
  final String name;
  final int studentSpaces;
  final int studentMaxSpaces;
  final double latitude;
  final double longitude;
  double? availableSpaces;
  double? distanceToClass;
  double? distanceFromOrigin;
  int? lotOtherMaxSpaces;
  int? lotOtherSpaces;

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
  });
  bool get isLot => type.toLowerCase() == 'lot';
  bool get isGarage => type.toLowerCase() == 'garage';

  factory Garage.fromJson(Map<String, dynamic> jsonData) {
    final int current = int.tryParse(jsonData['studentSpaces'] ?? '0') ?? 0;
    final int max = int.tryParse(jsonData['studentMaxSpaces'] ?? '1') ?? 1;
    final bool isLot = jsonData['type']?.toString().toLowerCase() == 'lot';

    return Garage(
      type: jsonData['type'] ?? '',
      name: jsonData['name'] ?? '',
      studentSpaces: current,
      studentMaxSpaces: max,
      latitude: double.tryParse(jsonData['Latitude'] ?? '0') ?? 0.0,
      longitude: double.tryParse(jsonData['Longitude'] ?? '0') ?? 0.0,
      lotOtherSpaces:
          isLot ? int.tryParse(jsonData['lotOtherSpaces'] ?? '0') ?? 0 : 0,
      lotOtherMaxSpaces:
          isLot ? int.tryParse(jsonData['lotOtherMaxSpaces'] ?? '1') ?? 1 : 0,
    );
  }
  @override
  String toString() {
    return 'Garage(name: $name, Available: $studentSpaces/$studentMaxSpaces, '
        'Location: ($latitude, $longitude))';
  }
}
