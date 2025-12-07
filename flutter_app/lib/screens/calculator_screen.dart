import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../services/socket_service.dart';
import '../services/auth_service.dart';
import '../controllers/auth_controller.dart';

class CalculatorScreen extends StatefulWidget {
  const CalculatorScreen({super.key});

  @override
  State<CalculatorScreen> createState() => _CalculatorScreenState();
}

class _CalculatorScreenState extends State<CalculatorScreen> {
  final AuthService _authService = AuthService();
  final AuthController _authController = Get.find();
  late SocketService _socketService;

  String _expression = '';
  String _result = '0';
  bool _isConnected = false;

  @override
  void initState() {
    super.initState();
    _initializeSocket();
  }

  void _initializeSocket() async {
    final token = await _authService.getToken();
    if (token != null) {
      _socketService = SocketService();
      _socketService.connect(token);

      // Listen for calculation results from backend
      _socketService.onCalculationResult((data) {
        setState(() {
          _result = data['result'] as String;
        });
      });

      setState(() {
        _isConnected = true;
      });
    }
  }

  @override
  void dispose() {
    _socketService.offCalculationResult();
    super.dispose();
  }

  void _onButtonPressed(String value) {
    setState(() {
      if (value == 'C') {
        // Clear all
        _expression = '';
        _result = '0';
      } else if (value == '⌫') {
        // Backspace
        if (_expression.isNotEmpty) {
          _expression = _expression.substring(0, _expression.length - 1);
          _sendCalculationRequest();
        }
      } else if (value == '=') {
        // Equal (result already calculated in real-time)
        if (_result != 'Error' && _result != '0') {
          _expression = _result;
          _sendCalculationRequest();
        }
      } else {
        // Add to expression
        _expression += value;
        _sendCalculationRequest();
      }
    });
  }

  void _sendCalculationRequest() {
    if (_expression.isEmpty) {
      setState(() {
        _result = '0';
      });
      return;
    }

    if (_isConnected) {
      // Send calculation request to backend via Socket.IO
      _socketService.calculate(_expression);
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
        child: SafeArea(
          child: Column(
            children: [
              // Custom AppBar
              Padding(
                padding: EdgeInsets.all(8.w),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Get.back(),
                    ),
                    SizedBox(width: 8.w),
                    Text(
                      'Calculator',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(width: 8.w),
                    Container(
                      width: 10.w,
                      height: 10.w,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _isConnected ? Colors.greenAccent : Colors.redAccent,
                        boxShadow: [
                          BoxShadow(
                            color: (_isConnected ? Colors.greenAccent : Colors.redAccent)
                                .withOpacity(0.5),
                            blurRadius: 8,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.logout, color: Colors.white),
                      onPressed: () => _showLogoutDialog(context),
                      tooltip: 'Logout',
                    ),
                  ],
                ),
              ),

              // Display Area
              Expanded(
                flex: 2,
                child: Container(
                  padding: EdgeInsets.all(24.w),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      // Expression
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        reverse: true,
                        child: Text(
                          _expression.isEmpty ? '0' : _expression,
                          style: TextStyle(
                            fontSize: 32.sp,
                            color: Colors.white70,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ),
                      SizedBox(height: 16.h),
                      // Result
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        reverse: true,
                        child: Text(
                          _result,
                          style: TextStyle(
                            fontSize: 52.sp,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Buttons Area
              Expanded(
                flex: 3,
                child: Container(
                  padding: EdgeInsets.all(16.w),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(30.r),
                      topRight: Radius.circular(30.r),
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildButtonRow(['C', '⌫', '%', '÷']),
                      _buildButtonRow(['7', '8', '9', '×']),
                      _buildButtonRow(['4', '5', '6', '-']),
                      _buildButtonRow(['1', '2', '3', '+']),
                      _buildButtonRow(['0', '.', '=', '']),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildButtonRow(List<String> buttons) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: buttons.map((button) {
        if (button.isEmpty) {
          return SizedBox(width: 70.w, height: 70.h);
        }
        return _buildButton(button);
      }).toList(),
    );
  }

  Widget _buildButton(String value) {
    // Determine button color
    Color backgroundColor;
    Color textColor = Colors.white;

    if (value == 'C') {
      backgroundColor = const Color(0xFFE53935); // Red
    } else if (value == '⌫') {
      backgroundColor = const Color(0xFFFF9800); // Orange
    } else if (['+', '-', '×', '÷', '%', '='].contains(value)) {
      backgroundColor = const Color(0xFF00A884); // Green
    } else {
      backgroundColor = const Color(0xFF2C3E50); // Dark gray
    }

    return GestureDetector(
      onTap: () => _onButtonPressed(value),
      child: Container(
        width: 70.w,
        height: 70.h,
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(15.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Center(
          child: Text(
            value,
            style: TextStyle(
              fontSize: value == '⌫' ? 24.sp : 28.sp,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
        ),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    Get.dialog(
      AlertDialog(
        backgroundColor: Colors.transparent,
        contentPadding: EdgeInsets.zero,
        content: Container(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF075E54), Color(0xFF128C7E)],
            ),
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(
              color: Colors.white.withOpacity(0.3),
              width: 1.5,
            ),
          ),
          padding: EdgeInsets.all(24.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.logout,
                size: 48.sp,
                color: Colors.white,
              ),
              SizedBox(height: 16.h),
              Text(
                'Logout',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 8.h),
              Text(
                'Are you sure you want to logout?',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 14.sp,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 24.h),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Get.back(),
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.symmetric(
                        horizontal: 16.w,
                        vertical: 8.h,
                      ),
                    ),
                    child: const Text(
                      'Cancel',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                  SizedBox(width: 8.w),
                  ElevatedButton(
                    onPressed: () async {
                      Get.back(); // Close dialog
                      await _authController.logout();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      padding: EdgeInsets.symmetric(
                        horizontal: 16.w,
                        vertical: 8.h,
                      ),
                    ),
                    child: const Text(
                      'Logout',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
