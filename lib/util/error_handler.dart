import 'dart:io';
import 'dart:async';

class ErrorHandler {
  static String getUserFriendlyError(dynamic error) {
    if (error is SocketException) {
      return "No internet connection. Please check your network settings.";
    } else if (error is TimeoutException) {
      return "Request timed out. Please try again.";
    } else if (error is FormatException) {
      return "Invalid data format received. Please try again.";
    } else if (error.toString().contains('Location')) {
      return "Please enable location services to use this app.";
    } else if (error.toString().contains('Invalid Panther ID')) {
      return "The Panther ID you entered is not valid. Please check and try again.";
    } else if (error.toString().contains('No classes found')) {
      return "No classes found for this Panther ID. Please verify your student ID.";
    } else if (error.toString().contains('API_URL')) {
      return "Configuration error. Please contact support.";
    } else if (error.toString().contains('timeout')) {
      return "The request took too long. Please try again.";
    } else if (error.toString().contains('n8n')) {
      return "Unable to get parking recommendations. Please try again later.";
    } else if (error.toString().contains('Building')) {
      return "Unable to load building information. Please try again.";
    } else if (error.toString().contains('Parking')) {
      return "Unable to load parking data. Please try again.";
    }

    return "An unexpected error occurred. Please try again later.";
  }

  static void logError(
    String context,
    dynamic error, [
    StackTrace? stackTrace,
  ]) {
    final timestamp = DateTime.now().toIso8601String();
    print('[$timestamp] Error in $context: $error');
    if (stackTrace != null) {}
  }
}
