class Building {
  final String name;
  final double latitude;
  final double longitude;

  Building({
    required this.name,
    required this.latitude,
    required this.longitude,
  });

  @override
  String toString() {
    return 'Building(code: $name, Location: ($latitude, $longitude))';
  }
}
