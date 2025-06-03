import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:convert';
import 'package:flutter/foundation.dart';

final http.Client _client = http.Client();

Map<String, String> _headers(String envKey) => {
  'Content-Type': 'application/json',
  'x-api-key': dotenv.env[envKey]!,
};

Future<dynamic> fetchUsers(String studentsIds) async {
  final baseUrl = dotenv.env['API_URL_SCHEDULE'];
  debugPrint('Base URL: $baseUrl');

  if (baseUrl == null || dotenv.env['API_KEYSCHEDULE'] == null) {
    return null;
  }

  final fullUrl = '$baseUrl$studentsIds';
  final url = Uri.parse(fullUrl);
  debugPrint('Fetching users from: $fullUrl');
  debugPrint('Using API key: ${dotenv.env['API_KEYSCHEDULE']}');

  try {
    final response = await _client.get(
      url,
      headers: _headers('API_KEYSCHEDULE'),
    );
    debugPrint('Response status code: ${response.statusCode}');
    if (response.statusCode != 200) {
      debugPrint('Error fetching users: ${response.body}');
      return null;
    }
    return await compute(jsonDecode, response.body);
  } catch (e) {
    debugPrint('Exception while fetching users: $e');
    return null;
  }
}

Future<dynamic> fetchParking() async {
  final fullUrl = dotenv.env['API_URL_PARKING'];

  if (fullUrl == null) {
    throw Exception('API_URL_PARKING not found in environment variables.');
  }
  final url = Uri.parse(fullUrl);

  try {
    final response = await _client.get(url, headers: _headers('API_KEY'));
    return await compute(jsonDecode, response.body);
  } catch (e) {
    return null;
  }
}

Future<dynamic> fetchBuilding() async {
  final fullUrl = dotenv.env['API_URL_BUILDINGS'];

  if (fullUrl == null) {
    throw Exception('API_URL_BUILDING not found in environment variables.');
  }

  final response = await _client.get(
    Uri.parse(fullUrl),
    headers: _headers('API_KEY'),
  );

  if (response.statusCode == 200) {
    return await compute(jsonDecode, response.body);
  } else {
    return null;
  }
}
