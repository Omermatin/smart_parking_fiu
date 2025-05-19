import 'package:flutter/material.dart';
import '../models/class_schedule.dart';
import '../pages/homepage.dart'; // For AppColors
import '../util/class_schedule_parser.dart';

class ClassInfoCard extends StatelessWidget {
  final ClassSchedule classSchedule;

  const ClassInfoCard({super.key, required this.classSchedule});

  @override
  Widget build(BuildContext context) {
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
                    _isClassInProgress() ? 'In Progress' : 'Upcoming',
                    color: _isClassInProgress() ? Colors.green : Colors.orange,
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

  bool _isClassInProgress() {
    final now = DateTime.now();
    final startTime = ClassScheduleParser.parseTime(
      classSchedule.meetingTimeStart,
    );
    final endTime = ClassScheduleParser.parseTime(classSchedule.meetingTimeEnd);

    if (startTime == null || endTime == null) return false;

    return now.isAfter(startTime) && now.isBefore(endTime);
  }
}
