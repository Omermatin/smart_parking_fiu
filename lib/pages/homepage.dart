import 'package:flutter/material.dart';

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
                height: 120, // adjust this as needed
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
                child: Container(
                  height: 50,
                  color: Color(0xFF00205B),

                  child: DropdownButton<int>(
                    value: selectedId,
                    hint: Text(
                      "Select your ID",
                      style: TextStyle(color: Colors.white),
                    ),

                    style: TextStyle(color: Colors.white),
                    dropdownColor: Color(0xFF00205B),
                    // isExpanded: true,
                    iconEnabledColor: Colors.white,
                    underline: SizedBox(),
                    items:
                        ids
                            .map(
                              (id) => DropdownMenuItem<int>(
                                value: id,
                                child: Text(id.toString()),
                              ),
                            )
                            .toList(),
                    onChanged: (value) {
                      setState(() {
                        selectedId = value;
                      });
                    },
                  ),
                ),
              ),

              const SizedBox(height: 25),
              ElevatedButton(
                onPressed: () {
                  if (selectedId != null) {
                    print("Selected ID: $selectedId");
                    // Call your API or navigate
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          "Please select an ID",
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    );
                  }
                },
                child: Text("Submit"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
