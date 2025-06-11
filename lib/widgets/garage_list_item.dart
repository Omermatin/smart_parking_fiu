import 'package:flutter/material.dart';
import '../models/garage.dart';
import '../pages/homepage.dart';

class GarageListItem extends StatelessWidget {
  final Garage garage;

  const GarageListItem({required this.garage, super.key});

  String formatDistance(double? miles) {
    if (miles == null) return '–';
    return '${miles.toStringAsFixed(2)} mi';
  }

  @override
  Widget build(BuildContext context) {
    final isLot = garage.type.toLowerCase() == 'lot';
    final availableSpaces = garage.calculateAvailableSpaces();
    final maxSpaces =
        garage.type.toLowerCase() == 'lot'
            ? (garage.lotOtherMaxSpaces ?? 1)
            : (garage.studentMaxSpaces ?? 1);
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
                  SizedBox(
                    width: 166,
                    child: RichText(
                      textAlign: TextAlign.right,
                      text: TextSpan(
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.bold,
                        ),

                        children: [
                          TextSpan(
                            text:
                                isLot
                                    ? 'All Spaces: $availableSpaces'
                                    : 'Student Spaces: $availableSpaces',
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Distance Information
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (garage.distanceToClass != null)
                    Row(
                      children: [
                        Icon(Icons.school, size: 16, color: Colors.grey[600]),
                        const SizedBox(width: 4),
                        Text(
                          "From class: ${formatDistance(garage.distanceToClass)}",
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[700],
                          ),
                        ),
                      ],
                    ),
                  if (garage.distanceFromOrigin != null)
                    Row(
                      children: [
                        Icon(
                          Icons.my_location,
                          size: 16,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          "From you: ${formatDistance(garage.distanceFromOrigin)}",
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[700],
                          ),
                        ),
                      ],
                    ),
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
