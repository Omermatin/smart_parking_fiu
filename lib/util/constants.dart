class AppConstants {
  // UI Constants
  static const int pantherIdLength = 7;

  // Network Constants
  static const Duration requestTimeout = Duration(seconds: 10);
  static const Duration n8nRequestTimeout = Duration(seconds: 20);
  static const Duration locationTimeout = Duration(seconds: 5);

  // Retry Constants
  static const int maxRetryAttempts = 3;
  static const Duration retryDelay = Duration(seconds: 1);

  // Debounce Constants
  static const Duration debounceDuration = Duration(milliseconds: 500);

  // Animation Constants
  static const Duration animationDuration = Duration(milliseconds: 300);

  // Cache Constants
  static const Duration cacheDuration = Duration(hours: 24);
}
