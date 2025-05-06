import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'pages/homepage.dart';
import 'models/garage.dart';
import 'package:smart_parking_fiu/functions/data.dart';

Future<void> main() async {
  debugPrint('Getting JSON Data');
  await dotenv.load();
  debugPrint('Laoding done');
  runApp(const MyApp());

  fetchUsers("4444444");
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const Homepage(),
    );
  }
}
