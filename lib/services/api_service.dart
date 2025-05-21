import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:convert';

Map<String, String> _getApiHeadersForParkingAndBuilding() {
  return {
    'Content-Type': 'application/json',
    'x-api-key': dotenv.env['API_KEY']!,
  };
}

Map<String, String> _getApiHeadersForSchedule() {
  return {
    'Content-Type': 'application/json',
    'x-api-key': dotenv.env['API_KEYSCHEDULE']!,
  };
}

Future<dynamic> fetchUsers(String studentsIds) async {
  final baseUrl = dotenv.env['API_URL_SCHEDULE'];

  if (baseUrl == null || dotenv.env['API_KEY'] == null) {
    return null;
  }

  final fullUrl = '$baseUrl$studentsIds';
  final url = Uri.parse(fullUrl);

  try {
    final response = await http.get(url, headers: _getApiHeadersForSchedule());
    return jsonDecode(response.body);
  } catch (e) {
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
    final response = await http.get(
      url,
      headers: _getApiHeadersForParkingAndBuilding(),
    );
    return jsonDecode(response.body);
  } catch (e) {
    return null;
  }
}

Future<dynamic> fetchBuilding() async {
  final fullUrl = dotenv.env['API_URL_BUILDINGS'];

  final url = Uri.parse(fullUrl!);

  try {
    final response = await http.get(
      url,
      headers: _getApiHeadersForParkingAndBuilding(),
    );
    return jsonDecode(response.body);
  } catch (e) {
    return null;
  }
}
