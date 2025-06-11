import '../models/garage.dart';

List<Garage> sortGaragesByAvailability(List<Garage> garages) {
  final sorted = List<Garage>.from(garages);
  sorted.sort(
    (a, b) =>
        b.calculateAvailableSpaces().compareTo(a.calculateAvailableSpaces()),
  );
  return sorted;
}

List<Garage> sortGaragesByDistanceFromYou(List<Garage> garages) {
  final sorted = List<Garage>.from(garages);
  sorted.sort((a, b) {
    final distA = a.distanceFromOrigin ?? double.infinity;
    final distB = b.distanceFromOrigin ?? double.infinity;

    return distA.compareTo(distB);
  });
  return sorted;
}

List<Garage> sortGaragesByDistanceFromClass(List<Garage> garages) {
  final sorted = List<Garage>.from(garages);
  sorted.sort((a, b) {
    final distA = a.distanceToClass ?? double.infinity;
    final distB = b.distanceToClass ?? double.infinity;
    return distA.compareTo(distB);
  });
  return sorted;
}

List<Garage> resetToOriginalOrder(List<Garage> garages) {
  return List<Garage>.from(garages);
}
