import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/secure_storage_service.dart';

class AuthController extends GetxController {
  final AuthService _authService = AuthService();
  final SecureStorageService _secureStorage = SecureStorageService();

  var isLoading = false.obs;
  var user = Rxn<User>();
  var rememberMe = false.obs;

  @override
  void onInit() {
    super.onInit();
    _loadRememberMePreference();
    checkLoginStatus();
  }

  Future<void> _loadRememberMePreference() async {
    rememberMe.value = await _secureStorage.getRememberMe();
  }

  Future<void> checkLoginStatus() async {
    final isLoggedIn = await _authService.isLoggedIn();
    if (isLoggedIn) {
      user.value = await _authService.getUser();
    }
  }

  Future<void> register(String email, String username, String password) async {
    isLoading.value = true;
    try {
      final result = await _authService.register(email, username, password);
      if (result['success']) {
        Get.snackbar(
          'Success',
          result['message'],
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
        Get.offNamed('/login');
      } else {
        Get.snackbar(
          'Error',
          result['message'],
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Registration failed',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> login(
    String email,
    String password, {
    bool remember = false,
  }) async {
    isLoading.value = true;
    try {
      final result = await _authService.login(email, password);
      if (result['success']) {
        user.value = result['user'];

        // Save remember me preference
        await _secureStorage.setRememberMe(remember);

        // Auto-logout after token expiry if not remembering
        if (!remember) {
          _scheduleAutoLogout();
        }

        Get.offNamed('/home');
      } else {
        Get.snackbar(
          'Error',
          result['message'],
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        debugPrint(result['message']);
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Login failed',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }

  void _scheduleAutoLogout() {
    // Schedule logout when token expires (24 hours from now)
    Future.delayed(const Duration(hours: 24), () async {
      if (!rememberMe.value) {
        await logout();
        Get.snackbar(
          'Session Expired',
          'Please login again',
          backgroundColor: Colors.orange,
          colorText: Colors.white,
        );
      }
    });
  }

  Future<Map<String, dynamic>> uploadProfilePhoto(String filePath) async {
    try {
      final result = await _authService.uploadProfilePhoto(filePath);
      if (result['success']) {
        final profilePhotoUrl = result['profilePhoto'];
        await updateProfilePhoto(profilePhotoUrl);
      }
      return result;
    } catch (e) {
      return {'success': false, 'message': 'Upload failed'};
    }
  }

  Future<void> updateProfilePhoto(String profilePhotoUrl) async {
    if (user.value != null) {
      user.value = User(
        id: user.value!.id,
        email: user.value!.email,
        username: user.value!.username,
        profilePhoto: profilePhotoUrl,
      );
      await _authService.saveUser(user.value!);
    }
  }

  Future<void> logout() async {
    await _authService.logout();
    await _secureStorage.clearAuthData();
    user.value = null;
    Get.offAllNamed('/login');
  }

  // Password reset functionality
  Future<Map<String, dynamic>> requestPasswordReset(String email) async {
    isLoading.value = true;
    try {
      final result = await _authService.requestPasswordReset(email);
      return result;
    } catch (e) {
      return {'success': false, 'message': 'Request failed'};
    } finally {
      isLoading.value = false;
    }
  }

  Future<Map<String, dynamic>> resetPassword(
    String token,
    String newPassword,
  ) async {
    isLoading.value = true;
    try {
      final result = await _authService.resetPassword(token, newPassword);
      return result;
    } catch (e) {
      return {'success': false, 'message': 'Reset failed'};
    } finally {
      isLoading.value = false;
    }
  }
}
