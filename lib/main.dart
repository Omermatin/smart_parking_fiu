import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'pages/homepage.dart';

import 'models/garage.dart';
import 'package:smart_parking_fiu/util/data.dart';
import 'package:smart_parking_fiu/util/class_schedule_parser.dart';
import 'package:smart_parking_fiu/util/building_parser.dart';
import 'package:smart_parking_fiu/models/building.dart'; // Add this

Future<void> main() async {
  await dotenv.load();
  runApp(const MyApp());
  // Ensure Flutter is initialized before async operations
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await dotenv.load();
    await fetchParking();
    await fetchUsers("4444444");

    final buildings = await getAllMMCBuildings();
    debugPrint('Loaded ${buildings.length} buildings');
  } catch (e) {
    debugPrint('Error during initialization: $e');
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const Homepage(),
    );
  }
}
