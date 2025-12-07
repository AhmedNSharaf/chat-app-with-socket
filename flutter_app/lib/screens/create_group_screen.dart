import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../controllers/auth_controller.dart';
import '../controllers/group_controller.dart';
import '../services/auth_service.dart';
import '../config/app_config.dart';
import '../models/group_model.dart';

class CreateGroupScreen extends StatefulWidget {
  const CreateGroupScreen({super.key});

  @override
  State<CreateGroupScreen> createState() => _CreateGroupScreenState();
}

class _CreateGroupScreenState extends State<CreateGroupScreen> {
  final AuthController _authController = Get.find();
  final GroupController _groupController = Get.find();
  final AuthService _authService = AuthService();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  final RxBool isLoading = false.obs;
  final RxBool isPublic = false.obs;
  final RxBool allowMembersToAddOthers = true.obs;
  final Rxn<String> selectedImagePath = Rxn<String>();
  final RxList<int> selectedMembers = <int>[].obs;

  Group? editingGroup;
  bool isEditMode = false;

  @override
  void initState() {
    super.initState();
    // Check if we're editing an existing group
    if (Get.arguments != null && Get.arguments is Group) {
      editingGroup = Get.arguments as Group;
      isEditMode = true;
      _populateEditData();
    }
  }

  void _populateEditData() {
    if (editingGroup != null) {
      _nameController.text = editingGroup!.name;
      _descriptionController.text = editingGroup!.description ?? '';
      isPublic.value = editingGroup!.isPublic;
      allowMembersToAddOthers.value = editingGroup!.allowMembersToAddOthers;
      selectedMembers.value = List.from(editingGroup!.members);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

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
                padding: EdgeInsets.all(8.w),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Get.back(),
                    ),
                    SizedBox(width: 8.w),
                    Text(
                      isEditMode ? 'Edit Group' : 'New Group',
                      style: TextStyle(
                        fontSize: 20.sp,
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    Obx(
                      () => TextButton(
                        onPressed: isLoading.value
                            ? null
                            : _createOrUpdateGroup,
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.symmetric(
                            horizontal: 16.w,
                            vertical: 8.h,
                          ),
                        ),
                        child: Text(
                          isEditMode ? 'Save' : 'Create',
                          style: TextStyle(
                            color: isLoading.value
                                ? Colors.white54
                                : Colors.white,
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Main Content
              Expanded(
                child: Obx(
                  () => isLoading.value
                      ? const Center(
                          child: CircularProgressIndicator(color: Colors.white),
                        )
                      : SingleChildScrollView(
                          child: Column(
                            children: [
                              SizedBox(height: 24.h),
                              // Group photo
                              GestureDetector(
                                onTap: _pickGroupPhoto,
                                child: Obx(
                                  () => Container(
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
                                      backgroundImage:
                                          selectedImagePath.value != null
                                          ? NetworkImage(
                                              selectedImagePath.value!,
                                            )
                                          : (isEditMode &&
                                                    editingGroup?.groupPhoto !=
                                                        null
                                                ? NetworkImage(
                                                    AppConfig.getMediaUrl(
                                                      editingGroup!.groupPhoto,
                                                    ),
                                                  )
                                                : null),
                                      child:
                                          selectedImagePath.value == null &&
                                              (editingGroup?.groupPhoto ==
                                                      null ||
                                                  !isEditMode)
                                          ? Icon(
                                              Icons.camera_alt_rounded,
                                              size: 32.sp,
                                              color: Colors.white,
                                            )
                                          : null,
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(height: 8.h),
                              Text(
                                'Tap to change photo',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 13.sp,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              SizedBox(height: 32.h),

                              // Group name
                              Padding(
                                padding: EdgeInsets.symmetric(horizontal: 16.w),
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(16.r),
                                    border: Border.all(
                                      color: Colors.white.withOpacity(0.3),
                                      width: 1.5,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.1),
                                        blurRadius: 10,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: TextField(
                                    controller: _nameController,
                                    style: const TextStyle(color: Colors.white),
                                    decoration: InputDecoration(
                                      labelText: 'Group name',
                                      labelStyle: TextStyle(
                                        color: Colors.white70,
                                        fontSize: 14.sp,
                                      ),
                                      border: InputBorder.none,
                                      enabledBorder: InputBorder.none,
                                      focusedBorder: InputBorder.none,
                                      contentPadding: EdgeInsets.symmetric(
                                        horizontal: 16.w,
                                        vertical: 16.h,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(height: 16.h),

                              // Group description
                              Padding(
                                padding: EdgeInsets.symmetric(horizontal: 16.w),
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(16.r),
                                    border: Border.all(
                                      color: Colors.white.withOpacity(0.3),
                                      width: 1.5,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.1),
                                        blurRadius: 10,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: TextField(
                                    controller: _descriptionController,
                                    style: const TextStyle(color: Colors.white),
                                    maxLines: 3,
                                    decoration: InputDecoration(
                                      labelText: 'Description (optional)',
                                      labelStyle: TextStyle(
                                        color: Colors.white70,
                                        fontSize: 14.sp,
                                      ),
                                      border: InputBorder.none,
                                      enabledBorder: InputBorder.none,
                                      focusedBorder: InputBorder.none,
                                      contentPadding: EdgeInsets.symmetric(
                                        horizontal: 16.w,
                                        vertical: 16.h,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(height: 24.h),

                              // Settings
                              Container(
                                margin: EdgeInsets.symmetric(horizontal: 16.w),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(16.r),
                                  border: Border.all(
                                    color: Colors.white.withOpacity(0.3),
                                    width: 1.5,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.1),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  children: [
                                    Obx(
                                      () => SwitchListTile(
                                        title: Text(
                                          'Public group',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 16.sp,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        subtitle: Text(
                                          'Anyone can find and join',
                                          style: TextStyle(
                                            color: Colors.white70,
                                            fontSize: 13.sp,
                                          ),
                                        ),
                                        value: isPublic.value,
                                        activeTrackColor: Colors.white
                                            .withOpacity(0.5),
                                        activeColor: Colors.white,
                                        onChanged: (value) =>
                                            isPublic.value = value,
                                      ),
                                    ),
                                    Divider(
                                      color: Colors.white.withOpacity(0.2),
                                      height: 1.h,
                                      indent: 16.w,
                                      endIndent: 16.w,
                                    ),
                                    Obx(
                                      () => SwitchListTile(
                                        title: Text(
                                          'Allow members to add others',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 16.sp,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        subtitle: Text(
                                          'Members can invite new participants',
                                          style: TextStyle(
                                            color: Colors.white70,
                                            fontSize: 13.sp,
                                          ),
                                        ),
                                        value: allowMembersToAddOthers.value,
                                        activeTrackColor: Colors.white
                                            .withOpacity(0.5),
                                        activeColor: Colors.white,
                                        onChanged: (value) =>
                                            allowMembersToAddOthers.value =
                                                value,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(height: 24.h),

                              // Members section (only for create mode)
                              if (!isEditMode) ...[
                                Padding(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 16.w,
                                  ),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'Add Members',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 16.sp,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      Obx(
                                        () => Container(
                                          padding: EdgeInsets.symmetric(
                                            horizontal: 12.w,
                                            vertical: 4.h,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.white.withOpacity(
                                              0.2,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              12.r,
                                            ),
                                          ),
                                          child: Text(
                                            '${selectedMembers.length} selected',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 13.sp,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                SizedBox(height: 12.h),
                                Container(
                                  margin: EdgeInsets.symmetric(
                                    horizontal: 16.w,
                                  ),
                                  constraints: BoxConstraints(maxHeight: 300.h),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(16.r),
                                    border: Border.all(
                                      color: Colors.white.withOpacity(0.3),
                                      width: 1.5,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.1),
                                        blurRadius: 10,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: FutureBuilder<List<dynamic>>(
                                    future: _fetchUsers(),
                                    builder: (context, snapshot) {
                                      if (snapshot.connectionState ==
                                          ConnectionState.waiting) {
                                        return const Center(
                                          child: CircularProgressIndicator(
                                            color: Colors.white,
                                          ),
                                        );
                                      }

                                      if (!snapshot.hasData ||
                                          snapshot.data!.isEmpty) {
                                        return Center(
                                          child: Padding(
                                            padding: EdgeInsets.all(24.w),
                                            child: Text(
                                              'No users available',
                                              style: TextStyle(
                                                color: Colors.white70,
                                                fontSize: 14.sp,
                                              ),
                                            ),
                                          ),
                                        );
                                      }

                                      return ClipRRect(
                                        borderRadius: BorderRadius.circular(
                                          16.r,
                                        ),
                                        child: ListView.builder(
                                          shrinkWrap: true,
                                          itemCount: snapshot.data!.length,
                                          itemBuilder: (context, index) {
                                            final user = snapshot.data![index];
                                            final userId = user['id'] as int;
                                            final username =
                                                user['username'] as String;
                                            final profilePhoto =
                                                user['profilePhoto'];

                                            return Obx(
                                              () => Container(
                                                decoration: BoxDecoration(
                                                  border:
                                                      index !=
                                                          snapshot
                                                                  .data!
                                                                  .length -
                                                              1
                                                      ? Border(
                                                          bottom: BorderSide(
                                                            color: Colors.white
                                                                .withOpacity(
                                                                  0.1,
                                                                ),
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
                                                      fontWeight:
                                                          FontWeight.w500,
                                                    ),
                                                  ),
                                                  secondary: CircleAvatar(
                                                    backgroundColor:
                                                        const Color(0xFF00A884),
                                                    backgroundImage:
                                                        profilePhoto != null
                                                        ? NetworkImage(
                                                            AppConfig.getMediaUrl(
                                                              profilePhoto,
                                                            ),
                                                          )
                                                        : null,
                                                    child: profilePhoto == null
                                                        ? Text(
                                                            username[0]
                                                                .toUpperCase(),
                                                            style:
                                                                const TextStyle(
                                                                  color: Colors
                                                                      .white,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .bold,
                                                                ),
                                                          )
                                                        : null,
                                                  ),
                                                  value: selectedMembers
                                                      .contains(userId),
                                                  activeColor: Colors.white,
                                                  checkColor: const Color(
                                                    0xFF075E54,
                                                  ),
                                                  onChanged: (bool? value) {
                                                    if (value == true) {
                                                      selectedMembers.add(
                                                        userId,
                                                      );
                                                    } else {
                                                      selectedMembers.remove(
                                                        userId,
                                                      );
                                                    }
                                                  },
                                                ),
                                              ),
                                            );
                                          },
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ],
                              SizedBox(height: 24.h),
                            ],
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<List<dynamic>> _fetchUsers() async {
    try {
      final token = await _authService.getToken();
      if (token == null) return [];

      final response = await http.get(
        Uri.parse('${AppConfig.serverUrl}/api/users'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> users = json.decode(response.body);
        final currentUserId = _authController.user.value?.id;

        // Filter out current user
        return users.where((u) => u['id'] != currentUserId).toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<void> _pickGroupPhoto() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      selectedImagePath.value = image.path;
    }
  }

  Future<void> _createOrUpdateGroup() async {
    if (_nameController.text.trim().isEmpty) {
      Get.snackbar(
        'Error',
        'Please enter a group name',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }

    isLoading.value = true;

    try {
      final token = await _authService.getToken();
      if (token == null) {
        Get.snackbar(
          'Error',
          'Not authenticated',
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        isLoading.value = false;
        return;
      }

      if (isEditMode) {
        // Update existing group
        final response = await http.put(
          Uri.parse('${AppConfig.serverUrl}/api/groups/${editingGroup!.id}'),
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
          body: json.encode({
            'name': _nameController.text.trim(),
            'description': _descriptionController.text.trim(),
            'isPublic': isPublic.value,
            'allowMembersToAddOthers': allowMembersToAddOthers.value,
          }),
        );

        if (response.statusCode == 200) {
          Get.snackbar(
            'Success',
            'Group updated successfully',
            backgroundColor: Colors.green,
            colorText: Colors.white,
          );
          Navigator.pop(context);
          await _groupController.fetchGroups();
        } else {
          Get.snackbar(
            'Error',
            'Failed to update group',
            backgroundColor: Colors.red,
            colorText: Colors.white,
          );
        }
      } else {
        // Create new group
        final response = await http.post(
          Uri.parse('${AppConfig.serverUrl}/api/groups/create'),
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
          body: json.encode({
            'name': _nameController.text.trim(),
            'description': _descriptionController.text.trim(),
            'isPublic': isPublic.value,
            'allowMembersToAddOthers': allowMembersToAddOthers.value,
            'members': selectedMembers,
          }),
        );

        if (response.statusCode == 201) {
          Get.snackbar(
            'Success',
            'Group created successfully',
            backgroundColor: Colors.green,
            colorText: Colors.white,
          );
          Navigator.pop(context);
          await _groupController.fetchGroups();
        } else {
          Get.snackbar(
            'Error',
            'Failed to create group',
            backgroundColor: Colors.red,
            colorText: Colors.white,
          );
        }
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
