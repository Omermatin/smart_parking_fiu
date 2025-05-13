import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:smart_parking_fiu/models/class_schedule.dart';
import 'package:smart_parking_fiu/util/garage_parser.dart';
import 'pages/homepage.dart';
import 'models/garage.dart';
import 'package:smart_parking_fiu/services/api_service.dart';
import 'package:smart_parking_fiu/util/class_schedule_parser.dart';
import 'package:smart_parking_fiu/util/building_parser.dart';
import 'package:smart_parking_fiu/util/logic.dart';
import 'package:smart_parking_fiu/models/building.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load();

  await recommendations("4444444", 25.7553898, -80.3762832779774);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
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
