import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/garage.dart';
import '../util/garage_parser.dart';
import '../util/class_schedule_parser.dart';
import '../util/building_parser.dart';
import '../models/building.dart';
import '../services/garage_service.dart';

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
    '1111111', '2222222', '3333333', '4444444', '5555555',
    '6666666', '7777777', '8888888', '9999999',
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
      backgroundColor: const Color.fromRGBO(239,239,239,1),
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
                    onPressed: validateAndLoadGarages,
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
void validateAndLoadGarages() async {
  setState(() {
    errorMessage = '';
    isLoading = true;
  });

  final enteredId = idController.text.trim();
  
  try {
    // Use the GarageService for clean logic
    garages = await GarageService.validateAndFetchGarages(enteredId);

    setState(() {
      errorMessage = garages.isEmpty ? "No garages found." : '';
    });
  } catch (e) {
    setState(() {
      errorMessage = e.toString();
    });
  } finally {
    setState(() {
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
      margin: const EdgeInsets.symmetric(vertical: 5),
      child: ListTile(
        title: Text(
          garage.name,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17,),
        ),
        subtitle: Text(
          'Available: ${garage.studentSpaces}/${garage.studentMaxSpaces}',
        ),
        trailing: CircularProgressIndicator(
          value: garage.studentMaxSpaces > 0 
              ? garage.studentSpaces / garage.studentMaxSpaces 
              : 0,
          backgroundColor: Colors.grey[300],
          valueColor: AlwaysStoppedAnimation<Color>(
            _getColorBasedOnAvailability(garage),
          ),
        ),
      ),
    );
  }
  
  // Helper method to determine color based on availability
  Color _getColorBasedOnAvailability(Garage garage) {
    final availability = garage.studentMaxSpaces > 0 
        ? garage.studentSpaces / garage.studentMaxSpaces 
        : 0;
    
    if (availability > 0.5) return Colors.green;
    if (availability > 0.2) return Colors.orange;
    return Colors.red;
  }
}