import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/garage.dart';
import '../util/class_schedule_parser.dart';
import '../util/logic.dart';
import '../util/building_parser.dart';
import 'recommendations_page.dart';

class AppColors {
  static const Color primary = Color(0xFF002D72);
  static const Color background = Colors.white;
  static const Color error = Colors.red;
  static const Color text = Color.fromARGB(255, 0, 0, 0);
}

class Homepage extends StatefulWidget {
  const Homepage({super.key});

  @override
  State<Homepage> createState() => _HomepageState();
}

class _HomepageState extends State<Homepage> {
  final TextEditingController idController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final List<String> validPantherIds = [
    '1111111',
    '2222222',
    '3333333',
    '4444444',
    '5555555',
    '6666666',
    '7777777',
    '8888888',
    '9999999',
  ];
  @override
  void initState() {
    super.initState();
    // Initialize building cache and location service
    Future.wait([
      BuildingCache.initialize(),
      LocationService.initializeUserLocation(),
    ]).catchError((error) {
      debugPrint('Error initializing services: $error');
    });
  }

  // Helper method to check if an ID is valid
  bool isValidPantherId(String id) {
    return validPantherIds.contains(id.trim());
  }

  bool isLoading = false;
  String errorMessage = '';
  List<Garage> garages = [];

  @override
  void dispose() {
    idController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromRGBO(239, 239, 239, 1),
      body: GestureDetector(
        // Unfocus when tapping outside
        onTap: () => FocusScope.of(context).unfocus(),
        child: ListView(
          padding: const EdgeInsets.all(30),
          children: [
            const SizedBox(height: 50),
            SizedBox(
              height: 80,
              child: Center(child: Image.asset('images/fiualonetrans.png')),
            ),
            const SizedBox(height: 15),
            const Text(
              "SMART PARKING",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.primary,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 100),

            // Form with validation
            Form(
              key: _formKey,
              child: TextFormField(
                style: TextStyle(color: AppColors.text),
                controller: idController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  filled: true,
                  fillColor: Colors.white,
                  labelText: "Enter Your Student ID",
                  labelStyle: TextStyle(color: AppColors.primary),
                  hintText: "e.g. 1111111",
                  border: OutlineInputBorder(),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: AppColors.primary),
                  ),
                ),
                // validation
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return "Please enter your Student ID";
                  } else if (!RegExp(r'^\d+$').hasMatch(value)) {
                    return "ID must be numeric";
                  } else if (!isValidPantherId(value)) {
                    return "Invalid Panther ID. Please enter a valid ID.";
                  }
                  return null;
                },
                // Clear the previous error on change
                onChanged: (_) {
                  setState(() {
                    errorMessage = '';
                  });
                },
              ),
            ),

            const SizedBox(height: 25),

            // Submit Button with loading state
            isLoading
                ? const Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
                )
                : ElevatedButton(
                  onPressed: validateAndFetchGarages,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.background,
                  ),
                  child: const Text("Submit"),
                ),

            // Error Message Display - for network/API errors
            if (errorMessage.isNotEmpty)
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  errorMessage,
                  style: const TextStyle(color: AppColors.error),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // Refactored validation and data fetching method with compute
  void validateAndFetchGarages() async {
    setState(() {
      errorMessage = '';
      isLoading = true; // Start loading immediately
    });

    // Unfocus keyboard

    // Validate form first - this handles both format and valid ID checks
    if (!_formKey.currentState!.validate()) {
      setState(() {
        isLoading = false; // Stop loading if validation fails
      });
      return;
    }

    final enteredId = idController.text.trim();

    try {
      // Get position outside of setState
      final userPosition = LocationService.currentPosition;

      if (userPosition == null) {
        setState(() {
          errorMessage = "Location services not available";
          isLoading = false;
        });
        return;
      }

      // First fetch the class schedule
      final classJson = await fetchUsers(enteredId);
      if (classJson == null) {
        setState(() {
          errorMessage = "Failed to fetch class schedule";
          isLoading = false;
        });
        return;
      }

      final classSchedule = ClassScheduleParser.getCurrentOrUpcomingClass(
        classJson,
      );
      if (classSchedule == null) {
        setState(() {
          errorMessage = "No current or upcoming classes found";
          isLoading = false;
        });
        return;
      }

      // Call recommendations to get parking options
      final result = await recommendations(
        enteredId,
        userPosition.longitude,
        userPosition.latitude,
        classSchedule,
      );

      if (result is List) {
        final garageResults = result.cast<Garage>();

        // Only set isLoading to false AFTER navigation
        // This prevents the button from flashing

        // Navigate to the recommendations page
        Navigator.push(
          context,
          MaterialPageRoute(
            builder:
                (context) => RecommendationsPage(
                  recommendations: garageResults,
                  classSchedule: classSchedule,
                ),
          ),
        ).then((_) {
          // Set loading to false after returning from recommendations page
          if (mounted) {
            setState(() {
              isLoading = false;
            });
          }
        });

        debugPrint(
          "Recommendations fetched successfully: ${garageResults.length} garages",
        );
      } else {
        setState(() {
          errorMessage = "Failed to get recommendations";
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = "Error: $e";
        isLoading = false;
      });
    }
  }
}
