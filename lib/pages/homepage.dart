import 'package:flutter/material.dart';
import 'package:smart_parking_fiu/util/class_schedule_parser.dart';
import '../services/api_service.dart';
import '../models/garage.dart';
import '../util/logic.dart';
import 'recommendations_page.dart';

class AppColors {
  static const Color primary = Color.fromARGB(255, 9, 31, 63);
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
    // Only initialize location service
    LocationService.initializeUserLocation();
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
      backgroundColor: const Color.fromARGB(255, 242, 242, 247),
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
                  fillColor: Color.fromARGB(255, 227, 227, 232),
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

    debugPrint('🚀 Submit button pressed');

    if (!_formKey.currentState!.validate()) {
      debugPrint('❌ Form validation failed');
      setState(() {
        isLoading = false;
      });
      return;
    }

    final enteredId = idController.text.trim();
    debugPrint('✅ Form validated. Student ID: $enteredId');

    try {
      final userPosition = LocationService.currentPosition;

      if (userPosition == null) {
        debugPrint('❌ Location not available');
        setState(() {
          errorMessage = "Location services not available";
          isLoading = false;
        });
        return;
      }
      debugPrint(
        '✅ Location available: ${userPosition.latitude}, ${userPosition.longitude}',
      );

      // Start parking & building fetches immediately
      final parkingFuture = fetchParking();
      final buildingFuture = fetchBuilding();

      // Fetch the class schedule to validate the Panther ID
      debugPrint('📚 Fetching class schedule...');
      final classJson = await fetchUsers(enteredId);
      if (classJson == null) {
        debugPrint('❌ No class data returned from API');
        setState(() {
          errorMessage = "Invalid Panther ID or no classes found";
          isLoading = false;
        });
        return;
      }
      debugPrint('✅ Class schedule fetched successfully');
      final todaySchedule = ClassScheduleParser.getAllTodayClasses(classJson);
      if (todaySchedule.isEmpty) {
        debugPrint('❌ No today schedule found');
        setState(() {
          errorMessage = "You have no classes today! No need to park :)";
          isLoading = false;
        });
        return;
      }
      // Get AI-powered recommendations
      debugPrint('🤖 Calling getAIRecommendations...');
      final result = await getAIRecommendations(
        enteredId,
        userPosition.longitude,
        userPosition.latitude,
        todaySchedule,
        parkingFuture,
        buildingFuture,
      );
      debugPrint('🤖 getAIRecommendations returned ${result.length} garages');

      if (result.isNotEmpty) {
        if (!mounted) {
          return;
        }
        debugPrint('✅ Navigating to recommendations page');
        Navigator.push(
          context,
          MaterialPageRoute(
            builder:
                (context) => RecommendationsPage(
                  recommendations: result,
                  fullScheduleJson: classJson,
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
        debugPrint('❌ No recommendations returned');
        setState(() {
          errorMessage = "Failed to get recommendations";
          isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('💥 Error in validateAndFetchGarages: $e');
      setState(() {
        errorMessage = "Error: $e";
        isLoading = false;
      });
    }
  }
}
