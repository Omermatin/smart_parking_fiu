import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/garage.dart';
import '../util/garage_parser.dart';
import '../util/class_schedule_parser.dart';
import '../util/building_parser.dart';
import '../models/building.dart';
import '../util/logic.dart';

// Color constants to avoid hardcoding
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

  // Added a method to check ID validity instead of relying on direct list comparison
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

  // Helper method to check if an ID is valid
  bool isValidPantherId(String id) {
    return validPantherIds.contains(id.trim());
  }

  bool isLoading = false;
  String errorMessage = '';
  List<Garage> garages = [];

  @override
  void dispose() {
    // Dispose controller to prevent memory leaks
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
          padding: EdgeInsets.all(30),
          children: [
            const SizedBox(height: 20),
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
                  semanticCounterText: "Enter your 7-digit Panther ID number",
                ),
                // Unified validation - handles both format and valid ID checks
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
                ? const Center(child: CircularProgressIndicator())
                : ElevatedButton(
                  onPressed: validateAndFetchGarages,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.background,
                  ),
                  child: const Text("Submit"),
                ),

            const SizedBox(height: 25),

            // Error Message Display - for network/API errors
            if (errorMessage.isNotEmpty)
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  errorMessage,
                  style: const TextStyle(color: AppColors.error),
                ),
              ),

            // Garage List Display
            if (garages.isNotEmpty)
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: garages.length,
                itemBuilder: (context, index) {
                  return GarageListItem(garage: garages[index]);
                },
              ),
          ],
        ),
      ),
    );
  }

  // Refactored validation and data fetching method
  void validateAndFetchGarages() async {
    setState(() {
      errorMessage = '';
    });
    
    // Unfocus keyboard
    FocusScope.of(context).unfocus();
    
    // Validate form first - this handles both format and valid ID checks
    if (!_formKey.currentState!.validate()) {
      return;
    }
    
    final enteredId = idController.text.trim();
    
    // Set loading state
    setState(() {
      isLoading = true;
    });

    try {
      // Use the recommendations function that already handles all the logic
      final userPosition = LocationService.currentPosition;
      debugPrint("position: ${userPosition}");
      
      if (userPosition == null) {
        setState(() {
          errorMessage = "Location services not available";
          isLoading = false;
        });
        return;
      }
      
      final result = await recommendations(
        enteredId,
        userPosition.longitude,
        userPosition.latitude
      );
      
      if (result is List) {
        setState(() {
          garages = result.cast<Garage>();
          errorMessage = garages.isEmpty ? "No suitable garages found." : '';
          isLoading = false;
        });
        debugPrint("Recommendations fetched successfully: ${garages.length} garages");
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

// Garage List Item Widget
class GarageListItem extends StatelessWidget {
  final Garage garage;
  
  const GarageListItem({required this.garage, Key? key}) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    garage.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold, 
                      fontSize: 18,
                      color: AppColors.primary,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _getColorBasedOnAvailability(garage).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${garage.studentSpaces}/${garage.studentMaxSpaces}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: _getColorBasedOnAvailability(garage),
                      fontSize: 16,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            if (garage.distanceToClass != null)
              Row(
                children: [
                  Icon(
                    Icons.school, 
                    size: 18, 
                    color: Colors.grey[600],
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'To class: ${garage.distanceToClass!.toStringAsFixed(2)} mi',
                    style: TextStyle(
                      fontSize: 15,
                      color: Colors.grey[700],
                    ),
                  ),
                ],
              ),
            if (garage.distanceFromOrigin != null)
              Padding(
                padding: const EdgeInsets.only(top: 4.0),
                child: Row(
                  children: [
                    Icon(
                      Icons.my_location, 
                      size: 18, 
                      color: Colors.grey[600],
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'From you: ${garage.distanceFromOrigin!.toStringAsFixed(2)} mi',
                      style: TextStyle(
                        fontSize: 15,
                        color: Colors.grey[700],
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: garage.studentMaxSpaces > 0 
                          ? garage.studentSpaces / garage.studentMaxSpaces 
                          : 0,
                      backgroundColor: Colors.grey[300],
                      valueColor: AlwaysStoppedAnimation<Color>(
                        _getColorBasedOnAvailability(garage),
                      ),
                      minHeight: 8,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  _getAvailabilityText(garage),
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    color: _getColorBasedOnAvailability(garage),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  // Helper method to determine color based on availability
  Color _getColorBasedOnAvailability(Garage garage) {
    final availability =
        garage.studentMaxSpaces > 0
            ? garage.studentSpaces / garage.studentMaxSpaces
            : 0;
    
    if (availability > 0.5) return Colors.green;
    if (availability > 0.2) return Colors.orange;
    return Colors.red;
  }
  
  // Helper method to get availability text
  String _getAvailabilityText(Garage garage) {
    final availability = garage.studentMaxSpaces > 0
        ? garage.studentSpaces / garage.studentMaxSpaces
        : 0;
    
    if (availability > 0.5) return 'High';
    if (availability > 0.2) return 'Medium';
    return 'Low';
  }
}
