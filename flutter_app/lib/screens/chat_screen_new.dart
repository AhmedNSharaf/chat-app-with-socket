import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_picker/image_picker.dart';
import '../controllers/chat_controller.dart';
import '../controllers/auth_controller.dart';
import '../models/user_model.dart';
import '../models/message_model.dart';
import '../widgets/message_bubble.dart';
import '../widgets/message_action_menu.dart';
import '../widgets/typing_indicator.dart';
import '../widgets/reply_preview.dart';
import '../widgets/edit_message_bar.dart';
import '../widgets/online_indicator.dart';
import '../widgets/last_seen_text.dart';
import '../config/app_config.dart';

class ChatScreenNew extends StatefulWidget {
  const ChatScreenNew({super.key});

  @override
  State<ChatScreenNew> createState() => _ChatScreenNewState();
}

class _ChatScreenNewState extends State<ChatScreenNew> {
  final ChatController _chatController = Get.put(ChatController());
  final AuthController _authController = Get.find();
  final TextEditingController _messageController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _editController = TextEditingController();

  bool _isSearchMode = false;

  @override
  void initState() {
    super.initState();
    final User chatUser = Get.arguments as User;
    _chatController.setChatUser(chatUser);

    // Mark messages as read when screen opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _chatController.markMessagesAsRead();
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _searchController.dispose();
    _editController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final User chatUser = Get.arguments as User;

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
              _buildAppBar(chatUser),

              // Search bar
              if (_isSearchMode) _buildSearchBar(),

              // Messages list
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.1),
                  ),
                  child: Obx(() {
                    if (_chatController.isLoading.value) {
                      return const Center(
                        child: CircularProgressIndicator(color: Colors.white),
                      );
                    }

                    final messages = _chatController.displayMessages;

                    return ListView.builder(
                      controller: _chatController.scrollController,
                      padding: EdgeInsets.all(8.w),
                      itemCount: messages.length +
                          (_chatController.otherUserTyping.value ? 1 : 0),
                      itemBuilder: (context, index) {
                        // Show typing indicator at the end
                        if (index == messages.length) {
                          return TypingIndicator(username: chatUser.username);
                        }

                        final message = messages[index];
                        final isSentByMe = message.senderId ==
                            _authController.user.value?.id;

                        return MessageBubble(
                          message: message,
                          isSentByMe: isSentByMe,
                          currentUserId: _authController.user.value?.id,
                          onLongPress: () => _showMessageActions(
                            context,
                            message,
                            isSentByMe,
                          ),
                          onReactionTap: (emoji) {
                            _chatController.toggleReaction(message, emoji);
                          },
                        );
                      },
                    );
                  }),
                ),
              ),

              // Reply preview
              Obx(() {
                if (_chatController.selectedMessageForReply.value != null) {
                  return ReplyPreview(
                    message: _chatController.selectedMessageForReply.value!,
                    onCancel: _chatController.cancelReply,
                  );
                }
                return const SizedBox.shrink();
              }),

              // Edit message bar
              Obx(() {
                if (_chatController.selectedMessageForEdit.value != null) {
                  _editController.text = _chatController.editMessageText.value;
                  return EditMessageBar(
                    message: _chatController.selectedMessageForEdit.value!,
                    textController: _editController,
                    onCancel: _chatController.cancelEdit,
                    onSave: () {
                      _chatController.editMessageText.value =
                          _editController.text;
                      _chatController.saveEditedMessage();
                    },
                  );
                }
                return const SizedBox.shrink();
              }),

              // Selected file preview
              Obx(() {
                if (_chatController.selectedFile.value != null) {
                  return _buildFilePreview();
                }
                return const SizedBox.shrink();
              }),

              // Message input
              _buildMessageInput(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar(User chatUser) {
    return Padding(
      padding: EdgeInsets.all(8.w),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Get.back(),
          ),
          Stack(
            children: [
              CircleAvatar(
                backgroundColor: const Color(0xFF00A884),
                backgroundImage: chatUser.profilePhoto != null
                    ? NetworkImage(
                        AppConfig.getMediaUrl(chatUser.profilePhoto),
                      )
                    : null,
                child: chatUser.profilePhoto == null
                    ? Text(
                        chatUser.username[0].toUpperCase(),
                        style: TextStyle(color: Colors.white, fontSize: 16.sp),
                      )
                    : null,
              ),
              Positioned(
                right: 0,
                bottom: 0,
                child: OnlineIndicator(
                  isOnline: chatUser.isOnline,
                  status: chatUser.status,
                  size: 10,
                ),
              ),
            ],
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  chatUser.username,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Obx(() {
                  if (_chatController.otherUserTyping.value) {
                    return Text(
                      'typing...',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12.sp,
                        fontStyle: FontStyle.italic,
                      ),
                    );
                  }
                  return LastSeenText(
                    isOnline: chatUser.isOnline,
                    status: chatUser.status,
                    lastSeen: chatUser.lastSeen,
                    customStatus: chatUser.customStatus,
                    fontSize: 12,
                  );
                }),
              ],
            ),
          ),
          IconButton(
            icon: Icon(
              _isSearchMode ? Icons.close : Icons.search,
              color: Colors.white,
            ),
            onPressed: () {
              setState(() {
                _isSearchMode = !_isSearchMode;
                if (!_isSearchMode) {
                  _searchController.clear();
                  _chatController.clearSearch();
                }
              });
            },
          ),
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
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'block',
                child: Text(
                  'Block user',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
      ),
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
          controller: _searchController,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'Search messages...',
            hintStyle: const TextStyle(color: Colors.white70),
            prefixIcon: const Icon(Icons.search, color: Colors.white70),
            suffixIcon: _searchController.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear, color: Colors.white70),
                    onPressed: () {
                      _searchController.clear();
                      _chatController.clearSearch();
                    },
                  )
                : null,
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            contentPadding: EdgeInsets.symmetric(vertical: 8.h),
          ),
          onChanged: (value) {
            _chatController.searchMessages(value);
          },
        ),
      ),
    );
  }

  Widget _buildFilePreview() {
    return Container(
      padding: EdgeInsets.all(8.w),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
      ),
      child: Row(
        children: [
          Icon(
            _chatController.selectedFileType.value == 'image'
                ? Icons.image
                : _chatController.selectedFileType.value == 'audio'
                    ? Icons.mic
                    : Icons.attach_file,
            size: 20.sp,
            color: Colors.white,
          ),
          SizedBox(width: 8.w),
          Expanded(
            child: Text(
              _chatController.selectedFileName.value,
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
            onPressed: _chatController.clearSelectedFile,
          ),
        ],
      ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
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
                maxLines: null,
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
                onChanged: (value) {
                  _chatController.onTextChanged(value);
                },
              ),
            ),
          ),
          SizedBox(width: 8.w),
          Obx(
            () => Container(
              width: 48.w,
              height: 48.h,
              decoration: BoxDecoration(
                color: (_chatController.messageText.value.trim().isNotEmpty ||
                        _chatController.selectedFile.value != null)
                    ? Colors.white
                    : Colors.transparent,
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: Icon(
                  (_chatController.messageText.value.trim().isNotEmpty ||
                          _chatController.selectedFile.value != null)
                      ? Icons.send
                      : Icons.mic,
                  color: (_chatController.messageText.value.trim().isNotEmpty ||
                          _chatController.selectedFile.value != null)
                      ? const Color(0xFF075E54)
                      : Colors.white70,
                ),
                onPressed: (_chatController.messageText.value
                            .trim()
                            .isNotEmpty ||
                        _chatController.selectedFile.value != null)
                    ? () {
                        _chatController.sendMessage();
                        _messageController.clear();
                      }
                    : () => _startRecording(context),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showMessageActions(
      BuildContext context, Message message, bool isSentByMe) {
    showMessageActionMenu(
      context: context,
      message: message,
      isSentByMe: isSentByMe,
      onReply: () {
        _chatController.replyToMessage(message);
      },
      onEdit: isSentByMe && message.mediaType == null
          ? () {
              _chatController.editMessage(message);
            }
          : null,
      onDelete: () {
        _chatController.deleteMessage(message, deleteForEveryone: false);
      },
      onDeleteForEveryone: () {
        _chatController.deleteMessage(message, deleteForEveryone: true);
      },
      onReaction: (emoji) {
        _chatController.toggleReaction(message, emoji);
      },
      onForward: () {
        _showForwardDialog(message);
      },
    );
  }

  void _showForwardDialog(Message message) {
    Get.snackbar(
      'Forward',
      'Forward feature coming soon!',
      backgroundColor: Colors.green,
      colorText: Colors.white,
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
                    _chatController.pickImage(ImageSource.gallery);
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
                    _chatController.pickImage(ImageSource.camera);
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
                    _chatController.pickFile();
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.mic, color: Colors.white),
                  title: const Text(
                    'Voice Message',
                    style: TextStyle(color: Colors.white),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _startRecording(context);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _startRecording(BuildContext context) {
    _chatController.startRecording();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
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
            child: SizedBox(
              height: 200.h,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Obx(
                    () => Text(
                      '${_chatController.recordingDuration.value ~/ 60}:${(_chatController.recordingDuration.value % 60).toString().padLeft(2, '0')}',
                      style: TextStyle(
                        fontSize: 32.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  SizedBox(height: 20.h),
                  Icon(Icons.mic, size: 48.sp, color: Colors.red),
                  SizedBox(height: 20.h),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          _chatController.stopRecording();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          shape: const CircleBorder(),
                          padding: EdgeInsets.all(16.w),
                        ),
                        child: Icon(Icons.close, color: Colors.white, size: 24.sp),
                      ),
                      SizedBox(width: 20.w),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          _chatController.stopRecording();
                          _chatController.sendMessage();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          shape: const CircleBorder(),
                          padding: EdgeInsets.all(16.w),
                        ),
                        child: Icon(
                          Icons.send,
                          color: const Color(0xFF075E54),
                          size: 24.sp,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
