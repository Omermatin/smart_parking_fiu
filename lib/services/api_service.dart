import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../util/constants.dart';

final http.Client _client = http.Client();

Map<String, String> _headers(String envKey) => {
  'Content-Type': 'application/json',
  'x-api-key': dotenv.env[envKey]!,
};

Future<dynamic> fetchUsers(String studentsIds) async {
  final baseUrl = dotenv.env['API_URL_SCHEDULE'];

  if (baseUrl == null || dotenv.env['API_KEYSCHEDULE'] == null) {
    debugPrint('Missing API configuration for schedule');
    return null;
  }

  final fullUrl = '$baseUrl$studentsIds';
  final url = Uri.parse(fullUrl);

  try {
    final response = await _client
        .get(url, headers: _headers('API_KEYSCHEDULE'))
        .timeout(
          AppConstants.requestTimeout,
          onTimeout: () {
            throw Exception('Schedule request timeout');
          },
        );

    if (response.statusCode != 200) {
      debugPrint('Error fetching users: ${response.body}');
      return null;
    }

    return await compute(jsonDecode, response.body);
  } catch (e) {
    debugPrint('Exception while fetching users: $e');
    rethrow;
  }
}

Future<dynamic> fetchParking() async {
  ;
  final fullUrl = dotenv.env['API_URL_PARKING'];

  debugPrint('Fetching parking data...');

  if (fullUrl == null) {
    throw Exception('API_URL_PARKING not found in environment variables.');
  }

  final url = Uri.parse(fullUrl);

  try {
    final response = await _client
        .get(url, headers: _headers('API_KEY'))
        .timeout(
          AppConstants.requestTimeout,
          onTimeout: () {
            throw Exception('Parking request timeout');
          },
        );

    if (response.statusCode != 200) {
      debugPrint('Error fetching parking: ${response.body}');
      return null;
    }

    return await compute(jsonDecode, response.body);
  } catch (e) {
    debugPrint('Exception while fetching parking: $e');
    rethrow;
  }
}

Future<dynamic> fetchBuilding() async {
  final fullUrl = dotenv.env['API_URL_BUILDINGS'];

  if (fullUrl == null) {
    throw Exception('API_URL_BUILDING not found in environment variables.');
  }

  try {
    final response = await _client
        .get(Uri.parse(fullUrl), headers: _headers('API_KEY'))
        .timeout(
          AppConstants.requestTimeout,
          onTimeout: () {
            throw Exception('Building request timeout');
          },
        );

    if (response.statusCode == 200) {
      return await compute(jsonDecode, response.body);
    } else {
      debugPrint('Error fetching buildings: ${response.body}');
      return null;
    }
  } catch (e) {
    debugPrint('Exception while fetching buildings: $e');
    rethrow;
  }
}

void disposeApiService() {
  _client.close();
}
