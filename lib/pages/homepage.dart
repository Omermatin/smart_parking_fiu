import 'package:flutter/material.dart';
import '../util/data.dart';
import '../models/garage.dart';
import '../util/garage_parser.dart';

class Homepage extends StatefulWidget {
  const Homepage({super.key});

  @override
  State<Homepage> createState() => _HomepageState();
}

class _HomepageState extends State<Homepage> {
  final List<int> ids = [
    1111111,
    2222222,
    3333333,
    4444444,
    5555555,
    6666666,
    7777777,
    8888888,
    9999999,
  ];

  int? selectedId;
  bool isLoading = false;
  String errorMessage = '';
  List<Garage> garages = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("FIU Smart Parking"), centerTitle: true),
      body: SingleChildScrollView(
        child: Center(
          child: Column(
            children: [
              const SizedBox(height: 20),
              SizedBox(
                height: 120,
                child: Image.asset('images/fiualonetrans.png'),
              ),
              const SizedBox(height: 15),
              const Text(
                "SMART PARKING",
                style: TextStyle(
                  color: Color(0xFF002D72),
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 100),
              SizedBox(
                height: 50,
                child: Container(
                  color: const Color(0xFF00205B),
                  child: DropdownButton<int>(
                    value: selectedId,
                    hint: const Text(
                      "Select your ID",
                      style: TextStyle(color: Colors.white),
                    ),
                    style: const TextStyle(color: Colors.white),
                    dropdownColor: const Color(0xFF00205B),
                    iconEnabledColor: Colors.white,
                    underline: const SizedBox(),
                    items: ids.map((id) {
                      return DropdownMenuItem<int>(
                        value: id,
                        child: Text(id.toString()),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        selectedId = value;
                      });
                    },
                  ),
                ),
              ),
              const SizedBox(height: 25),
              isLoading
                  ? const CircularProgressIndicator()
                  : ElevatedButton(
                      onPressed: () {
                        if (selectedId != null) {
                          fetchGarages();
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                "Please select an ID",
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                          );
                        }
                      },
                      child: const Text("Submit"),
                    ),
              const SizedBox(height: 25),
              if (errorMessage.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    errorMessage,
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
              if (garages.isNotEmpty)
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: garages.length,
                  itemBuilder: (context, index) {
                    final garage = garages[index];
                    return ListTile(
                      title: Text(garage.name),
                      subtitle: Text(
                        'Available: ${garage.studentSpaces}/${garage.studentMaxSpaces}',
                      ),
                    );
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  /// ✅ This function fetches garages and updates the UI
  Future<void> fetchGarages() async {
    setState(() {
      isLoading = true;
      errorMessage = '';
      garages = [];
    });

    try {
      final parkingData = await fetchParking();
      if (parkingData == null) {
        setState(() {
          errorMessage = "Failed to load garages.";
        });
        return;
      }
      garages = GarageParser.parseGarages(parkingData);
      setState(() {
        print(garages);
        errorMessage = garages.isEmpty ? "No garages found." : '';
      });
    } catch (e) {
      setState(() {
        errorMessage = 'Error fetching garages: $e';
      });
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }
}
