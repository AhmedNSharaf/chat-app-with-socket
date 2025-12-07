import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class OnlineIndicator extends StatelessWidget {
  final bool isOnline;
  final String status; // online, offline, away, busy
  final double size;

  const OnlineIndicator({
    super.key,
    required this.isOnline,
    this.status = 'offline',
    this.size = 12,
  });

  @override
  Widget build(BuildContext context) {
    Color color;
    if (!isOnline) {
      color = Colors.grey;
    } else {
      switch (status) {
        case 'online':
          color = const Color(0xFF00A884); // Green
          break;
        case 'away':
          color = Colors.orange;
          break;
        case 'busy':
          color = Colors.red;
          break;
        default:
          color = Colors.grey;
      }
    }

    return Container(
      width: size.w,
      height: size.h,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.white,
          width: 2.w,
        ),
      ),
    );
  }
}
