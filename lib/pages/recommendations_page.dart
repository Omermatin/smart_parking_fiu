import 'package:flutter/material.dart';
import '../models/garage.dart';
import '../models/class_schedule.dart';
import '../pages/homepage.dart'; // For AppColors
import '../widgets/garage_list_item.dart';
import '../widgets/class_info_card.dart';
import '../widgets/empty_recommendations.dart';
import '../util/logic.dart';
import 'package:geolocator/geolocator.dart';
import '../widgets/buttons.dart';

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
  List<Garage> _currentRecommendations = [];
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    _currentRecommendations = widget.recommendations;
  }

  void _sortByDistanceFromClass() {
    setState(() {
      _currentRecommendations = sortGaragesByDistance(_currentRecommendations);
    });
  }

  void _sortByAvailability() {
    setState(() {
      _currentRecommendations = sortGaragesByAvailability(_currentRecommendations);
    });
  }
  void _sortByDistanceFromYou() {
    setState(() {
      _currentRecommendations = sortGaragesByDistanceFromYou(_currentRecommendations);
    });
  }

  Future<void> _refreshRecommendations() async {
    setState(() {
      _isRefreshing = true;
    });

    try {
      // Get current position
      final position = await Geolocator.getCurrentPosition();

      // Fetch new recommendations
      final newRecommendations = await recommendations(
        widget.classSchedule.pantherId,
        position.longitude,
        position.latitude,
        widget.classSchedule,
      );

      setState(() {
        _currentRecommendations = newRecommendations;
        _isRefreshing = false;
      });
    } catch (e) {
      setState(() {
        _isRefreshing = false;
      });
      // Show error message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to refresh: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 249, 249, 250),
      appBar: AppBar(
        title: const Text('Parking Recommendations'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _refreshRecommendations,
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
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${_currentRecommendations.length} options',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    const SizedBox(width: 8),
                    MyButton(
                      text: "Distance from class",
                      onPressed: _sortByDistanceFromClass,
                    ),
                    const SizedBox(width: 8),
                    MyButton(text: "Availability", onPressed: _sortByAvailability),
                    const SizedBox(width: 8),
                    MyButton(text: "Distance from you", onPressed: _sortByDistanceFromYou),
                  ],
                ),
              ),

              // Garage List
              if (_currentRecommendations.isEmpty)
                const EmptyRecommendations()
              else
                ..._currentRecommendations.map(
                  (garage) => GarageListItem(garage: garage),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
