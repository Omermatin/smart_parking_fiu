
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'pages/homepage.dart';
import 'package:smart_parking_fiu/util/logic.dart';

Future<void> main() async {
  // Initialize Flutter binding
  WidgetsFlutterBinding.ensureInitialized();
  // Load environment variables
  await dotenv.load();
  // Initialize location service
  await LocationService.initializeUserLocation();


  // Run the app
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FIU Smart Parking',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color.fromARGB(255, 50, 30, 165),
        ),
      ),
      home: const Homepage(),
    );
  }
}
