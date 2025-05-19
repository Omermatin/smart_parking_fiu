import 'package:flutter/material.dart';
import '../models/garage.dart';
import '../models/class_schedule.dart';
import '../pages/homepage.dart'; // For AppColors
import '../widgets/garage_list_item.dart';
import '../widgets/class_info_card.dart';
import '../widgets/empty_recommendations.dart';

class RecommendationsPage extends StatefulWidget {
  final List<Garage> recommendations;
  final ClassSchedule classSchedule;

  const RecommendationsPage({
    super.key,
    required this.recommendations,
    required this.classSchedule,
  });

  @override
  State<RecommendationsPage> createState() => _RecommendationsPageState();
}

class _RecommendationsPageState extends State<RecommendationsPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Parking Recommendations'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SafeArea(
        child: ListView(
          children: [
            // Class Information Card
            ClassInfoCard(classSchedule: widget.classSchedule),

            // Recommendations Heading
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
                    '${widget.recommendations.length} options',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
            ),

            // Recommendations List or Empty State
            widget.recommendations.isEmpty
                ? const EmptyRecommendations()
                : ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: widget.recommendations.length,
                  itemBuilder: (context, index) {
                    return GarageListItem(
                      garage: widget.recommendations[index],
                    );
                  },
                ),
          ],
        ),
      ),
    );
  }
}
