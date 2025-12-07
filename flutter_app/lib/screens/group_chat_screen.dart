import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_picker/image_picker.dart';
import '../controllers/group_controller.dart';
import '../controllers/auth_controller.dart';
import '../models/group_model.dart';
import '../models/group_message_model.dart';
import '../config/app_config.dart';

class GroupChatScreen extends StatelessWidget {
  GroupChatScreen({super.key});

  final GroupController _groupController = Get.find();
  final AuthController _authController = Get.find();
  final TextEditingController _messageController = TextEditingController();
  final TextEditingController _editController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final Group group = Get.arguments as Group;
    _groupController.setCurrentGroup(group);

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
                    GestureDetector(
                      onTap: () => Get.toNamed('/group-info', arguments: group),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 20.r,
                            backgroundColor: const Color(0xFF00A884),
                            backgroundImage: group.groupPhoto != null
                                ? NetworkImage(
                                    AppConfig.getMediaUrl(group.groupPhoto),
                                  )
                                : null,
                            child: group.groupPhoto == null
                                ? Icon(Icons.group, size: 20.sp, color: Colors.white)
                                : null,
                          ),
                          SizedBox(width: 12.w),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                group.name,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18.sp,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Obx(() {
                                final typingText = _groupController.typingUsersText;
                                if (typingText.isNotEmpty) {
                                  return Text(
                                    typingText,
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 13.sp,
                                    ),
                                  );
                                }
                                return Text(
                                  '${group.members.length} members',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 13.sp,
                                  ),
                                );
                              }),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.videocam, color: Colors.white),
                      onPressed: () {},
                    ),
                    IconButton(
                      icon: const Icon(Icons.call, color: Colors.white),
                      onPressed: () {},
                    ),
                    PopupMenuButton<String>(
                      icon: const Icon(Icons.more_vert, color: Colors.white),
                      color: Colors.white.withOpacity(0.15),
                      onSelected: (value) {
                        if (value == 'info') {
                          Get.toNamed('/group-info', arguments: group);
                        }
                      },
                      itemBuilder: (context) => [
                        PopupMenuItem(
                          value: 'info',
                          child: Text(
                            'Group info',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Messages area
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.1),
                  ),
                  child: Obx(() {
                    if (_groupController.isLoading.value &&
                        _groupController.groupMessages.isEmpty) {
                      return const Center(
                        child: CircularProgressIndicator(color: Colors.white),
                      );
                    }

                    if (_groupController.groupMessages.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.message_outlined,
                              size: 80.sp,
                              color: Colors.white.withOpacity(0.5),
                            ),
                            SizedBox(height: 16.h),
                            Text(
                              'No messages yet',
                              style: TextStyle(
                                fontSize: 18.sp,
                                color: Colors.white,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            SizedBox(height: 8.h),
                            Text(
                              'Start the conversation',
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
                      controller: _groupController.scrollController,
                      padding: EdgeInsets.all(16.w),
                      itemCount: _groupController.groupMessages.length,
                      itemBuilder: (context, index) {
                        final message = _groupController.groupMessages[index];
                        final isSent =
                            message.senderId == _authController.user.value?.id;

                        return _buildMessageBubble(context, message, isSent);
                      },
                    );
                  }),
                ),
              ),
              // Reply preview
              Obx(() {
                if (_groupController.selectedMessageForReply.value != null) {
                  final replyMsg =
                      _groupController.selectedMessageForReply.value!;
                  return Container(
                    padding: EdgeInsets.all(12.w),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      border: Border(
                        left: BorderSide(
                          color: Colors.white,
                          width: 3.w,
                        ),
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Replying to ${replyMsg.senderId == _authController.user.value?.id ? "yourself" : "someone"}',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 14.sp,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              SizedBox(height: 4.h),
                              Text(
                                replyMsg.text ?? '[Media]',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 13.sp,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.close, color: Colors.white, size: 20.sp),
                          onPressed: _groupController.cancelReply,
                        ),
                      ],
                    ),
                  );
                }
                return const SizedBox.shrink();
              }),
              // Edit mode
              Obx(() {
                if (_groupController.selectedMessageForEdit.value != null) {
                  _editController.text = _groupController.editMessageText.value;
                  return Container(
                    padding: EdgeInsets.all(12.w),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.edit, color: Colors.white, size: 20.sp),
                        SizedBox(width: 8.w),
                        Expanded(
                          child: TextField(
                            controller: _editController,
                            style: const TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              hintText: 'Edit message...',
                              hintStyle: const TextStyle(color: Colors.white70),
                              border: InputBorder.none,
                            ),
                            onChanged: (value) =>
                                _groupController.editMessageText.value = value,
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.check, color: Colors.green, size: 20.sp),
                          onPressed: _groupController.saveEditedMessage,
                        ),
                        IconButton(
                          icon: Icon(Icons.close, color: Colors.red, size: 20.sp),
                          onPressed: _groupController.cancelEdit,
                        ),
                      ],
                    ),
                  );
                }
                return const SizedBox.shrink();
              }),
              // Selected file preview
              Obx(() {
                if (_groupController.selectedFile.value != null) {
                  return Container(
                    padding: EdgeInsets.all(8.w),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          _groupController.selectedFileType.value == 'image'
                              ? Icons.image
                              : Icons.attach_file,
                          size: 20.sp,
                          color: Colors.white,
                        ),
                        SizedBox(width: 8.w),
                        Expanded(
                          child: Text(
                            _groupController.selectedFileName.value,
                            style: TextStyle(fontSize: 14.sp, color: Colors.white),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        IconButton(
                          icon: Icon(
                            Icons.close,
                            size: 20.sp,
                            color: Colors.white,
                          ),
                          onPressed: _groupController.clearSelectedFile,
                        ),
                      ],
                    ),
                  );
                }
                return const SizedBox.shrink();
              }),
              // Message input bar
              Container(
                padding: EdgeInsets.all(16.w),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                ),
                child: Row(
                  children: [
                    IconButton(
                      icon: Icon(
                        Icons.attach_file,
                        size: 24.sp,
                        color: Colors.white,
                      ),
                      onPressed: () => _showAttachmentOptions(context),
                    ),
                    SizedBox(width: 8.w),
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(24.r),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.3),
                            width: 1.5,
                          ),
                        ),
                        child: TextField(
                          controller: _messageController,
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            hintText: 'Type a message...',
                            hintStyle: const TextStyle(color: Colors.white70),
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 16.w,
                              vertical: 12.h,
                            ),
                          ),
                          onChanged: (value) => _groupController.onTextChanged(value),
                        ),
                      ),
                    ),
                    SizedBox(width: 8.w),
                    Obx(
                      () => Container(
                        width: 48.w,
                        height: 48.h,
                        decoration: BoxDecoration(
                          color: (_groupController.messageText.value.trim().isNotEmpty ||
                                  _groupController.selectedFile.value != null)
                              ? Colors.white
                              : Colors.transparent,
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          icon: Icon(
                            (_groupController.messageText.value.trim().isNotEmpty ||
                                    _groupController.selectedFile.value != null)
                                ? Icons.send
                                : Icons.mic,
                            color: (_groupController.messageText.value.trim().isNotEmpty ||
                                    _groupController.selectedFile.value != null)
                                ? const Color(0xFF075E54)
                                : Colors.white70,
                          ),
                          onPressed: (_groupController.messageText.value
                                      .trim()
                                      .isNotEmpty ||
                                  _groupController.selectedFile.value != null)
                              ? () {
                                  _groupController.sendGroupMessage();
                                  _messageController.clear();
                                }
                              : null,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMessageBubble(
      BuildContext context, GroupMessage message, bool isSent) {
    return GestureDetector(
      onLongPress: () => _showMessageOptions(context, message, isSent),
      child: Align(
        alignment: isSent ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          margin: EdgeInsets.only(bottom: 8.h),
          padding: EdgeInsets.all(12.w),
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.75,
          ),
          decoration: BoxDecoration(
            color: isSent
                ? Colors.white.withOpacity(0.2)
                : Colors.white.withOpacity(0.15),
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(16.r),
              topRight: Radius.circular(16.r),
              bottomLeft: isSent ? Radius.circular(16.r) : Radius.zero,
              bottomRight: isSent ? Radius.zero : Radius.circular(16.r),
            ),
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Sender name for group messages (if not sent by current user)
              if (!isSent)
                Text(
                  'User ${message.senderId}',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              if (!isSent) SizedBox(height: 4.h),
              // Reply preview
              if (message.replyTo != null)
                Container(
                  margin: EdgeInsets.only(bottom: 8.h),
                  padding: EdgeInsets.all(8.w),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8.r),
                    border: Border(
                      left: BorderSide(
                        color: Colors.white,
                        width: 3.w,
                      ),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        message.replyTo!.senderId == _authController.user.value?.id
                            ? 'You'
                            : 'User ${message.replyTo!.senderId}',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: 2.h),
                      Text(
                        message.replyTo!.text ?? '[Media]',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 12.sp,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              // Media
              if (message.mediaUrl != null && message.mediaUrl!.isNotEmpty)
                _buildMediaWidget(message, isSent),
              // Message text
              if (message.text != null && message.text!.isNotEmpty)
                Text(
                  message.text!,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16.sp,
                  ),
                ),
              SizedBox(height: 4.h),
              // Reactions
              if (message.reactions.isNotEmpty)
                Wrap(
                  spacing: 4.w,
                  runSpacing: 4.h,
                  children: _buildReactionChips(message),
                ),
              if (message.reactions.isNotEmpty) SizedBox(height: 4.h),
              // Time, edit status, and read receipts
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _formatTimestamp(message.timestamp),
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 12.sp,
                    ),
                  ),
                  if (message.isEdited) ...[
                    SizedBox(width: 4.w),
                    Text(
                      'edited',
                      style: TextStyle(
                        color: Colors.white60,
                        fontSize: 11.sp,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                  if (isSent) ...[
                    SizedBox(width: 4.w),
                    _buildMessageStatus(message),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMediaWidget(GroupMessage message, bool isSent) {
    if (message.mediaType == 'image') {
      return Container(
        margin: EdgeInsets.only(bottom: 8.h),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8.r),
          child: Image.network(
            AppConfig.getMediaUrl(message.mediaUrl),
            height: 200.h,
            width: double.infinity,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                height: 200.h,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Center(
                  child: Icon(
                    Icons.broken_image,
                    size: 50.sp,
                    color: Colors.white70,
                  ),
                ),
              );
            },
          ),
        ),
      );
    } else if (message.mediaType == 'file') {
      return Container(
        margin: EdgeInsets.only(bottom: 8.h),
        padding: EdgeInsets.all(12.w),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(8.r),
          border: Border.all(
            color: Colors.white.withOpacity(0.3),
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Icon(Icons.attach_file, size: 24.sp, color: Colors.white),
            SizedBox(width: 8.w),
            Expanded(
              child: Text(
                message.fileName ?? 'File',
                style: TextStyle(color: Colors.white, fontSize: 14.sp),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      );
    }
    return const SizedBox.shrink();
  }

  List<Widget> _buildReactionChips(GroupMessage message) {
    final Map<String, List<int>> reactionGroups = {};
    for (var reaction in message.reactions) {
      reactionGroups.putIfAbsent(reaction.emoji, () => []).add(reaction.userId);
    }

    return reactionGroups.entries.map((entry) {
      final emoji = entry.key;
      final userIds = entry.value;
      final hasReacted =
          userIds.contains(_authController.user.value?.id);

      return GestureDetector(
        onTap: () => _groupController.toggleReaction(message, emoji),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
          decoration: BoxDecoration(
            color: hasReacted
                ? Colors.white.withOpacity(0.3)
                : Colors.white.withOpacity(0.15),
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(
              color: hasReacted ? Colors.white : Colors.white.withOpacity(0.3),
              width: 1.5,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(emoji, style: TextStyle(fontSize: 14.sp)),
              SizedBox(width: 4.w),
              Text(
                '${userIds.length}',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      );
    }).toList();
  }

  Widget _buildMessageStatus(GroupMessage message) {
    final group = _groupController.currentGroup.value;

    if (group == null) return const SizedBox.shrink();

    // Count how many members have read the message
    final readCount = message.readBy.length;
    final totalMembers = group.members.length - 1; // Exclude sender

    if (readCount >= totalMembers) {
      // All read
      return Icon(Icons.done_all, size: 16.sp, color: Colors.white);
    } else if (readCount > 0) {
      // Some read
      return Icon(Icons.done_all, size: 16.sp, color: Colors.white70);
    } else if (message.deliveredTo.isNotEmpty) {
      // Delivered
      return Icon(Icons.done_all, size: 16.sp, color: Colors.white70);
    } else {
      // Sent
      return Icon(Icons.done, size: 16.sp, color: Colors.white70);
    }
  }

  String _formatTimestamp(String timestamp) {
    if (timestamp.isEmpty) return '';

    try {
      final dateTime = DateTime.parse(timestamp);
      final now = DateTime.now();
      final difference = now.difference(dateTime);

      if (difference.inDays == 0) {
        return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
      } else if (difference.inDays == 1) {
        return 'Yesterday';
      } else {
        return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
      }
    } catch (e) {
      return '';
    }
  }

  void _showMessageOptions(
      BuildContext context, GroupMessage message, bool isSent) {
    final currentUser = _authController.user.value;
    final group = _groupController.currentGroup.value;
    final isAdmin = group?.isAdmin(currentUser?.id ?? -1) ?? false;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return Container(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF075E54), Color(0xFF128C7E)],
            ),
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(16.r),
              topRight: Radius.circular(16.r),
            ),
          ),
          child: SafeArea(
            child: Wrap(
              children: [
                ListTile(
                  leading: const Icon(Icons.reply, color: Colors.white),
                  title: const Text('Reply', style: TextStyle(color: Colors.white)),
                  onTap: () {
                    Navigator.pop(context);
                    _groupController.replyToMessage(message);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.add_reaction, color: Colors.white),
                  title:
                      const Text('React', style: TextStyle(color: Colors.white)),
                  onTap: () {
                    Navigator.pop(context);
                    _showReactionPicker(context, message);
                  },
                ),
                if (isSent) ...[
                  ListTile(
                    leading: const Icon(Icons.edit, color: Colors.white),
                    title: const Text('Edit', style: TextStyle(color: Colors.white)),
                    onTap: () {
                      Navigator.pop(context);
                      _groupController.editMessage(message);
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.delete, color: Colors.red),
                    title:
                        const Text('Delete for me', style: TextStyle(color: Colors.red)),
                    onTap: () {
                      Navigator.pop(context);
                      _groupController.deleteGroupMessage(
                        message,
                        deleteForEveryone: false,
                      );
                    },
                  ),
                ],
                if (isSent || isAdmin)
                  ListTile(
                    leading: const Icon(Icons.delete_forever, color: Colors.red),
                    title: const Text('Delete for everyone',
                        style: TextStyle(color: Colors.red)),
                    onTap: () {
                      Navigator.pop(context);
                      _groupController.deleteGroupMessage(
                        message,
                        deleteForEveryone: true,
                      );
                    },
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showReactionPicker(BuildContext context, GroupMessage message) {
    final reactions = ['👍', '❤️', '😂', '😮', '😢', '🙏', '👏', '🔥'];

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return Container(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF075E54), Color(0xFF128C7E)],
            ),
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(16.r),
              topRight: Radius.circular(16.r),
            ),
          ),
          child: SafeArea(
            child: Container(
              padding: EdgeInsets.all(16.w),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'React to message',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 16.h),
                  Wrap(
                    spacing: 12.w,
                    runSpacing: 12.h,
                    children: reactions.map((emoji) {
                      return GestureDetector(
                        onTap: () {
                          Navigator.pop(context);
                          _groupController.toggleReaction(message, emoji);
                        },
                        child: Container(
                          padding: EdgeInsets.all(12.w),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12.r),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.3),
                              width: 1.5,
                            ),
                          ),
                          child: Text(
                            emoji,
                            style: TextStyle(fontSize: 28.sp),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _showAttachmentOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return Container(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF075E54), Color(0xFF128C7E)],
            ),
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(16.r),
              topRight: Radius.circular(16.r),
            ),
          ),
          child: SafeArea(
            child: Wrap(
              children: [
                ListTile(
                  leading: const Icon(Icons.photo_library, color: Colors.white),
                  title: const Text(
                    'Photo from Gallery',
                    style: TextStyle(color: Colors.white),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _groupController.pickImage(ImageSource.gallery);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.camera_alt, color: Colors.white),
                  title: const Text(
                    'Take Photo',
                    style: TextStyle(color: Colors.white),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _groupController.pickImage(ImageSource.camera);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.attach_file, color: Colors.white),
                  title: const Text(
                    'Attach File',
                    style: TextStyle(color: Colors.white),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _groupController.pickFile();
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
