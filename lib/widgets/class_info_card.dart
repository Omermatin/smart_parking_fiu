import 'package:flutter/material.dart';
import '../models/class_schedule.dart';
import '../pages/homepage.dart';
import '../util/class_schedule_parser.dart';

class ClassInfoCard extends StatelessWidget {
  final ClassSchedule classSchedule;

  const ClassInfoCard({super.key, required this.classSchedule});

  @override
  Widget build(BuildContext context) {
    final bool isInProgress = _isClassInProgress();
    final Color statusColor = Colors.black;

    return Card(
      color: AppColors.backgroundwidget,
      margin: const EdgeInsets.all(16.0),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with course name and status
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.school, color: AppColors.primary, size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        classSchedule.courseName,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: statusColor),
                        ),
                        child: Text(
                          isInProgress ? 'In Progress' : 'Upcoming',
                          style: TextStyle(
                            color: statusColor,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),
            const Divider(height: 1),
            const SizedBox(height: 16),

            // Class details grid
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

            const SizedBox(height: 2),

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
                    Icons.book,
                    'Subject',
                    classSchedule.subject,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem(IconData icon, String label, String value) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(8)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(color: Colors.grey[600], fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 1),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
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

  String? _getTimeUntilClass() {
    final now = DateTime.now();
    final startTime = ClassScheduleParser.parseTime(
      classSchedule.meetingTimeStart,
    );

    if (startTime == null || now.isAfter(startTime)) return null;

    final difference = startTime.difference(now);
    final hours = difference.inHours;
    final minutes = difference.inMinutes % 60;

    if (hours > 0) {
      return 'Class starts in $hours hour${hours > 1 ? 's' : ''} $minutes min';
    } else {
      return 'Class starts in $minutes minute${minutes > 1 ? 's' : ''}';
    }
  }
}
