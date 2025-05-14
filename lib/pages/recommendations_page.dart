import 'package:flutter/material.dart';
import '../models/garage.dart';
import '../models/class_schedule.dart';
import '../pages/homepage.dart'; // For AppColors

class RecommendationsPage extends StatelessWidget {
  final List<Garage> recommendations;
  final ClassSchedule classSchedule;

  const RecommendationsPage({
    Key? key,
    required this.recommendations,
    required this.classSchedule,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Parking Recommendations'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Class information card
          _buildClassInfoCard(),

          // Recommendations heading
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                const Text(
                  'Recommended Parking',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                Text(
                  '${recommendations.length} options',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ],
            ),
          ),

          // Recommendations list
          Expanded(
            child:
                recommendations.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                      itemCount: recommendations.length,
                      itemBuilder: (context, index) {
                        return GarageListItem(garage: recommendations[index]);
                      },
                    ),
          ),
        ],
      ),
    );
  }

  Widget _buildClassInfoCard() {
    return Card(
      margin: const EdgeInsets.all(16.0),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.school, color: AppColors.primary, size: 24),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    classSchedule.courseName,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildInfoItem(
                    Icons.location_on,
                    'Building',
                    classSchedule.buildingCode,
                  ),
                ),
                Expanded(
                  child: _buildInfoItem(
                    Icons.access_time,
                    'Time',
                    '${classSchedule.meetingTimeStart} - ${classSchedule.meetingTimeEnd}',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _buildInfoItem(
                    Icons.calendar_today,
                    'Days',
                    classSchedule.meetingDays,
                  ),
                ),
                Expanded(
                  child: _buildInfoItem(
                    Icons.info_outline,
                    'Status',
                    classSchedule.today == 'true' ? 'In Progress' : 'Upcoming',
                    color:
                        classSchedule.today == 'true'
                            ? Colors.green
                            : Colors.orange,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem(
    IconData icon,
    String label,
    String value, {
    Color? color,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
        const SizedBox(height: 4),
        Row(
          children: [
            Icon(icon, size: 16, color: color ?? Colors.grey[700]),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                value,
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  color: color ?? Colors.black87,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
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
