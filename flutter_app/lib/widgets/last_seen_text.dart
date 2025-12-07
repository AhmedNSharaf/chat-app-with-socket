import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class LastSeenText extends StatelessWidget {
  final bool isOnline;
  final String status;
  final String? lastSeen;
  final String? customStatus;
  final double fontSize;
  final Color? onlineColor;
  final Color? offlineColor;

  const LastSeenText({
    super.key,
    required this.isOnline,
    this.status = 'offline',
    this.lastSeen,
    this.customStatus,
    this.fontSize = 12,
    this.onlineColor,
    this.offlineColor,
  });

  @override
  Widget build(BuildContext context) {
    String text;
    Color textColor;

    if (customStatus != null && customStatus!.isNotEmpty) {
      text = customStatus!;
      textColor = onlineColor ?? const Color(0xFF00A884);
    } else if (isOnline) {
      switch (status) {
        case 'online':
          text = 'online';
          textColor = onlineColor ?? const Color(0xFF00A884);
          break;
        case 'away':
          text = 'away';
          textColor = Colors.orange;
          break;
        case 'busy':
          text = 'busy';
          textColor = Colors.red;
          break;
        default:
          text = 'online';
          textColor = onlineColor ?? const Color(0xFF00A884);
      }
    } else if (lastSeen != null) {
      text = 'last seen ${_formatLastSeen(lastSeen!)}';
      textColor = offlineColor ?? Colors.grey[400]!;
    } else {
      text = 'offline';
      textColor = offlineColor ?? Colors.grey[400]!;
    }

    return Text(
      text,
      style: TextStyle(
        color: textColor,
        fontSize: fontSize.sp,
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }

  String _formatLastSeen(String lastSeen) {
    try {
      final dateTime = DateTime.parse(lastSeen);
      final now = DateTime.now();
      final difference = now.difference(dateTime);

      if (difference.inSeconds < 60) {
        return 'just now';
      } else if (difference.inMinutes < 60) {
        return '${difference.inMinutes}m ago';
      } else if (difference.inHours < 24) {
        return '${difference.inHours}h ago';
      } else if (difference.inDays == 1) {
        return 'yesterday';
      } else if (difference.inDays < 7) {
        return '${difference.inDays}d ago';
      } else {
        return 'on ${dateTime.day}/${dateTime.month}/${dateTime.year}';
      }
    } catch (e) {
      return 'recently';
    }
  }
}
