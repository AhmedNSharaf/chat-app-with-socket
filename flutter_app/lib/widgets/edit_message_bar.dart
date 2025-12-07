import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../models/message_model.dart';

class EditMessageBar extends StatelessWidget {
  final Message message;
  final TextEditingController textController;
  final VoidCallback onCancel;
  final VoidCallback onSave;

  const EditMessageBar({
    super.key,
    required this.message,
    required this.textController,
    required this.onCancel,
    required this.onSave,
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
                Row(
                  children: [
                    Icon(
                      Icons.edit,
                      color: const Color(0xFF00A884),
                      size: 16.sp,
                    ),
                    SizedBox(width: 4.w),
                    Text(
                      'Edit message',
                      style: TextStyle(
                        color: const Color(0xFF00A884),
                        fontSize: 12.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 2.h),
                Text(
                  message.text,
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
          IconButton(
            icon: Icon(
              Icons.check,
              color: const Color(0xFF00A884),
              size: 24.sp,
            ),
            onPressed: onSave,
          ),
        ],
      ),
    );
  }
}
