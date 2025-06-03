import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
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
      backgroundColor: Color(0xFFF2F2F7),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: ListView(
          padding: const EdgeInsets.all(30),
          children: [
            const SizedBox(height: 50),
            SizedBox(
              height: 90,
              child: Center(child: Image.asset('images/qmage1.png')),
            ),
            const SizedBox(height: 10),
            const Text(
              "Smart Parking",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.black,
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 90),

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
                  labelStyle: TextStyle(color: Colors.black),
                  hintText: "e.g. 1234567",
                  border: OutlineInputBorder(),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.black),
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
                ? Center(
                  child: Lottie.asset(
                    'assets/Animation - 1748970341722 (2).json',
                    width: 100,
                    height: 100,
                    repeat: true,
                  ),
                )
                : ElevatedButton(
                  onPressed: validateAndFetchGarages,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
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
