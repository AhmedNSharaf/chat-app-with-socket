import 'package:flutter/material.dart';

class MessageStatusIcon extends StatelessWidget {
  final String status; // 'sent', 'delivered', 'read'
  final Color color;

  const MessageStatusIcon({
    super.key,
    required this.status,
    this.color = Colors.grey,
  });

  @override
  Widget build(BuildContext context) {
    return _buildStatusIcon();
  }

  Widget _buildStatusIcon() {
    switch (status) {
      case 'sent':
        // Single checkmark
        return Icon(
          Icons.check,
          size: 16,
          color: color,
        );
      case 'delivered':
        // Double checkmark (grey)
        return Icon(
          Icons.done_all,
          size: 16,
          color: color,
        );
      case 'read':
        // Double checkmark (blue)
        return const Icon(
          Icons.done_all,
          size: 16,
          color: Color(0xFF00A884), // WhatsApp green/blue color for read
        );
      default:
        return const SizedBox.shrink();
    }
  }
}
