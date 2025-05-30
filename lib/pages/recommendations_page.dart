import 'package:flutter/material.dart';
import '../models/garage.dart';
import '../models/class_schedule.dart';
import '../pages/homepage.dart';
import '../widgets/garage_list_item.dart';
import '../widgets/class_info_card.dart';
import '../widgets/empty_recommendations.dart';
import '../util/logic.dart';
import '../util/class_schedule_parser.dart';
import 'package:geolocator/geolocator.dart';
import '../services/api_service.dart';

class RecommendationsPage extends StatefulWidget {
  final List<Garage> recommendations;
  final Map<String, dynamic> fullScheduleJson;

  const RecommendationsPage({
    super.key,
    required this.recommendations,
    required this.fullScheduleJson,
  });

  @override
  State<RecommendationsPage> createState() => _RecommendationsPageState();
}

class _RecommendationsPageState extends State<RecommendationsPage> {
  List<Garage> _currentRecommendations = [];
  bool _isRefreshing = false;
  ClassSchedule? _currentClass;

  @override
  void initState() {
    super.initState();
    _currentRecommendations = widget.recommendations;
    _currentClass = ClassScheduleParser.getCurrentOrUpcomingClass(
      widget.fullScheduleJson,
    );
  }

  Future<void> _refreshRecommendations() async {
    setState(() {
      _isRefreshing = true;
    });

    try {
      final position = await Geolocator.getCurrentPosition();

      if (_currentClass == null) {
        throw Exception('No current class available');
      }

      final todaySchedule = ClassScheduleParser.getAllTodayClasses(
        widget.fullScheduleJson,
      );

      final newRecommendations = await getAIRecommendations(
        _currentClass!.pantherId,
        position.longitude,
        position.latitude,
        todaySchedule,
        await fetchParking(),
        await fetchBuilding(),
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
        title: const Text('AI Parking Recommendations'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _refreshRecommendations,
          child: ListView(
            children: [
              if (_currentClass != null)
                ClassInfoCard(classSchedule: _currentClass!),

              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    const Text(
                      'AI-Powered Recommendations',
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
