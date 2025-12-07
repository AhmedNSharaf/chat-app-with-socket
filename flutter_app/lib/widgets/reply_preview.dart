import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../models/message_model.dart';

class ReplyPreview extends StatelessWidget {
  final Message message;
  final VoidCallback onCancel;

  const ReplyPreview({
    super.key,
    required this.message,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: const Color(0xFF202C33),
        border: Border(
          top: BorderSide(color: Colors.grey[800]!, width: 1),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 3.w,
            height: 40.h,
            decoration: BoxDecoration(
              color: const Color(0xFF00A884),
              borderRadius: BorderRadius.circular(2.r),
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Replying to',
                  style: TextStyle(
                    color: const Color(0xFF00A884),
                    fontSize: 12.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  message.text.isNotEmpty
                      ? message.text
                      : _getMediaLabel(message.mediaType),
                  style: TextStyle(
                    color: Colors.grey[400],
                    fontSize: 13.sp,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(
              Icons.close,
              color: Colors.grey[400],
              size: 20.sp,
            ),
            onPressed: onCancel,
          ),
        ],
      ),
    );
  }

  String _getMediaLabel(String? mediaType) {
    switch (mediaType) {
      case 'image':
        return '📷 Photo';
      case 'video':
        return '🎥 Video';
      case 'audio':
        return '🎤 Voice message';
      case 'document':
        return '📄 Document';
      default:
        return 'Message';
    }
  }
}
