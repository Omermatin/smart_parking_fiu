import 'package:flutter/material.dart';
import '../models/garage.dart';
import '../models/class_schedule.dart';
import '../pages/homepage.dart';
import '../widgets/garage_list_item.dart';
import '../widgets/class_info_card.dart';
import '../widgets/empty_recommendations.dart';
import '../util/logic.dart';
import '../util/class_schedule_parser.dart';
import '../util/building_parser.dart';
import 'package:geolocator/geolocator.dart';
import '../widgets/buttons.dart';
import '../services/api_service.dart';
import '../util/error_handler.dart';
import '../util/constants.dart';
import '../util/custom_sort.dart';
import '../util/location_distance.dart';

class RecommendationsPage extends StatefulWidget {
  final List<Garage> recommendations;
  final Map<String, dynamic> fullScheduleJson;
  final Position userPosition;
  final String pantherId;
  final dynamic buildingData;

  const RecommendationsPage({
    super.key,
    required this.recommendations,
    required this.fullScheduleJson,
    required this.userPosition,
    required this.pantherId,
    required this.buildingData,
  });

  @override
  State<RecommendationsPage> createState() => _RecommendationsPageState();
}

class _RecommendationsPageState extends State<RecommendationsPage> {
  List<Garage> _currentRecommendations = [];
  List<Garage> _originalRecommendations = [];
  bool _isRefreshing = false;
  String _activeSort = "";
  ClassSchedule? _currentClass;

  @override
  void initState() {
    super.initState();
    _originalRecommendations = List.from(widget.recommendations);
    _currentRecommendations = List.from(widget.recommendations);
    _currentClass = ClassScheduleParser.getCurrentOrUpcomingClass(
      widget.fullScheduleJson,
    );
    _calculateDistancesToClass();
  }

  void _calculateDistancesToClass() {
    if (_currentClass == null) return;

    final building = getBuildingByCode(_currentClass!.buildingCode);
    if (building == null) return;

    for (final garage in _currentRecommendations) {
      garage.distanceToClass =
          calculateDistance(
            building.latitude,
            building.longitude,
            garage.latitude,
            garage.longitude,
          ).toDouble() /
          1609.34; // Convert to miles
    }
  }

  void _updateSorting(String sortType) {
    setState(() {
      if (_activeSort == sortType) {
        // Reset to original order
        _activeSort = "";
        _currentRecommendations = resetToOriginalOrder(
          _originalRecommendations,
        );
      } else {
        _activeSort = sortType;
        switch (sortType) {
          case "Distance from class":
            _currentRecommendations = sortGaragesByDistanceFromClass(
              _currentRecommendations,
            );
            break;
          case "Availability":
            _currentRecommendations = sortGaragesByAvailability(
              _currentRecommendations,
            );
            break;
          case "Distance from you":
            _currentRecommendations = sortGaragesByDistanceFromYou(
              _currentRecommendations,
            );
            break;
        }
      }
    });
  }

  Future<void> _refreshRecommendations() async {
    if (_isRefreshing) return;

    setState(() {
      _isRefreshing = true;
    });

    try {
      final stopwatch = Stopwatch()..start();

      // PRESERVE current class if it's null
      if (_currentClass == null || _currentClass!.pantherId.isEmpty) {
        _currentClass = ClassScheduleParser.getCurrentOrUpcomingClass(
          widget.fullScheduleJson,
        );
      }
      // Get fresh location
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: AppConstants.locationTimeout,
      );

      if (_currentClass == null) {
        throw Exception('No current class available');
      }

      final todaySchedule = ClassScheduleParser.getAllTodayClasses(
        widget.fullScheduleJson,
      );

      // Fetch fresh parking data (building data is cached)
      final parkingData = await fetchParking();
      if (parkingData == null) {
        throw Exception('Failed to fetch parking data');
      }

      final newRecommendations = await getAIRecommendationsOptimized(
        _currentClass!.pantherId,
        position.longitude,
        position.latitude,
        todaySchedule,
        parkingData,

        widget.buildingData,
      );

      stopwatch.stop();

      if (mounted) {
        setState(() {
          _originalRecommendations = List.from(newRecommendations);
          _currentRecommendations = List.from(newRecommendations);
          _calculateDistancesToClass();
          _isRefreshing = false;

          if (_activeSort.isNotEmpty) {
            _updateSorting(_activeSort);
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isRefreshing = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(ErrorHandler.getUserFriendlyError(e)),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
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
          child:
              _currentRecommendations.isEmpty
                  ? ListView(
                    children: const [
                      SizedBox(height: 200),
                      EmptyRecommendations(),
                    ],
                  )
                  : ListView.builder(
                    itemCount: _currentRecommendations.length + 3,
                    itemBuilder: (context, index) {
                      if (index == 0) {
                        return _currentClass != null
                            ? ClassInfoCard(classSchedule: _currentClass!)
                            : const SizedBox.shrink();
                      } else if (index == 1) {
                        return Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Row(
                            children: [
                              const Text(
                                'Recommendations',
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
                        );
                      } else if (index == 2) {
                        return SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: Row(
                            children: [
                              MyButton(
                                text: "Distance from class",
                                onPressed:
                                    () => _updateSorting("Distance from class"),
                                color:
                                    _activeSort == "Distance from class"
                                        ? AppColors.primary
                                        : null,
                                textColor:
                                    _activeSort == "Distance from class"
                                        ? Colors.white
                                        : null,
                              ),
                              const SizedBox(width: 8),
                              MyButton(
                                text: "Availability",
                                onPressed: () => _updateSorting("Availability"),
                                color:
                                    _activeSort == "Availability"
                                        ? AppColors.primary
                                        : null,
                                textColor:
                                    _activeSort == "Availability"
                                        ? Colors.white
                                        : null,
                              ),
                              const SizedBox(width: 8),
                              MyButton(
                                text: "Distance from you",
                                onPressed:
                                    () => _updateSorting("Distance from you"),
                                color:
                                    _activeSort == "Distance from you"
                                        ? AppColors.primary
                                        : null,
                                textColor:
                                    _activeSort == "Distance from you"
                                        ? Colors.white
                                        : null,
                              ),
                            ],
                          ),
                        );
                      } else {
                        final garageIndex = index - 3;
                        if (garageIndex < _currentRecommendations.length) {
                          return RepaintBoundary(
                            child: GarageListItem(
                              garage: _currentRecommendations[garageIndex],
                            ),
                          );
                        }
                        return const SizedBox.shrink();
                      }
                    },
                  ),
        ),
      ),
    );
  }
}
