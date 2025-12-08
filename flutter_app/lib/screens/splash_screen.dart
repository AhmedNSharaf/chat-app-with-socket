import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../controllers/auth_controller.dart';
import '../controllers/server_config_controller.dart';
import '../config/app_config.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final AuthController _authController = Get.put(AuthController());
  final ServerConfigController _serverConfigController = Get.put(ServerConfigController());

  @override
  void initState() {
    super.initState();
    _navigateToNextScreen();
  }

  void _navigateToNextScreen() async {
    await Future.delayed(const Duration(seconds: 2));

    // Check if server URL is configured
    final hasServerUrl = await _serverConfigController.hasServerUrl();

    if (!hasServerUrl) {
      // No server URL configured, go to server config screen
      Get.offNamed('/server-config');
      return;
    }

    // Load server URL from storage and set it in AppConfig
    final savedServerUrl = await _serverConfigController.getSavedServerUrl();
    if (savedServerUrl != null) {
      AppConfig.setServerUrl(savedServerUrl);
    }

    // Check if user is logged in
    if (_authController.user.value != null) {
      Get.offNamed('/home');
    } else {
      Get.offNamed('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF075E54), Color(0xFF128C7E)],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 120.w,
                height: 120.w,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.chat_bubble_rounded,
                  size: 60.sp,
                  color: const Color(0xFF00A884),
                ),
              ),
              SizedBox(height: 40.h),
              Text(
                'Chat App',
                style: TextStyle(
                  fontSize: 42.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 2,
                ),
              ),
              SizedBox(height: 12.h),
              Text(
                'Real-time messaging',
                style: TextStyle(
                  fontSize: 18.sp,
                  color: Colors.white70,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
