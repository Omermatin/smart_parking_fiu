import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/garage.dart';
import '../util/class_schedule_parser.dart';
import '../util/logic.dart';
import '../util/building_parser.dart';
import '../util/garage_parser.dart';
import 'recommendations_page.dart';

class AppColors {
  static const Color primary = Color.fromARGB(255, 2, 33, 80);
  static const Color backgroundwidget = Colors.white;
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

  @override
  void initState() {
    super.initState();
    Future.wait([
      BuildingCache.initialize(),
      LocationService.initializeUserLocation(),
    ]);
  }

  bool isValidPantherId(String id) {
    // Panther ID must be exactly 7 digits
    return RegExp(r'^\d{7}$').hasMatch(id.trim());
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
      backgroundColor: const Color.fromARGB(255, 249, 249, 250),
      body: GestureDetector(
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

            Form(
              key: _formKey,
              child: TextFormField(
                style: TextStyle(color: AppColors.text),
                controller: idController,
                keyboardType: TextInputType.number,
                maxLength: 7, // Limit to 7 digits
                decoration: const InputDecoration(
                  filled: true,
                  fillColor: Colors.white,
                  labelText: "Enter Your Student ID",
                  labelStyle: TextStyle(color: AppColors.primary),
                  hintText: "e.g. 1234567",
                  border: OutlineInputBorder(),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: AppColors.primary),
                  ),
                  counterText: "", // Hide the character counter
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return "Please enter your Student ID";
                  } else if (!isValidPantherId(value)) {
                    return "Please enter a valid 7-digit Panther ID";
                  }
                  return null;
                },
                onChanged: (_) {
                  setState(() {
                    errorMessage = '';
                  });
                },
              ),
            ),

            const SizedBox(height: 25),

            isLoading
                ? const Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
                )
                : ElevatedButton(
                  onPressed: validateAndFetchGarages,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.backgroundwidget,
                  ),
                  child: const Text("Submit"),
                ),

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

  void validateAndFetchGarages() async {
    setState(() {
      errorMessage = '';
      isLoading = true;
    });

    if (!_formKey.currentState!.validate()) {
      setState(() {
        isLoading = false;
      });
      return;
    }

    final enteredId = idController.text.trim();

    try {
      final userPosition = LocationService.currentPosition;

      if (userPosition == null) {
        setState(() {
          errorMessage = "Location services not available";
          isLoading = false;
        });
        return;
      }

      // First try to fetch the class schedule to validate the Panther ID
      final classJson = await fetchUsers(enteredId);
      if (classJson == null) {
        setState(() {
          errorMessage = "Invalid Panther ID or no classes found";
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
      final result = await recommendations(
        enteredId,
        userPosition.longitude,
        userPosition.latitude,
        classSchedule,
      );

      if (result is List) {
        final garageResults = result.cast<Garage>();

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
          if (mounted) {
            setState(() {
              isLoading = false;
            });
          }
        });
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
