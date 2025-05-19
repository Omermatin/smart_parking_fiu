import 'package:flutter/material.dart';

class EmptyRecommendations extends StatelessWidget {
  const EmptyRecommendations({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.no_transfer, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'No parking recommendations available',
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          Text(
            'Try another time or check back later',
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }
}
