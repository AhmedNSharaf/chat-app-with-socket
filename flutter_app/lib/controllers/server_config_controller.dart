import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/app_config.dart';

class ServerConfigController extends GetxController {
  var isLoading = false.obs;
  var errorMessage = ''.obs;

  Future<void> saveServerUrl(String url) async {
    // Clear previous error
    errorMessage.value = '';

    // Validate URL
    if (url.isEmpty) {
      errorMessage.value = 'Please enter a server URL';
      return;
    }

    // Remove trailing slash if present
    String cleanUrl = url.trim();
    if (cleanUrl.endsWith('/')) {
      cleanUrl = cleanUrl.substring(0, cleanUrl.length - 1);
    }

    // Basic URL validation
    if (!cleanUrl.startsWith('http://') && !cleanUrl.startsWith('https://')) {
      errorMessage.value = 'URL must start with http:// or https://';
      return;
    }

    // Validate URL format
    try {
      Uri.parse(cleanUrl);
    } catch (e) {
      errorMessage.value = 'Invalid URL format';
      return;
    }

    isLoading.value = true;

    try {
      // Test connection to server
      final testResult = await _testServerConnection(cleanUrl);

      if (!testResult) {
        errorMessage.value = 'Cannot connect to server. Please check the URL and ensure the server is running.';
        isLoading.value = false;
        return;
      }

      // Save to shared preferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('server_url', cleanUrl);

      // Update AppConfig
      AppConfig.setServerUrl(cleanUrl);

      // Navigate to login screen
      Get.offAllNamed('/login');
    } catch (e) {
      errorMessage.value = 'Error: ${e.toString()}';
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> _testServerConnection(String url) async {
    try {
      // Simple test: try to connect to the server
      // You can enhance this by making an actual API call
      final uri = Uri.parse(url);

      // Check if URL is valid
      if (uri.host.isEmpty) {
        return false;
      }

      // In a real scenario, you'd make a test HTTP request here
      // For now, we'll just validate the URL structure
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<String?> getSavedServerUrl() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('server_url');
    } catch (e) {
      return null;
    }
  }

  Future<bool> hasServerUrl() async {
    final url = await getSavedServerUrl();
    return url != null && url.isNotEmpty;
  }

  Future<void> clearServerUrl() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('server_url');
      AppConfig.setServerUrl('');
    } catch (e) {
      print('Error clearing server URL: $e');
    }
  }
}
