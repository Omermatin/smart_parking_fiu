import 'package:flutter/material.dart';
import '../models/garage.dart';
import '../pages/homepage.dart';

class GarageListItem extends StatelessWidget {
  final Garage garage;

  const GarageListItem({required this.garage, super.key});

  String formatDistance(double? distance) {
    if (distance == null) return 'N/A';
    if (distance < 0.1) return '< 0.1 miles';
    return '${distance.toStringAsFixed(1)} miles';
  }

  @override
  Widget build(BuildContext context) {
    final isLot = garage.type.toLowerCase() == 'lot';
    final availableSpaces = garage.calculateAvailableSpaces();
    final maxSpaces = garage.studentMaxSpaces ?? 1;
    final availability = availableSpaces / maxSpaces;

    return Card(
      color: AppColors.backgroundwidget,
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () {
          // Future: Add navigation to garage details
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Icon(
                          isLot ? Icons.local_parking : Icons.garage,
                          color: AppColors.primary,
                          size: 24,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                garage.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                  color: Color.fromARGB(255, 2, 33, 80),
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                isLot ? 'Parking Lot' : 'Parking Garage',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Availability Badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '$availableSpaces ${isLot ? "spaces" : "student spots"}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Distance Information
              Row(
                children: [
                  if (garage.distanceToClass != null) ...[
                    Icon(Icons.school, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(
                      formatDistance(garage.distanceToClass),
                      style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                    ),
                    const SizedBox(width: 16),
                  ],
                  if (garage.distanceFromOrigin != null) ...[
                    Icon(Icons.my_location, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(
                      formatDistance(garage.distanceFromOrigin),
                      style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                    ),
                  ],
                ],
              ),

              const SizedBox(height: 12),

              // Availability Bar
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Availability',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                      Text(
                        '${(availability * 100).toInt()}%',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: availability,
                      backgroundColor: Colors.grey[300],
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
                      minHeight: 6,
                    ),
                  ),
                ],
              ),

              // AI Score indicator (if available)
              if (garage.score != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.auto_awesome,
                      size: 14,
                      color: Colors.amber[700],
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'AI Score: ${garage.score!.toStringAsFixed(1)}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.amber[700],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
