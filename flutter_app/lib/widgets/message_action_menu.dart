import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../models/message_model.dart';

class MessageActionMenu extends StatelessWidget {
  final Message message;
  final bool isSentByMe;
  final VoidCallback onReply;
  final VoidCallback? onEdit;
  final VoidCallback onDelete;
  final VoidCallback onDeleteForEveryone;
  final Function(String) onReaction;
  final VoidCallback onForward;

  const MessageActionMenu({
    super.key,
    required this.message,
    required this.isSentByMe,
    required this.onReply,
    this.onEdit,
    required this.onDelete,
    required this.onDeleteForEveryone,
    required this.onReaction,
    required this.onForward,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF202C33),
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Quick reactions
          _buildQuickReactions(),

          Divider(height: 1, color: Colors.grey[700]),

          // Action buttons
          _buildActionButton(
            icon: Icons.reply,
            label: 'Reply',
            onTap: onReply,
          ),

          if (isSentByMe && message.mediaType == null && !message.isEdited)
            _buildActionButton(
              icon: Icons.edit,
              label: 'Edit',
              onTap: onEdit ?? () {},
            ),

          _buildActionButton(
            icon: Icons.forward,
            label: 'Forward',
            onTap: onForward,
          ),

          _buildActionButton(
            icon: Icons.delete_outline,
            label: 'Delete for me',
            onTap: onDelete,
          ),

          if (isSentByMe)
            _buildActionButton(
              icon: Icons.delete,
              label: 'Delete for everyone',
              onTap: onDeleteForEveryone,
              isDestructive: true,
            ),
        ],
      ),
    );
  }

  Widget _buildQuickReactions() {
    final reactions = ['👍', '❤️', '😂', '😮', '😢', '🙏'];

    return Container(
      padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 16.w),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: reactions.map((emoji) {
          return GestureDetector(
            onTap: () => onReaction(emoji),
            child: Container(
              padding: EdgeInsets.all(8.w),
              decoration: BoxDecoration(
                color: Colors.grey[800],
                shape: BoxShape.circle,
              ),
              child: Text(
                emoji,
                style: TextStyle(fontSize: 24.sp),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 16.w),
        child: Row(
          children: [
            Icon(
              icon,
              color: isDestructive ? Colors.red : Colors.white,
              size: 20.sp,
            ),
            SizedBox(width: 16.w),
            Text(
              label,
              style: TextStyle(
                color: isDestructive ? Colors.red : Colors.white,
                fontSize: 14.sp,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Helper function to show the message action menu
void showMessageActionMenu({
  required BuildContext context,
  required Message message,
  required bool isSentByMe,
  required VoidCallback onReply,
  VoidCallback? onEdit,
  required VoidCallback onDelete,
  required VoidCallback onDeleteForEveryone,
  required Function(String) onReaction,
  required VoidCallback onForward,
}) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (context) => MessageActionMenu(
      message: message,
      isSentByMe: isSentByMe,
      onReply: () {
        Navigator.pop(context);
        onReply();
      },
      onEdit: onEdit != null
          ? () {
              Navigator.pop(context);
              onEdit();
            }
          : null,
      onDelete: () {
        Navigator.pop(context);
        onDelete();
      },
      onDeleteForEveryone: () {
        Navigator.pop(context);
        onDeleteForEveryone();
      },
      onReaction: (emoji) {
        Navigator.pop(context);
        onReaction(emoji);
      },
      onForward: () {
        Navigator.pop(context);
        onForward();
      },
    ),
  );
}
