import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shimmer/shimmer.dart';
import '../controllers/auth_controller.dart';
import '../controllers/users_controller.dart';
import '../models/user_model.dart';
import '../widgets/online_indicator.dart';
import '../widgets/last_seen_text.dart';
import '../config/app_config.dart';

class UsersListScreen extends StatelessWidget {
  UsersListScreen({super.key});

  final AuthController _authController = Get.find();
  final UsersController _usersController = Get.put(UsersController());

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
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 8.h),
                child: Row(
                  children: [
                    Text(
                      'Chats',
                      style: TextStyle(
                        fontSize: 24.sp,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: Container(
                        padding: EdgeInsets.all(8.w),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                        child: const Icon(Icons.group_rounded,
                            color: Colors.white),
                      ),
                      onPressed: () => Get.toNamed('/groups'),
                      tooltip: 'Groups',
                    ),
                    IconButton(
                      icon: Container(
                        padding: EdgeInsets.all(8.w),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                        child: const Icon(Icons.person_rounded,
                            color: Colors.white),
                      ),
                      onPressed: () => Get.toNamed('/profile'),
                      tooltip: 'Profile',
                    ),
                    IconButton(
                      icon: Container(
                        padding: EdgeInsets.all(8.w),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                        child: const Icon(Icons.logout,
                            color: Colors.white),
                      ),
                      onPressed: () => _showLogoutDialog(context),
                      tooltip: 'Logout',
                    ),
                  ],
                ),
              ),
              // User List
              Expanded(
                child: Obx(() {
                  if (_usersController.isLoading.value) {
                    return _buildShimmerLoading();
                  }

                  return ListView.builder(
                    padding: EdgeInsets.symmetric(horizontal: 12.w),
                    itemCount: _usersController.users.length,
                    itemBuilder: (context, index) {
                      final user = _usersController.users[index];
                      final currentUser = _authController.user.value;

                      // Don't show current user in the list
                      if (user.id == currentUser?.id) {
                        return const SizedBox.shrink();
                      }

                      return Container(
                        margin: EdgeInsets.only(bottom: 8.h),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(16.r),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.2),
                            width: 1,
                          ),
                        ),
                        child: ListTile(
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 16.w,
                            vertical: 8.h,
                          ),
                          leading: Stack(
                            children: [
                              CircleAvatar(
                                radius: 28.r,
                                backgroundColor: const Color(0xFF00A884),
                                backgroundImage: user.profilePhoto != null
                                    ? NetworkImage(
                                        AppConfig.getMediaUrl(user.profilePhoto),
                                      )
                                    : null,
                                child: user.profilePhoto == null
                                    ? Text(
                                        user.username[0].toUpperCase(),
                                        style: TextStyle(
                                          fontSize: 20.sp,
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      )
                                    : null,
                              ),
                              Positioned(
                                right: 0,
                                bottom: 0,
                                child: OnlineIndicator(
                                  isOnline: user.isOnline,
                                  status: user.status,
                                ),
                              ),
                            ],
                          ),
                          title: Text(
                            user.username,
                            style: TextStyle(
                              fontSize: 16.sp,
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          subtitle: Obx(() {
                            final lastMessageData =
                                _usersController.lastMessages[user.id];

                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                SizedBox(height: 4.h),
                                // Last message or status
                                if (lastMessageData != null)
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          lastMessageData['text'] ??
                                              'No messages yet',
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
                                        _formatLastMessageTime(
                                          lastMessageData['timestamp'] ?? '',
                                        ),
                                        style: TextStyle(
                                          fontSize: 12.sp,
                                          color: Colors.white60,
                                        ),
                                      ),
                                    ],
                                  )
                                else
                                  LastSeenText(
                                    isOnline: user.isOnline,
                                    status: user.status,
                                    lastSeen: user.lastSeen,
                                    customStatus: user.customStatus,
                                    fontSize: 13,
                                  ),

                                // Online status if has messages
                                if (lastMessageData != null)
                                  Padding(
                                    padding: EdgeInsets.only(top: 4.h),
                                    child: LastSeenText(
                                      isOnline: user.isOnline,
                                      status: user.status,
                                      lastSeen: user.lastSeen,
                                      customStatus: user.customStatus,
                                      fontSize: 12,
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
              ),
            ],
          ),
        ),
      ),
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
      baseColor: Colors.white.withOpacity(0.1),
      highlightColor: Colors.white.withOpacity(0.2),
      child: ListView.builder(
        padding: EdgeInsets.symmetric(horizontal: 12.w),
        itemCount: 8, // Show 8 skeleton items
        itemBuilder: (context, index) {
          return Container(
            margin: EdgeInsets.only(bottom: 8.h),
            padding: EdgeInsets.all(16.w),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(16.r),
              border: Border.all(
                color: Colors.white.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                // Profile picture skeleton
                Container(
                  width: 56.w,
                  height: 56.w,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.3),
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
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(4.r),
                        ),
                      ),
                      SizedBox(height: 8.h),
                      // Last message skeleton
                      Container(
                        height: 14.h,
                        width: 200.w,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(4.r),
                        ),
                      ),
                    ],
                  ),
                ),
                // Timestamp skeleton
                Container(
                  height: 12.h,
                  width: 50.w,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(4.r),
                  ),
                ),
              ],
            ),
          );
        },
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
