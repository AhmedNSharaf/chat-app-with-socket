import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_picker/image_picker.dart';
import '../controllers/chat_controller.dart';
import '../controllers/auth_controller.dart';
import '../models/user_model.dart';
import '../models/message_model.dart';

class ChatScreen extends StatelessWidget {
  ChatScreen({super.key});

  final ChatController _chatController = Get.put(ChatController());
  final AuthController _authController = Get.find();
  final TextEditingController _messageController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final User chatUser = Get.arguments as User;
    _chatController.setChatUser(chatUser);

    return Scaffold(
      backgroundColor: const Color(0xFF0B141A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF202C33),
        elevation: 0,
        title: Row(
          children: [
            CircleAvatar(
              backgroundColor: Colors.grey[600],
              backgroundImage: chatUser.profilePhoto != null
                  ? NetworkImage(
                      'http://192.168.1.6:3000${chatUser.profilePhoto}',
                    )
                  : null,
              child: chatUser.profilePhoto == null
                  ? Text(
                      chatUser.username[0].toUpperCase(),
                      style: TextStyle(color: Colors.white, fontSize: 16.sp),
                    )
                  : null,
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Text(
                chatUser.username,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Get.back(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.videocam, color: Colors.white),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.call, color: Colors.white),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Container(
              decoration: const BoxDecoration(color: Color(0xFF0B141A)),
              child: Obx(() {
                if (_chatController.isLoading.value) {
                  return const Center(
                    child: CircularProgressIndicator(color: Color(0xFF00A884)),
                  );
                }

                return ListView.builder(
                  controller: _chatController.scrollController,
                  padding: EdgeInsets.all(16.w),
                  itemCount: _chatController.messages.length,
                  itemBuilder: (context, index) {
                    final message = _chatController.messages[index];
                    final isSent =
                        message.senderId == _authController.user.value?.id;

                    return Align(
                      alignment: isSent
                          ? Alignment.centerRight
                          : Alignment.centerLeft,
                      child: Container(
                        margin: EdgeInsets.only(bottom: 8.h),
                        padding: EdgeInsets.all(12.w),
                        constraints: BoxConstraints(
                          maxWidth: MediaQuery.of(context).size.width * 0.7,
                        ),
                        decoration: BoxDecoration(
                          color: isSent
                              ? const Color(0xFF005C4B)
                              : const Color(0xFF202C33),
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(16.r),
                            topRight: Radius.circular(16.r),
                            bottomLeft: isSent
                                ? Radius.circular(16.r)
                                : Radius.zero,
                            bottomRight: isSent
                                ? Radius.zero
                                : Radius.circular(16.r),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (message.hasMedia)
                              _buildMediaWidget(message, isSent),
                            if (message.text.isNotEmpty)
                              Text(
                                message.text,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16.sp,
                                ),
                              ),
                            SizedBox(height: 4.h),
                            Text(
                              _formatTimestamp(message.timestamp),
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 12.sp,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              }),
            ),
          ),
          // Selected file preview
          Obx(() {
            if (_chatController.selectedFile.value != null) {
              return Container(
                padding: EdgeInsets.all(8.w),
                color: const Color(0xFF202C33),
                child: Row(
                  children: [
                    Icon(
                      _chatController.selectedFileType.value == 'image'
                          ? Icons.image
                          : Icons.attach_file,
                      size: 20.sp,
                      color: Colors.white70,
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
                        color: Colors.white70,
                      ),
                      onPressed: _chatController.clearSelectedFile,
                    ),
                  ],
                ),
              );
            }
            return const SizedBox.shrink();
          }),
          Container(
            padding: EdgeInsets.all(16.w),
            decoration: const BoxDecoration(color: Color(0xFF202C33)),
            child: Row(
              children: [
                // GestureDetector(
                //   onLongPress: () => _startRecordingLongPress(context),
                //   onLongPressEnd: (details) {
                //     // Stop recording and send when long press ends
                //     _chatController.stopRecording();
                //     _chatController.sendMessage();
                //   },
                //   child: IconButton(
                //     icon: Icon(Icons.mic, size: 24.sp),
                //     onPressed: () => _startRecording(context),
                //   ),
                // ),
                IconButton(
                  icon: Icon(
                    Icons.attach_file,
                    size: 24.sp,
                    color: Color(0xFF8696A0),
                  ),
                  onPressed: () => _showAttachmentOptions(context),
                ),
                SizedBox(width: 8.w),
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Type a message...',
                      hintStyle: TextStyle(color: Colors.white70),
                      filled: true,
                      fillColor: const Color(0xFF2A3942),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24.r),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 16.w,
                        vertical: 12.h,
                      ),
                    ),
                    onChanged: (value) =>
                        _chatController.messageText.value = value,
                  ),
                ),
                SizedBox(width: 8.w),
                Obx(
                  () => Container(
                    width: 48.w,
                    height: 48.h,
                    decoration: BoxDecoration(
                      color:
                          (_chatController.messageText.value
                                  .trim()
                                  .isNotEmpty ||
                              _chatController.selectedFile.value != null)
                          ? const Color(0xFF00A884)
                          : Colors.transparent,
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: Icon(
                        (_chatController.messageText.value.trim().isNotEmpty ||
                                _chatController.selectedFile.value != null)
                            ? Icons.send
                            : Icons.mic,
                        color:
                            (_chatController.messageText.value
                                    .trim()
                                    .isNotEmpty ||
                                _chatController.selectedFile.value != null)
                            ? Colors.white
                            : const Color(0xFF8696A0),
                      ),
                      onPressed:
                          (_chatController.messageText.value
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
          ),
        ],
      ),
    );
  }

  String _formatTimestamp(String timestamp) {
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
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  Widget _buildMediaWidget(Message message, bool isSent) {
    if (message.mediaType == 'image') {
      return Container(
        margin: EdgeInsets.only(bottom: 8.h),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8.r),
          child: Image.network(
            'http://192.168.1.6:3000${message.mediaUrl}',
            height: 200.h,
            width: double.infinity,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                height: 200.h,
                color: const Color(0xFF202C33),
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
          color: isSent ? Colors.white24 : const Color(0xFF2A3942),
          borderRadius: BorderRadius.circular(8.r),
        ),
        child: Row(
          children: [
            Icon(Icons.attach_file, size: 24.sp, color: Colors.white70),
            SizedBox(width: 8.w),
            Expanded(
              child: Text(
                message.mediaUrl!.split('/').last,
                style: TextStyle(color: Colors.white, fontSize: 14.sp),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      );
    } else if (message.mediaType == 'audio') {
      return Container(
        margin: EdgeInsets.only(bottom: 8.h),
        padding: EdgeInsets.all(2.w),
        decoration: BoxDecoration(
          color: isSent ? Colors.white24 : const Color(0xFF2A3942),
          borderRadius: BorderRadius.circular(8.r),
        ),
        child: Column(
          children: [
            Obx(() {
              final position = _chatController.audioPosition.value;
              final duration = _chatController.audioDuration.value;
              return Column(
                children: [
                  Row(
                    children: [
                      Obx(
                        () => IconButton(
                          icon: Icon(
                            _chatController.isPlayingAudio.value
                                ? Icons.pause
                                : Icons.play_arrow,
                            size: 24.sp,
                            color: Colors.white70,
                          ),
                          onPressed: () {
                            if (_chatController.isPlayingAudio.value) {
                              _chatController.pauseAudio();
                            } else {
                              _chatController.playAudio(message.mediaUrl!);
                            }
                          },
                        ),
                      ),
                      Slider(
                        value: position.inSeconds.toDouble(),
                        min: 0.0,
                        max: duration.inSeconds.toDouble() > 0
                            ? duration.inSeconds.toDouble()
                            : 1.0,
                        onChanged: (value) {
                          _chatController.seekAudio(
                            Duration(seconds: value.toInt()),
                          );
                        },
                        activeColor: const Color(0xFF00A884),
                        inactiveColor: Colors.white30,
                      ),
                    ],
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16.w),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _formatDuration(position),
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 12.sp,
                          ),
                        ),
                        Text(
                          _formatDuration(duration),
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 12.sp,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            }),
          ],
        ),
      );
    }
    return const SizedBox.shrink();
  }

  void _showAttachmentOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF202C33),
      builder: (BuildContext context) {
        return SafeArea(
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
          contentPadding: EdgeInsets.zero,
          content: Container(
            height: 200,
            width: 200,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Obx(
                  () => Text(
                    '${_chatController.recordingDuration.value ~/ 60}:${(_chatController.recordingDuration.value % 60).toString().padLeft(2, '0')}',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                ),
                SizedBox(height: 20),
                Icon(Icons.mic, size: 48, color: Colors.red),
                SizedBox(height: 20),
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
                        shape: CircleBorder(),
                        padding: EdgeInsets.all(16),
                      ),
                      child: Icon(Icons.stop, color: Colors.white),
                    ),
                    SizedBox(width: 20),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _chatController.stopRecording();
                        _chatController.sendMessage();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        shape: CircleBorder(),
                        padding: EdgeInsets.all(16),
                      ),
                      child: Icon(Icons.send, color: Colors.white),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _startRecordingLongPress(BuildContext context) {
    _chatController.startRecording();
    // Show a simple overlay instead of full dialog for long press
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return GestureDetector(
          onTap: () {
            Navigator.pop(context);
            _chatController.stopRecording();
            _chatController.sendMessage();
          },
          child: Container(
            color: Colors.black54,
            child: Center(
              child: Container(
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.mic, size: 48, color: Colors.red),
                    SizedBox(height: 10),
                    Obx(
                      () => Text(
                        '${_chatController.recordingDuration.value ~/ 60}:${(_chatController.recordingDuration.value % 60).toString().padLeft(2, '0')}',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    SizedBox(height: 10),
                    Text(
                      'Recording... Tap to send',
                      style: TextStyle(fontSize: 16),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
