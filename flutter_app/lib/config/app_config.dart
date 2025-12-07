/// Application configuration
class AppConfig {
  // Server configuration
  // Change this to your backend server IP address
  static const String serverUrl = 'http://192.168.1.3:3000';

  // API endpoints
  static const String apiBaseUrl = '$serverUrl/api/auth';

  // WebSocket configuration
  static const String socketUrl = serverUrl;

  // File upload configuration
  static const int maxFileSize = 10 * 1024 * 1024; // 10MB

  // Message configuration
  static const int typingIndicatorTimeout = 2; // seconds
  static const int messageLoadLimit = 50; // messages per load

  // UI configuration
  static const double messageMaxWidth = 0.75; // 75% of screen width

  // Colors (WhatsApp Dark Theme)
  static const int colorBackground = 0xFF0B141A;
  static const int colorAppBar = 0xFF202C33;
  static const int colorSentMessage = 0xFF005C4B;
  static const int colorReceivedMessage = 0xFF202C33;
  static const int colorAccent = 0xFF00A884;
  static const int colorInputBackground = 0xFF2A3942;
  static const int colorGreyText = 0xFF8696A0;

  // Environment detection
  static bool get isProduction => const bool.fromEnvironment('dart.vm.product');
  static bool get isDevelopment => !isProduction;

  // Debug settings
  static bool get enableDebugLogs => isDevelopment;

  /// Get media URL with server prefix
  static String getMediaUrl(String? path) {
    if (path == null || path.isEmpty) return '';
    if (path.startsWith('http')) return path;
    return '$serverUrl$path';
  }
}
