import 'package:flutter/material.dart';
import '../models/garage.dart';
import '../pages/homepage.dart'; // For AppColors

class GarageListItem extends StatelessWidget {
  final Garage garage;

  const GarageListItem({required this.garage, super.key});

  // Helper method to format distance
  String formatDistance(double? distance) {
    if (distance == null) return 'N/A';
    return '${distance.toStringAsFixed(2)} miles';
  }

  @override
  Widget build(BuildContext context) {
    // Calculate values once outside of widget tree to reduce build time
    final isLot = garage.type.toLowerCase() == 'lot';
    final availability = garage.calculateAvailabilityPercentage();
    final availabilityColor = _getColorBasedOnAvailability(availability);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(15.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Icon(
                        isLot ? Icons.local_parking : Icons.garage,
                        color: AppColors.primary,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          garage.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  width: 163,
                  child: Text(
                    'Spaces Available: ${garage.availableSpaces}',
                    style: TextStyle(
                      fontSize: 15,
                      color: Colors.grey[700],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.only(top: 4.0),
              child: Text(
                isLot ? 'Parking Lot' : 'Parking Garage',
                style: TextStyle(
                  fontSize: 14,
                  fontStyle: FontStyle.italic,
                  color: Colors.grey[600],
                ),
              ),
            ),
            const SizedBox(height: 10),
            if (garage.distanceToClass != null)
              Row(
                children: [
                  Icon(Icons.school, size: 18, color: Colors.grey[600]),
                  const SizedBox(width: 6),
                  Text(
                    'To class: ${formatDistance(garage.distanceToClass)}',
                    style: TextStyle(fontSize: 15, color: Colors.grey[700]),
                  ),
                ],
              ),
            if (garage.distanceFromOrigin != null)
              Padding(
                padding: const EdgeInsets.only(top: 4.0),
                child: Row(
                  children: [
                    Icon(Icons.my_location, size: 18, color: Colors.grey[600]),
                    const SizedBox(width: 6),
                    Text(
                      'From you: ${formatDistance(garage.distanceFromOrigin)}',
                      style: TextStyle(fontSize: 15, color: Colors.grey[700]),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: availability,
                      backgroundColor: Colors.grey[300],
                      valueColor: AlwaysStoppedAnimation<Color>(
                        availabilityColor,
                      ),
                      minHeight: 8,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Helper method to determine color based on availability
  Color _getColorBasedOnAvailability(double availability) {
    if (availability > 0.5) return Colors.green;
    if (availability > 0.2) return Colors.orange;
    return Colors.red;
  }
}
