import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

Future<void> fetchUsers(String studentsIds) async {
  debugPrint('Getting JSON Data');

  final baseUrl = dotenv.env['API_URL_SCHEDULE'];
  final apiKey = dotenv.env['API_KEY'];
  final fullUrl = '$baseUrl$studentsIds';
  final url = Uri.parse(fullUrl);

  final headers = {
    'Content-Type': 'application/json',
    'x-api-key': dotenv.env['API_KEY']!,
  };

  try {
    final response = await http.get(url, headers: headers);
    debugPrint('Response status: ${response.statusCode}');
    debugPrint('Response body: ${response.body}');
  } catch (e) {
    debugPrint('Fetch failed: $e');
  }
}

// void fetchParking(String apiUrlGarages) async {
//   print("Getting JSON Data");

//   final url = Uri.parse(apiUrlGarages);

//   final response = await http.get(url);

//   print('Response status: ${response.statusCode}');
//   print('Response body: ${response.body}');
// }
