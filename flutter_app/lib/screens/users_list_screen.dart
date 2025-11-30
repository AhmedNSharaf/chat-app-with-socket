import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get_connect/http/src/utils/utils.dart';
import 'package:shimmer/shimmer.dart';
import '../controllers/auth_controller.dart';
import '../controllers/users_controller.dart';
import '../models/user_model.dart';

class UsersListScreen extends StatelessWidget {
  UsersListScreen({super.key});

  final AuthController _authController = Get.find();
  final UsersController _usersController = Get.put(UsersController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B141A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0B141A),
        elevation: 0,
        title: Text(
          'Chat_ty',
          style: TextStyle(
            fontSize: 20.sp,
            color: Colors.white,
            fontWeight: FontWeight.w500,
          ),
        ),
        automaticallyImplyLeading: F,
        actions: [
          IconButton(
            icon: const Icon(Icons.person, color: Colors.white),
            onPressed: () => Get.toNamed('/profile'),
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: () => _authController.logout(),
          ),
        ],
      ),
      body: Obx(() {
        if (_usersController.isLoading.value) {
          return _buildShimmerLoading();
        }

        return ListView.builder(
          padding: EdgeInsets.only(top: 1.h),
          itemCount: _usersController.users.length,
          itemBuilder: (context, index) {
            final user = _usersController.users[index];
            final currentUser = _authController.user.value;

            // Don't show current user in the list
            if (user.id == currentUser?.id) {
              return const SizedBox.shrink();
            }

            return Container(
              margin: EdgeInsets.only(bottom: 1.h),
              color: const Color(0xFF0B141A),
              child: ListTile(
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 16.w,
                  vertical: 8.h,
                ),
                leading: CircleAvatar(
                  backgroundColor: Colors.grey[600],
                  backgroundImage: user.profilePhoto != null
                      ? NetworkImage(
                          'http://192.168.1.6:3000${user.profilePhoto}',
                        )
                      : null,
                  child: user.profilePhoto == null
                      ? Text(
                          user.username[0].toUpperCase(),
                          style: TextStyle(
                            fontSize: 18.sp,
                            color: Colors.white,
                          ),
                        )
                      : null,
                ),
                title: Text(
                  user.username,
                  style: TextStyle(
                    fontSize: 16.sp,
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                subtitle: Obx(() {
                  final lastMessageData =
                      _usersController.lastMessages[user.id];
                  if (lastMessageData == null) {
                    return Text(
                      'No messages yet',
                      style: TextStyle(fontSize: 14.sp, color: Colors.white70),
                    );
                  }

                  final messageText =
                      lastMessageData['text'] ?? 'No messages yet';
                  final timestamp = lastMessageData['timestamp'] ?? '';

                  return Row(
                    children: [
                      Expanded(
                        child: Text(
                          messageText,
                          style: TextStyle(
                            fontSize: 14.sp,
                            color: Colors.white70,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      SizedBox(width: 8.w),
                      Text(
                        _formatLastMessageTime(timestamp),
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: Colors.white54,
                        ),
                      ),
                    ],
                  );
                }),
                onTap: () => _startChat(user),
              ),
            );
          },
        );
      }),
    );
  }

  void _startChat(User user) {
    Get.toNamed('/chat', arguments: user);
  }

  String _formatLastMessageTime(String timestamp) {
    if (timestamp.isEmpty) return '';

    try {
      final dateTime = DateTime.parse(timestamp);
      final now = DateTime.now();
      final difference = now.difference(dateTime);

      if (difference.inDays == 0) {
        return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
      } else if (difference.inDays == 1) {
        return 'Yesterday';
      } else if (difference.inDays < 7) {
        return '${difference.inDays}d ago';
      } else {
        return '${dateTime.day}/${dateTime.month}/${dateTime.year.toString().substring(2)}';
      }
    } catch (e) {
      return '';
    }
  }

  Widget _buildShimmerLoading() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[700]!,
      highlightColor: Colors.grey[600]!,
      child: ListView.builder(
        itemCount: 8, // Show 8 skeleton items
        itemBuilder: (context, index) {
          return Container(
            margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
            padding: EdgeInsets.all(16.w),
            decoration: BoxDecoration(
              color: const Color(0xFF1F2C34),
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Row(
              children: [
                // Profile picture skeleton
                Container(
                  width: 50.w,
                  height: 50.w,
                  decoration: BoxDecoration(
                    color: Colors.grey[600],
                    shape: BoxShape.circle,
                  ),
                ),
                SizedBox(width: 16.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Username skeleton
                      Container(
                        height: 16.h,
                        width: 120.w,
                        color: Colors.grey[600],
                      ),
                      SizedBox(height: 8.h),
                      // Last message skeleton
                      Container(
                        height: 14.h,
                        width: 200.w,
                        color: Colors.grey[600],
                      ),
                    ],
                  ),
                ),
                // Timestamp skeleton
                Container(height: 12.h, width: 50.w, color: Colors.grey[600]),
              ],
            ),
          );
        },
      ),
    );
  }
}
