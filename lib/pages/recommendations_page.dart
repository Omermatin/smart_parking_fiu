import 'package:flutter/material.dart';
import '../models/garage.dart';
import '../models/class_schedule.dart';
import '../pages/homepage.dart';  
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
  String isActive = "";

  @override
  void initState() {
    super.initState();
    _currentRecommendations = widget.recommendations;
  }

  void _sortByDistanceFromClass() {
    setState(() {
      isActive = "Distance from class";
      _currentRecommendations = sortGaragesByDistance(_currentRecommendations);
    });
  }

  void _sortByAvailability() {
    setState(() {
      isActive = "Availability";
      _currentRecommendations = sortGaragesByAvailability(
        _currentRecommendations,
      );
    });
  }

  void _sortByDistanceFromYou() {
    setState(() {
      isActive = "Distance from you";
      _currentRecommendations = sortGaragesByDistanceFromYou(
        _currentRecommendations,
      );
    });
  }

  Future<void> _refreshRecommendations() async {
    setState(() {
      isActive = "";
      _isRefreshing = true;
    });

    try {
    
      final position = await Geolocator.getCurrentPosition();

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
              ClassInfoCard(classSchedule: widget.classSchedule),

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
                      color: isActive == "Distance from class"
                          ? AppColors.primary
                          : null,
                      textColor: isActive == "Distance from class"
                          ? Colors.white
                          : null,
                    ),
                    const SizedBox(width: 8),
                    MyButton(
                      text: "Availability",
                      onPressed: _sortByAvailability,
                      color: isActive == "Availability"
                          ? AppColors.primary
                          : null,
                      textColor: isActive == "Availability"
                          ? Colors.white
                          : null,
                    ),
                    const SizedBox(width: 8),
                    MyButton(
                      text: "Distance from you",
                      onPressed: _sortByDistanceFromYou,
                      color: isActive == "Distance from you"
                          ? AppColors.primary
                          : null,
                      textColor: isActive == "Distance from you"
                          ? Colors.white
                          : null,
                    ),
                  ],
                ),
              ),
  
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
