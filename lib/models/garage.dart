class Garage {
  final String type;
  final String name;
  final int studentSpaces;
  final int studentMaxSpaces;
  //final double availablePercent; 
  final double latitude;
  final double longitude;

  const Garage({
    required this.type,
    required this.name,
    required this.studentSpaces,
    required this.studentMaxSpaces,
    //required this.availablePercent,
    required this.latitude,
    required this.longitude,
  });

  factory Garage.fromJson(Map<String, dynamic> jsonData) {
    final int current = int.tryParse(jsonData['studentSpaces'] ?? '0') ?? 0;
    final int max = int.tryParse(jsonData['studentMaxSpaces'] ?? '1') ?? 1;

    return Garage(
      type: jsonData['type'] ?? '',
      name: jsonData['name'] ?? '',
      studentSpaces: current,
      studentMaxSpaces: max,
      // availablePercent: (max > 0) ? (current / max * 100) : 0.0
      latitude: double.tryParse(jsonData['Latitude'] ?? '0') ?? 0.0,
      longitude: double.tryParse(jsonData['Longitude'] ?? '0') ?? 0.0,
    );
  }
  @override
  String toString(){
    return 'Garage(name: $name, Available: $studentSpaces/$studentMaxSpaces, '
           'Location: ($latitude, $longitude))';
  }
}
