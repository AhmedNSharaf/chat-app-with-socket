import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../models/message_model.dart';
import 'message_status_icon.dart';

class MessageBubble extends StatelessWidget {
  final Message message;
  final bool isSentByMe;
  final int? currentUserId;
  final VoidCallback? onLongPress;
  final Function(String)? onReactionTap;

  const MessageBubble({
    super.key,
    required this.message,
    required this.isSentByMe,
    this.currentUserId,
    this.onLongPress,
    this.onReactionTap,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isSentByMe ? Alignment.centerRight : Alignment.centerLeft,
      child: GestureDetector(
        onLongPress: onLongPress,
        child: Container(
          margin: EdgeInsets.symmetric(vertical: 4.h, horizontal: 8.w),
          constraints: BoxConstraints(maxWidth: 0.75.sw),
          child: Column(
            crossAxisAlignment:
                isSentByMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              // Reply preview if this is a reply
              if (message.replyToMessage != null)
                _buildReplyPreview(message.replyToMessage!),

              // Main message bubble
              Container(
                padding: EdgeInsets.all(12.w),
                decoration: BoxDecoration(
                  color: isSentByMe
                      ? const Color(0xFF005C4B)
                      : const Color(0xFF202C33),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Message text
                    if (message.text.isNotEmpty)
                      Text(
                        message.text,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14.sp,
                        ),
                      ),

                    // Media (image/video/audio/document)
                    if (message.hasMedia) _buildMediaWidget(),

                    // Timestamp, edited indicator, and status
                    SizedBox(height: 4.h),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _formatTime(message.timestamp),
                          style: TextStyle(
                            color: Colors.grey[400],
                            fontSize: 11.sp,
                          ),
                        ),
                        if (message.isEdited) ...[
                          SizedBox(width: 4.w),
                          Text(
                            'edited',
                            style: TextStyle(
                              color: Colors.grey[400],
                              fontSize: 10.sp,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                        if (isSentByMe) ...[
                          SizedBox(width: 4.w),
                          MessageStatusIcon(
                            status: message.status,
                            color: Colors.grey[400]!,
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),

              // Reactions
              if (message.reactions.isNotEmpty) _buildReactions(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReplyPreview(Message replyToMessage) {
    return Container(
      margin: EdgeInsets.only(bottom: 4.h),
      padding: EdgeInsets.all(8.w),
      decoration: BoxDecoration(
        color: Colors.grey[800],
        borderRadius: BorderRadius.circular(8.r),
        border: Border(
          left: BorderSide(
            color: const Color(0xFF00A884),
            width: 3.w,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isSentByMe ? 'You' : 'Reply to',
            style: TextStyle(
              color: const Color(0xFF00A884),
              fontSize: 12.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 2.h),
          Text(
            replyToMessage.text.isNotEmpty
                ? replyToMessage.text
                : replyToMessage.mediaType ?? '',
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 12.sp,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildMediaWidget() {
    // Placeholder for media rendering
    return Container(
      margin: EdgeInsets.only(bottom: 8.h),
      padding: EdgeInsets.all(8.w),
      decoration: BoxDecoration(
        color: Colors.black26,
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _getMediaIcon(),
            color: Colors.white70,
            size: 20.sp,
          ),
          SizedBox(width: 8.w),
          Text(
            message.mediaType ?? 'Media',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 12.sp,
            ),
          ),
        ],
      ),
    );
  }

  IconData _getMediaIcon() {
    switch (message.mediaType) {
      case 'image':
        return Icons.image;
      case 'video':
        return Icons.videocam;
      case 'audio':
        return Icons.mic;
      case 'document':
        return Icons.insert_drive_file;
      default:
        return Icons.attachment;
    }
  }

  Widget _buildReactions() {
    return Container(
      margin: EdgeInsets.only(top: 4.h),
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: const Color(0xFF202C33),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: Colors.grey[700]!, width: 1),
      ),
      child: Wrap(
        spacing: 4.w,
        children: _groupReactions().entries.map((entry) {
          final emoji = entry.key;
          final count = entry.value.length;
          final reactionByMe = currentUserId != null &&
              entry.value.any((r) => r.userId == currentUserId);

          return GestureDetector(
            onTap: () => onReactionTap?.call(emoji),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
              decoration: BoxDecoration(
                color: reactionByMe
                    ? const Color(0xFF00A884).withOpacity(0.2)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(10.r),
                border: reactionByMe
                    ? Border.all(color: const Color(0xFF00A884), width: 1)
                    : null,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    emoji,
                    style: TextStyle(fontSize: 14.sp),
                  ),
                  if (count > 1) ...[
                    SizedBox(width: 2.w),
                    Text(
                      count.toString(),
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 11.sp,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Map<String, List<MessageReaction>> _groupReactions() {
    final Map<String, List<MessageReaction>> grouped = {};
    for (var reaction in message.reactions) {
      if (!grouped.containsKey(reaction.emoji)) {
        grouped[reaction.emoji] = [];
      }
      grouped[reaction.emoji]!.add(reaction);
    }
    return grouped;
  }

  String _formatTime(String timestamp) {
    try {
      final dateTime = DateTime.parse(timestamp);
      final hour = dateTime.hour.toString().padLeft(2, '0');
      final minute = dateTime.minute.toString().padLeft(2, '0');
      return '$hour:$minute';
    } catch (e) {
      return '';
    }
  }
}
