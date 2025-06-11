import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:async';
import 'package:smart_parking_fiu/util/class_schedule_parser.dart';
import 'package:smart_parking_fiu/util/building_parser.dart';
import '../services/api_service.dart';
import '../models/garage.dart';
import '../util/logic.dart';
import '../util/constants.dart';
import '../util/error_handler.dart';
import '../util/location_distance.dart';
import 'recommendations_page.dart';

class AppColors {
  static const Color primary = Color.fromARGB(255, 9, 31, 63);
  static const Color backgroundwidget = Colors.white;
  static const Color error = Colors.red;
  static const Color text = Color.fromARGB(255, 0, 0, 0);
}

enum LoadingState { initial, loading, loaded, error }

class Homepage extends StatefulWidget {
  const Homepage({super.key});

  @override
  State<Homepage> createState() => _HomepageState();
}

class _HomepageState extends State<Homepage> {
  final TextEditingController idController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  LoadingState _state = LoadingState.initial;
  String? _errorMessage;
  Timer? _debounce;
  bool _isNavigating = false;

  @override
  void initState() {
    super.initState();

    LocationService.initializeUserLocation();
  }

  bool isValidPantherId(String id) {
    return RegExp(r'^\d{7}$').hasMatch(id.trim());
  }

  @override
  void dispose() {
    _debounce?.cancel();
    idController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F7),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: ListView(
          padding: const EdgeInsets.all(30),
          children: [
            const SizedBox(height: 50),
            SizedBox(
              height: 90,
              child: Center(child: Image.asset('images/fiualonetrans.jpg')),
            ),
            const SizedBox(height: 10),
            const Text(
              "Smart Parking",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.primary,
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 90),

            Form(
              key: _formKey,
              child: TextFormField(
                style: const TextStyle(color: AppColors.text),
                controller: idController,
                keyboardType: TextInputType.number,
                maxLength: AppConstants.pantherIdLength,
                decoration: const InputDecoration(
                  filled: true,
                  fillColor: Colors.white,
                  labelText: "Enter Your Student ID",
                  labelStyle: TextStyle(color: Colors.black),
                  hintText: "e.g. 1234567",
                  border: OutlineInputBorder(),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.black),
                  ),
                  counterText: "",
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return "Please enter your Student ID";
                  } else if (!isValidPantherId(value)) {
                    return "Please enter a valid 7-digit Panther ID";
                  }
                  return null;
                },
                onChanged: (value) {
                  if (_debounce?.isActive ?? false) _debounce!.cancel();
                  _debounce = Timer(AppConstants.debounceDuration, () {
                    if (mounted) {
                      setState(() {
                        _errorMessage = null;
                      });
                    }
                  });
                },
              ),
            ),

            const SizedBox(height: 25),

            _buildSubmitButton(),

            if (_errorMessage != null)
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  _errorMessage!,
                  style: const TextStyle(color: AppColors.error),
                  textAlign: TextAlign.center,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubmitButton() {
    if (_state == LoadingState.loading) {
      return Center(
        child: RepaintBoundary(
          child: Lottie.asset(
            'assets/Animation - 1748970341722 (2).json',
            width: 100,
            height: 100,
            repeat: true,
            frameRate: FrameRate(60),
          ),
        ),
      );
    }

    return ElevatedButton(
      onPressed:
          _state == LoadingState.loading ? null : validateAndFetchGarages,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      child: const Text("Submit"),
    );
  }

  Future<void> validateAndFetchGarages() async {
    if (_state == LoadingState.loading) return;

    setState(() {
      _errorMessage = null;
      _state = LoadingState.loading;
    });

    if (!_formKey.currentState!.validate()) {
      setState(() {
        _state = LoadingState.initial;
      });
      return;
    }

    final enteredId = idController.text.trim();

    try {
      // Start all async operations in parallel
      final futures = await Future.wait([
        LocationService.initializeUserLocation().then(
          (_) => LocationService.currentPosition,
        ),
        fetchUsers(enteredId),
        fetchParking(),
        fetchBuilding(),
      ]);

      final userPosition = futures[0] as Position?;
      final classJson = futures[1] as Map<String, dynamic>?;
      final parkingData = futures[2];
      final buildingData = futures[3];

      // Validate location
      if (userPosition == null) {
        _handleError(
          "Location services not available. Please enable location access.",
        );
        return;
      }

      // Validate class data
      if (classJson == null) {
        _handleError("Invalid Panther ID or no classes found");
        return;
      }

      // Initialize building cache if not already done
      if (buildingData != null && !BuildingCache.isInitialized) {
        BuildingCache.initialize(buildingData);
      }

      // Parse today's schedule
      final todaySchedule = ClassScheduleParser.getAllTodayClasses(classJson);
      if (todaySchedule.isEmpty) {
        _handleError("You have no classes today! No need to park ");
        return;
      }

      // Get AI-powered recommendations with already fetched data
      final recommendationsStopwatch = Stopwatch()..start();

      final result = await getAIRecommendationsOptimized(
        enteredId,
        userPosition.longitude,
        userPosition.latitude,
        todaySchedule,
        parkingData,
        buildingData,
      );

      recommendationsStopwatch.stop();

      if (result.isNotEmpty) {
        _navigateToRecommendations(
          result,
          classJson,
          userPosition,
          enteredId,
          buildingData,
        );
      } else {
        _handleError("No parking recommendations available at this time");
      }
    } catch (e) {
      debugPrint('Error in validateAndFetchGarages: $e');
      _handleError(ErrorHandler.getUserFriendlyError(e));
    }
  }

  void _navigateToRecommendations(
    List<Garage> recommendations,
    Map<String, dynamic> classJson,
    Position userPosition,
    String pantherId,
    dynamic buildingData,
  ) {
    if (_isNavigating || !mounted) return;

    _isNavigating = true;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => RecommendationsPage(
              recommendations: recommendations,
              fullScheduleJson: classJson,
              userPosition: userPosition,
              pantherId: pantherId,
              buildingData: buildingData,
            ),
      ),
    ).then((_) {
      _isNavigating = false;
      if (mounted) {
        setState(() {
          _state = LoadingState.initial;
        });
      }
    });
  }

  void _handleError(String message) {
    if (mounted) {
      setState(() {
        _errorMessage = message;
        _state = LoadingState.error;
      });
    }
  }
}
