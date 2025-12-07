import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../controllers/group_controller.dart';
import '../controllers/auth_controller.dart';
import '../models/group_model.dart';
import '../config/app_config.dart';

class GroupsListScreen extends StatelessWidget {
  GroupsListScreen({super.key});

  final GroupController _groupController = Get.put(GroupController());
  final AuthController _authController = Get.find();

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
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Get.back(),
                    ),
                    SizedBox(width: 8.w),
                    Text(
                      'Groups',
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
                        child: const Icon(Icons.search, color: Colors.white),
                      ),
                      onPressed: () {
                        // TODO: Implement search
                      },
                    ),
                  ],
                ),
              ),
              // Groups List
              Expanded(
                child: Obx(() {
                  if (_groupController.isLoading.value) {
                    return const Center(
                      child: CircularProgressIndicator(color: Colors.white),
                    );
                  }

                  if (_groupController.groups.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 100.w,
                            height: 100.w,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.15),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.group_outlined,
                              size: 50.sp,
                              color: Colors.white70,
                            ),
                          ),
                          SizedBox(height: 24.h),
                          Text(
                            'No groups yet',
                            style: TextStyle(
                              fontSize: 20.sp,
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          SizedBox(height: 8.h),
                          Text(
                            'Create a group to start chatting',
                            style: TextStyle(
                              fontSize: 14.sp,
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: EdgeInsets.symmetric(horizontal: 12.w),
                    itemCount: _groupController.groups.length,
                    itemBuilder: (context, index) {
                      final group = _groupController.groups[index];
                      final currentUser = _authController.user.value;

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
                          leading: CircleAvatar(
                            radius: 28.r,
                            backgroundColor: const Color(0xFF00A884),
                            backgroundImage: group.groupPhoto != null
                                ? NetworkImage(
                                    AppConfig.getMediaUrl(group.groupPhoto),
                                  )
                                : null,
                            child: group.groupPhoto == null
                                ? Icon(
                                    Icons.group_rounded,
                                    size: 28.sp,
                                    color: Colors.white,
                                  )
                                : null,
                          ),
                          title: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  group.name,
                                  style: TextStyle(
                                    fontSize: 16.sp,
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (group.isMutedBy(currentUser?.id ?? -1))
                                Padding(
                                  padding: EdgeInsets.only(left: 8.w),
                                  child: Icon(
                                    Icons.volume_off_rounded,
                                    size: 16.sp,
                                    color: Colors.white70,
                                  ),
                                ),
                            ],
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(height: 4.h),
                              if (group.lastMessage != null)
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        group.lastMessage!.text ?? '',
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
                                        group.lastMessage!.timestamp ?? '',
                                      ),
                                      style: TextStyle(
                                        fontSize: 12.sp,
                                        color: Colors.white60,
                                      ),
                                    ),
                                  ],
                                )
                              else
                                Row(
                                  children: [
                                    Icon(
                                      Icons.people_outline,
                                      size: 14.sp,
                                      color: Colors.white70,
                                    ),
                                    SizedBox(width: 4.w),
                                    Text(
                                      '${group.members.length} members',
                                      style: TextStyle(
                                        fontSize: 13.sp,
                                        color: Colors.white70,
                                      ),
                                    ),
                                  ],
                                ),
                            ],
                          ),
                          trailing: group.isAdmin(currentUser?.id ?? -1)
                              ? Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 10.w,
                                    vertical: 6.h,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(8.r),
                                  ),
                                  child: Text(
                                    'Admin',
                                    style: TextStyle(
                                      fontSize: 11.sp,
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                )
                              : null,
                          onTap: () => _openGroupChat(group),
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
      floatingActionButton: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: FloatingActionButton(
          onPressed: () => Get.toNamed('/create-group'),
          backgroundColor: Colors.white,
          child: const Icon(
            Icons.add_rounded,
            color: Color(0xFF075E54),
            size: 32,
          ),
        ),
      ),
    );
  }

  void _openGroupChat(Group group) {
    Get.toNamed('/group-chat', arguments: group);
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
}
