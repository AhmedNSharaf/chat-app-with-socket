import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../controllers/group_controller.dart';
import '../controllers/auth_controller.dart';
import '../models/group_model.dart';
import '../services/auth_service.dart';
import '../config/app_config.dart';

class GroupInfoScreen extends StatelessWidget {
  GroupInfoScreen({super.key});

  final GroupController _groupController = Get.find();
  final AuthController _authController = Get.find();
  final AuthService _authService = AuthService();

  @override
  Widget build(BuildContext context) {
    final Group group = Get.arguments as Group;
    final currentUser = _authController.user.value;
    final isAdmin = group.isAdmin(currentUser?.id ?? -1);
    final isCreator = group.isCreator(currentUser?.id ?? -1);
    final isMuted = group.isMutedBy(currentUser?.id ?? -1);

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
                padding: EdgeInsets.all(8.w),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Get.back(),
                    ),
                    SizedBox(width: 8.w),
                    Text(
                      'Group Info',
                      style: TextStyle(
                        fontSize: 20.sp,
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              // Scrollable content
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      // Group header
                      Container(
                        padding: EdgeInsets.all(24.w),
                        child: Column(
                          children: [
                            Container(
                              width: 130.w,
                              height: 130.w,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.2),
                                    blurRadius: 20,
                                    offset: const Offset(0, 10),
                                  ),
                                ],
                              ),
                              child: CircleAvatar(
                                radius: 60.r,
                                backgroundColor: const Color(0xFF00A884),
                                backgroundImage: group.groupPhoto != null
                                    ? NetworkImage(
                                        AppConfig.getMediaUrl(group.groupPhoto),
                                      )
                                    : null,
                                child: group.groupPhoto == null
                                    ? Icon(Icons.group,
                                        size: 60.sp, color: Colors.white)
                                    : null,
                              ),
                            ),
                            SizedBox(height: 16.h),
                            Text(
                              group.name,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 24.sp,
                                fontWeight: FontWeight.w600,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            SizedBox(height: 8.h),
                            Text(
                              'Group • ${group.members.length} members',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 14.sp,
                              ),
                            ),
                            if (group.description != null &&
                                group.description!.isNotEmpty) ...[
                              SizedBox(height: 16.h),
                              Container(
                                padding: EdgeInsets.all(12.w),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(12.r),
                                  border: Border.all(
                                    color: Colors.white.withOpacity(0.3),
                                    width: 1.5,
                                  ),
                                ),
                                child: Text(
                                  group.description!,
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 14.sp,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ],
                            if (isAdmin) ...[
                              SizedBox(height: 16.h),
                              ElevatedButton.icon(
                                onPressed: () =>
                                    Get.toNamed('/edit-group', arguments: group),
                                icon:
                                    const Icon(Icons.edit, color: Color(0xFF075E54)),
                                label: Text(
                                  'Edit Group Info',
                                  style: TextStyle(
                                      color: const Color(0xFF075E54),
                                      fontWeight: FontWeight.w600),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 24.w,
                                    vertical: 12.h,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(24.r),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      SizedBox(height: 8.h),
                      // Group settings
                      _buildSectionHeader('Settings'),
                      _buildSettingTile(
                        icon: isMuted ? Icons.volume_off : Icons.volume_up,
                        title: isMuted
                            ? 'Unmute notifications'
                            : 'Mute notifications',
                        onTap: () => _toggleMute(group, isMuted),
                      ),
                      _buildSettingTile(
                        icon: Icons.block,
                        title: 'Report group',
                        iconColor: Colors.red,
                        titleColor: Colors.red,
                        onTap: () {
                          Get.snackbar(
                            'Report',
                            'Report feature coming soon',
                            backgroundColor: Colors.red,
                            colorText: Colors.white,
                          );
                        },
                      ),
                      SizedBox(height: 8.h),
                      // Members section
                      _buildSectionHeader(
                          '${group.members.length} Members',
                          trailing: isAdmin
                              ? IconButton(
                                  icon: const Icon(Icons.person_add,
                                      color: Colors.white),
                                  onPressed: () =>
                                      _showAddMemberDialog(context, group),
                                )
                              : null),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                        ),
                        child: ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: group.members.length,
                          itemBuilder: (context, index) {
                            final memberId = group.members[index];
                            final memberIsAdmin = group.admins.contains(memberId);
                            final memberIsCreator = group.createdBy == memberId;
                            final isCurrentUser = memberId == currentUser?.id;

                            return Container(
                              decoration: BoxDecoration(
                                border: index != group.members.length - 1
                                    ? Border(
                                        bottom: BorderSide(
                                          color: Colors.white.withOpacity(0.1),
                                          width: 1,
                                        ),
                                      )
                                    : null,
                              ),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: const Color(0xFF00A884),
                                  child: Text(
                                    'U${memberId.toString().substring(0, 1)}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                title: Row(
                                  children: [
                                    Text(
                                      isCurrentUser ? 'You' : 'User $memberId',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 16.sp,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    if (memberIsCreator) ...[
                                      SizedBox(width: 8.w),
                                      Container(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: 6.w,
                                          vertical: 2.h,
                                        ),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFFFD700)
                                              .withOpacity(0.3),
                                          borderRadius:
                                              BorderRadius.circular(4.r),
                                          border: Border.all(
                                            color: const Color(0xFFFFD700),
                                            width: 1,
                                          ),
                                        ),
                                        child: Text(
                                          'Creator',
                                          style: TextStyle(
                                            color: const Color(0xFFFFD700),
                                            fontSize: 10.sp,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ] else if (memberIsAdmin) ...[
                                      SizedBox(width: 8.w),
                                      Container(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: 6.w,
                                          vertical: 2.h,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withOpacity(0.3),
                                          borderRadius:
                                              BorderRadius.circular(4.r),
                                          border: Border.all(
                                            color: Colors.white,
                                            width: 1,
                                          ),
                                        ),
                                        child: Text(
                                          'Admin',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 10.sp,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                                trailing: isAdmin && !isCurrentUser
                                    ? PopupMenuButton<String>(
                                        icon: const Icon(Icons.more_vert,
                                            color: Colors.white70),
                                        color: Colors.white.withOpacity(0.15),
                                        onSelected: (value) {
                                          _handleMemberAction(
                                              value, memberId, group);
                                        },
                                        itemBuilder: (context) => [
                                          if (!memberIsCreator && !memberIsAdmin)
                                            const PopupMenuItem(
                                              value: 'promote',
                                              child: Text(
                                                'Make group admin',
                                                style: TextStyle(
                                                    color: Colors.white),
                                              ),
                                            ),
                                          if (memberIsAdmin &&
                                              !memberIsCreator &&
                                              isCreator)
                                            const PopupMenuItem(
                                              value: 'demote',
                                              child: Text(
                                                'Dismiss as admin',
                                                style: TextStyle(
                                                    color: Colors.white),
                                              ),
                                            ),
                                          const PopupMenuItem(
                                            value: 'remove',
                                            child: Text(
                                              'Remove from group',
                                              style: TextStyle(color: Colors.red),
                                            ),
                                          ),
                                        ],
                                      )
                                    : null,
                              ),
                            );
                          },
                        ),
                      ),
                      SizedBox(height: 8.h),
                      // Actions
                      _buildActionTile(
                        icon: Icons.exit_to_app,
                        title: 'Exit group',
                        iconColor: Colors.red,
                        titleColor: Colors.red,
                        onTap: () => _showExitGroupDialog(context, group),
                      ),
                      if (isCreator)
                        _buildActionTile(
                          icon: Icons.delete_forever,
                          title: 'Delete group',
                          iconColor: Colors.red,
                          titleColor: Colors.red,
                          onTap: () => _showDeleteGroupDialog(context, group),
                        ),
                      SizedBox(height: 24.h),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, {Widget? trailing}) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: TextStyle(
              color: Colors.white,
              fontSize: 16.sp,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (trailing != null) trailing,
        ],
      ),
    );
  }

  Widget _buildSettingTile({
    required IconData icon,
    required String title,
    Color? iconColor,
    Color? titleColor,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: EdgeInsets.only(bottom: 1.h),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
      ),
      child: ListTile(
        leading: Icon(
          icon,
          color: iconColor ?? Colors.white,
          size: 24.sp,
        ),
        title: Text(
          title,
          style: TextStyle(
            color: titleColor ?? Colors.white,
            fontSize: 16.sp,
            fontWeight: FontWeight.w500,
          ),
        ),
        onTap: onTap,
      ),
    );
  }

  Widget _buildActionTile({
    required IconData icon,
    required String title,
    Color? iconColor,
    Color? titleColor,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: EdgeInsets.only(bottom: 1.h),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
      ),
      child: ListTile(
        leading: Icon(
          icon,
          color: iconColor ?? Colors.white,
          size: 24.sp,
        ),
        title: Text(
          title,
          style: TextStyle(
            color: titleColor ?? Colors.white,
            fontSize: 16.sp,
            fontWeight: FontWeight.w600,
          ),
        ),
        onTap: onTap,
      ),
    );
  }

  Future<void> _toggleMute(Group group, bool isMuted) async {
    try {
      final token = await _authService.getToken();
      if (token == null) {
        Get.snackbar('Error', 'Not authenticated',
            backgroundColor: Colors.red, colorText: Colors.white);
        return;
      }

      final response = await http.post(
        Uri.parse('${AppConfig.serverUrl}/api/groups/${group.id}/mute'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'mute': !isMuted, // Toggle the current state
        }),
      );

      if (response.statusCode == 200) {
        Get.snackbar(
          'Success',
          isMuted
              ? 'Group notifications unmuted'
              : 'Group notifications muted',
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );

        // Refresh groups
        await _groupController.fetchGroups();

        // Update current screen
        Get.back(); // Go back to refresh
      } else {
        final error = json.decode(response.body);
        Get.snackbar(
          'Error',
          error['message'] ?? 'Failed to update mute settings',
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'An error occurred: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  void _handleMemberAction(String action, int memberId, Group group) async {
    final token = await _authService.getToken();
    if (token == null) {
      Get.snackbar('Error', 'Not authenticated',
          backgroundColor: Colors.red, colorText: Colors.white);
      return;
    }

    String? endpoint;
    String? successMessage;

    switch (action) {
      case 'promote':
        endpoint = '${AppConfig.serverUrl}/api/groups/${group.id}/promote';
        successMessage = 'User promoted to admin';
        break;
      case 'demote':
        endpoint = '${AppConfig.serverUrl}/api/groups/${group.id}/demote';
        successMessage = 'User dismissed as admin';
        break;
      case 'remove':
        endpoint =
            '${AppConfig.serverUrl}/api/groups/${group.id}/remove-member';
        successMessage = 'User removed from group';
        break;
    }

    if (endpoint == null) return;

    try {
      final response = await http.post(
        Uri.parse(endpoint),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'userId': memberId,
        }),
      );

      if (response.statusCode == 200) {
        Get.snackbar(
          'Success',
          successMessage!,
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );

        // Refresh groups
        await _groupController.fetchGroups();

        // Update current screen
        Get.back(); // Go back to refresh
      } else {
        final error = json.decode(response.body);
        Get.snackbar(
          'Error',
          error['message'] ?? 'Failed to perform action',
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'An error occurred: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  void _showExitGroupDialog(BuildContext context, Group group) {
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
              Text(
                'Exit group?',
                style:
                    TextStyle(color: Colors.white, fontSize: 20.sp, fontWeight: FontWeight.w600),
              ),
              SizedBox(height: 16.h),
              Text(
                'Are you sure you want to exit "${group.name}"?',
                style: TextStyle(color: Colors.white70, fontSize: 14.sp),
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
                          horizontal: 16.w, vertical: 8.h),
                    ),
                    child: const Text(
                      'Cancel',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                  SizedBox(width: 8.w),
                  ElevatedButton(
                    onPressed: () => _leaveGroup(group),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      padding: EdgeInsets.symmetric(
                          horizontal: 16.w, vertical: 8.h),
                    ),
                    child: const Text(
                      'Exit',
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

  Future<void> _leaveGroup(Group group) async {
    Get.back(); // Close dialog

    try {
      final token = await _authService.getToken();
      if (token == null) {
        Get.snackbar('Error', 'Not authenticated',
            backgroundColor: Colors.red, colorText: Colors.white);
        return;
      }

      final response = await http.post(
        Uri.parse('${AppConfig.serverUrl}/api/groups/${group.id}/leave'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        Get.back(); // Go back to groups list
        Get.snackbar(
          'Success',
          'You have left the group',
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );

        // Refresh groups
        await _groupController.fetchGroups();
      } else {
        final error = json.decode(response.body);
        Get.snackbar(
          'Error',
          error['message'] ?? 'Failed to leave group',
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'An error occurred: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  void _showDeleteGroupDialog(BuildContext context, Group group) {
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
              Text(
                'Delete group?',
                style:
                    TextStyle(color: Colors.white, fontSize: 20.sp, fontWeight: FontWeight.w600),
              ),
              SizedBox(height: 16.h),
              Text(
                'Are you sure you want to permanently delete "${group.name}"? This action cannot be undone.',
                style: TextStyle(color: Colors.white70, fontSize: 14.sp),
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
                          horizontal: 16.w, vertical: 8.h),
                    ),
                    child: const Text(
                      'Cancel',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                  SizedBox(width: 8.w),
                  ElevatedButton(
                    onPressed: () => _deleteGroup(group),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      padding: EdgeInsets.symmetric(
                          horizontal: 16.w, vertical: 8.h),
                    ),
                    child: const Text(
                      'Delete',
                      style:
                          TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
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

  Future<void> _deleteGroup(Group group) async {
    Get.back(); // Close dialog

    try {
      final token = await _authService.getToken();
      if (token == null) {
        Get.snackbar('Error', 'Not authenticated',
            backgroundColor: Colors.red, colorText: Colors.white);
        return;
      }

      final response = await http.delete(
        Uri.parse('${AppConfig.serverUrl}/api/groups/${group.id}'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        Get.back(); // Go back to groups list
        Get.snackbar(
          'Success',
          'Group has been deleted',
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );

        // Refresh groups
        await _groupController.fetchGroups();
      } else {
        final error = json.decode(response.body);
        Get.snackbar(
          'Error',
          error['message'] ?? 'Failed to delete group',
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'An error occurred: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  Future<void> _showAddMemberDialog(BuildContext context, Group group) async {
    final RxList<int> selectedMembers = <int>[].obs;
    final RxBool isLoading = false.obs;

    // Fetch available users (not already in group)
    final availableUsers = await _fetchAvailableUsers(group);

    if (availableUsers.isEmpty) {
      Get.snackbar(
        'No Users',
        'All users are already members of this group',
        backgroundColor: Colors.orange,
        colorText: Colors.white,
      );
      return;
    }

    Get.dialog(
      AlertDialog(
        backgroundColor: Colors.transparent,
        contentPadding: EdgeInsets.zero,
        content: Container(
          width: double.maxFinite,
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
              Text(
                'Add Members',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 20.sp,
                    fontWeight: FontWeight.w600),
              ),
              SizedBox(height: 8.h),
              Obx(
                () => Text(
                  '${selectedMembers.length} selected',
                  style: TextStyle(color: Colors.white70, fontSize: 14.sp),
                ),
              ),
              SizedBox(height: 16.h),
              Flexible(
                child: Container(
                  constraints: BoxConstraints(maxHeight: 300.h),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: availableUsers.length,
                    itemBuilder: (context, index) {
                      final user = availableUsers[index];
                      final userId = user['id'] as int;
                      final username = user['username'] as String;
                      final profilePhoto = user['profilePhoto'];

                      return Obx(
                        () => Container(
                          decoration: BoxDecoration(
                            border: index != availableUsers.length - 1
                                ? Border(
                                    bottom: BorderSide(
                                      color: Colors.white.withOpacity(0.1),
                                      width: 1,
                                    ),
                                  )
                                : null,
                          ),
                          child: CheckboxListTile(
                            title: Text(
                              username,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16.sp,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            secondary: CircleAvatar(
                              backgroundColor: const Color(0xFF00A884),
                              backgroundImage: profilePhoto != null
                                  ? NetworkImage(
                                      AppConfig.getMediaUrl(profilePhoto),
                                    )
                                  : null,
                              child: profilePhoto == null
                                  ? Text(
                                      username[0].toUpperCase(),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    )
                                  : null,
                            ),
                            value: selectedMembers.contains(userId),
                            activeColor: Colors.white,
                            checkColor: const Color(0xFF075E54),
                            onChanged: (bool? value) {
                              if (value == true) {
                                selectedMembers.add(userId);
                              } else {
                                selectedMembers.remove(userId);
                              }
                            },
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              SizedBox(height: 16.h),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Get.back(),
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.symmetric(
                          horizontal: 16.w, vertical: 8.h),
                    ),
                    child: const Text(
                      'Cancel',
                      style: TextStyle(color: Colors.white70),
                    ),
                  ),
                  SizedBox(width: 8.w),
                  Obx(
                    () => ElevatedButton(
                      onPressed: isLoading.value || selectedMembers.isEmpty
                          ? null
                          : () => _addMembersToGroup(
                                group,
                                selectedMembers,
                                isLoading,
                              ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        disabledBackgroundColor: Colors.white.withOpacity(0.3),
                        padding: EdgeInsets.symmetric(
                            horizontal: 16.w, vertical: 8.h),
                      ),
                      child: isLoading.value
                          ? SizedBox(
                              width: 20.w,
                              height: 20.h,
                              child: const CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Color(0xFF075E54),
                              ),
                            )
                          : Text(
                              'Add',
                              style: TextStyle(
                                color: selectedMembers.isEmpty
                                    ? Colors.grey
                                    : const Color(0xFF075E54),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
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

  Future<List<dynamic>> _fetchAvailableUsers(Group group) async {
    try {
      final token = await _authService.getToken();
      if (token == null) return [];

      final response = await http.get(
        Uri.parse('${AppConfig.serverUrl}/api/auth/users'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> users = json.decode(response.body);
        final currentUserId = _authController.user.value?.id;

        // Filter out current user and existing group members
        return users
            .where((u) =>
                u['id'] != currentUserId && !group.members.contains(u['id']))
            .toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<void> _addMembersToGroup(
    Group group,
    RxList<int> selectedMembers,
    RxBool isLoading,
  ) async {
    isLoading.value = true;

    try {
      final token = await _authService.getToken();
      if (token == null) {
        Get.snackbar('Error', 'Not authenticated',
            backgroundColor: Colors.red, colorText: Colors.white);
        return;
      }

      final response = await http.post(
        Uri.parse('${AppConfig.serverUrl}/api/groups/${group.id}/add-member'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'memberIds': selectedMembers.toList(),
        }),
      );

      if (response.statusCode == 200) {
        Get.back(); // Close dialog
        Get.snackbar(
          'Success',
          '${selectedMembers.length} member(s) added to the group',
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );

        // Refresh groups
        await _groupController.fetchGroups();

        // Update current screen
        Get.back(); // Go back to refresh
      } else {
        final error = json.decode(response.body);
        Get.snackbar(
          'Error',
          error['message'] ?? 'Failed to add members',
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'An error occurred: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }
}
