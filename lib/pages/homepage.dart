import 'package:flutter/material.dart';
import '../util/data.dart';
import '../models/garage.dart';
import '../util/garage_parser.dart';

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
    // Responsive padding based on screen size
    double screenWidth = MediaQuery.of(context).size.width;
    double padding = screenWidth > 600 ? 40.0 : 20.0;

    return Scaffold(
      body: GestureDetector(
        // Unfocus when tapping outside
        onTap: () => FocusScope.of(context).unfocus(),
        child: ListView(
          padding: EdgeInsets.all(padding),
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
                  labelText: "Enter Your Student ID",
                  labelStyle: TextStyle(color: AppColors.primary),
                  hintText: "e.g. 1111111",
                  border: OutlineInputBorder(),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: AppColors.primary),
                  ),
                  semanticCounterText: "Enter your 7-digit Panther ID number",
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return "Please enter your Student ID";
                  } else if (!RegExp(r'^\d+$').hasMatch(value)) {
                    return "ID must be numeric";
                  }
                  return null;
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

            // Error Message Display
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

  // Extracted the validation logic to avoid duplication
  void validateAndFetchGarages() async {
    // Unfocus keyboard
    FocusScope.of(context).unfocus();

    // Validate form first
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final enteredId = idController.text.trim();

    // Check if ID is in valid list using our helper method
    debugPrint("Validating ID: '$enteredId'");

    if (!isValidPantherId(enteredId)) {
      // For testing/debugging, let's try to bypass this validation temporarily
      // REMOVE THIS FOR PRODUCTION - just for testing if the rest of the flow works
      debugPrint("WARNING: ID validation bypassed for testing");

      // Comment this section out if you want to test the rest of the flow
      setState(() {
        errorMessage = "Invalid Panther ID. Please enter a valid ID.";
      });
      return;

      // Uncomment the line below to bypass validation for testing
      // debugPrint("Bypassing ID validation for testing");
    }

    // Clear error and show loading
    setState(() {
      errorMessage = '';
      isLoading = true;
    });

    try {
      // Fetch data
      await fetchUsers(enteredId);
      await fetchGarages();
      debugPrint("User data and garages fetched successfully");
    } catch (e) {
      setState(() {
        errorMessage = "Error fetching data: $e";
      });
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  // Added missing method implementation
  Future<void> fetchUsers(String pantherId) async {
    // Implementation should fetch user data based on the pantherId
    // This is a placeholder - replace with actual implementation
    await Future.delayed(const Duration(milliseconds: 500));
    // Add your user fetching logic here
  }

  // Improved with single setState call for better performance
  Future<void> fetchGarages() async {
    try {
      final parkingData = await fetchParking();

      setState(() {
        if (parkingData == null) {
          errorMessage = "Failed to load garages.";
          garages = [];
        } else {
          garages = GarageParser.parseGarages(parkingData);
          errorMessage = garages.isEmpty ? "No garages found." : '';
        }
      });
    } catch (e) {
      setState(() {
        errorMessage = 'Error fetching garages: $e';
        garages = [];
      });
    }
  }
}

// Extracted widget for better reusability
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
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          'Available: ${garage.studentSpaces}/${garage.studentMaxSpaces}',
        ),
        trailing: CircularProgressIndicator(
          value:
              garage.studentMaxSpaces > 0
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
    final availability =
        garage.studentMaxSpaces > 0
            ? garage.studentSpaces / garage.studentMaxSpaces
            : 0;

    if (availability > 0.5) return Colors.green;
    if (availability > 0.2) return Colors.orange;
    return Colors.red;
  }
}
