import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:convert';

Future<dynamic> fetchUsers(String studentsIds) async {
  debugPrint('Getting JSON Data');

  final baseUrl = dotenv.env['API_URL_SCHEDULE'];

  if (baseUrl == null || dotenv.env['API_KEY'] == null) {
    debugPrint('Environment variables not found');
    return null;
  }

  final fullUrl = '$baseUrl$studentsIds';
  final url = Uri.parse(fullUrl);

  final headers = {
    'Content-Type': 'application/json',
    'x-api-key': dotenv.env['API_KEY']!,
  };

  try {
    final response = await http.get(url, headers: headers);
   // debugPrint('Response status: ${response.statusCode}');
    //debugPrint('Response body: ${response.body}');
    return jsonDecode(response.body);
  } catch (e) {
    debugPrint('Fetch failed: $e');
    return null;
  }
}

Future<dynamic> fetchParking() async {
  final fullUrl = dotenv.env['API_URL_PARKING'];

  if (fullUrl == null) {
    throw Exception('API_URL_PARKING not found in environment variables.');
  }
  final url = Uri.parse(fullUrl!);

  final headers = {
    'Content-Type': 'application/json',
    'x-api-key': dotenv.env['API_KEY']!,
  };

  try {
    final response = await http.get(url, headers: headers);
  //  debugPrint('Response status: ${response.statusCode}');
  //  debugPrint('Response body: ${response.body}');
    return jsonDecode(response.body);
  } catch (e) {
    debugPrint('Fetch failed: $e');
    return null;
  }
}
