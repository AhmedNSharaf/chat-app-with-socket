import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import '../models/group_model.dart';
import '../models/group_message_model.dart';
import '../services/auth_service.dart';
import '../services/socket_service.dart';
import '../config/app_config.dart';
import 'auth_controller.dart';

class GroupController extends GetxController {
  final AuthService _authService = AuthService();
  final AuthController _authController = Get.find();
  late SocketService _socketService;

  var isLoading = false.obs;
  var groups = <Group>[].obs;
  var currentGroup = Rxn<Group>();
  var groupMessages = <GroupMessage>[].obs;
  var selectedFile = Rxn<PlatformFile>();
  var selectedFileType = ''.obs;
  var selectedFileName = ''.obs;
  var messageText = ''.obs;
  var selectedMessageForReply = Rxn<GroupMessage>();
  var selectedMessageForEdit = Rxn<GroupMessage>();
  var editMessageText = ''.obs;
  var typingUsers = <int, String>{}.obs; // userId -> username
  var isRecording = false.obs;
  var recordingDuration = 0.obs;

  final ScrollController scrollController = ScrollController();

  @override
  void onInit() {
    super.onInit();
    _initializeApp();
  }

  @override
  void onClose() {
    _socketService.removeAllListeners();
    _socketService.disconnect();
    scrollController.dispose();
    super.onClose();
  }

  // Initialize socket first, then fetch groups
  Future<void> _initializeApp() async {
    await _initializeSocket();
    await fetchGroups();
  }

  Future<void> _initializeSocket() async {
    final token = await _authService.getToken();
    if (token != null) {
      _socketService = SocketService();
      _socketService.connect(token);
      _listenToGroupEvents();
      // Small delay to ensure socket is connected
      await Future.delayed(const Duration(milliseconds: 300));
    }
  }

  void _listenToGroupEvents() {
    // Group message received
    _socketService.onGroupMessageReceived((data) {
      final message = GroupMessage.fromJson(data);
      if (currentGroup.value?.id == message.groupId) {
        // Check if message already exists to prevent duplication
        final existingIndex = groupMessages.indexWhere((m) => m.id == message.id);
        if (existingIndex == -1) {
          groupMessages.add(message);
          groupMessages.refresh();
          _scrollToBottom();
          markMessagesAsRead();
        }
      }
      _updateGroupLastMessage(message.groupId, data);
    });

    // Message delivered
    _socketService.onGroupMessageDelivered((data) {
      final messageId = data['messageId'];
      final deliveredTo = List<int>.from(data['deliveredTo'] ?? []);

      final index =
          groupMessages.indexWhere((m) => m.id == messageId);
      if (index != -1) {
        final message = groupMessages[index];
        final updatedDeliveredTo = [
          ...message.deliveredTo,
          ...deliveredTo
              .map((userId) => DeliveryReceipt(
                    userId: userId,
                    deliveredAt: DateTime.now().toIso8601String(),
                  ))
        ];

        groupMessages[index] = message.copyWith(deliveredTo: updatedDeliveredTo);
        groupMessages.refresh();
      }
    });

    // Messages read
    _socketService.onGroupMessagesRead((data) {
      final messageIds = List<String>.from(data['messageIds'] ?? []);
      final userId = data['userId'] as int;
      final readAt = data['readAt'] as String;

      for (var messageId in messageIds) {
        final index = groupMessages.indexWhere((m) => m.id == messageId);
        if (index != -1) {
          final message = groupMessages[index];
          if (!message.readBy.any((r) => r.userId == userId)) {
            final updatedReadBy = [
              ...message.readBy,
              ReadReceipt(userId: userId, readAt: readAt)
            ];
            groupMessages[index] = message.copyWith(readBy: updatedReadBy);
          }
        }
      }
      groupMessages.refresh();
    });

    // Message edited
    _socketService.onGroupMessageEdited((data) {
      final messageId = data['messageId'];
      final newText = data['newText'];
      final isEdited = data['isEdited'] ?? true;
      final editedAt = data['editedAt'];

      final index = groupMessages.indexWhere((m) => m.id == messageId);
      if (index != -1) {
        groupMessages[index] = groupMessages[index].copyWith(
          text: newText,
          isEdited: isEdited,
          editedAt: editedAt,
        );
        groupMessages.refresh();
      }
    });

    // Message deleted
    _socketService.onGroupMessageDeleted((data) {
      final messageId = data['messageId'];
      final deleteForEveryone = data['deleteForEveryone'] ?? false;

      if (deleteForEveryone) {
        groupMessages.removeWhere((m) => m.id == messageId);
      } else {
        final index = groupMessages.indexWhere((m) => m.id == messageId);
        if (index != -1) {
          final currentUserId = _authController.user.value?.id;
          if (currentUserId != null) {
            groupMessages[index] = groupMessages[index].copyWith(
              deletedFor: [...groupMessages[index].deletedFor, currentUserId],
            );
          }
        }
      }
      groupMessages.refresh();
    });

    // Reaction added
    _socketService.onGroupReactionAdded((data) {
      final messageId = data['messageId'];
      final reactions = (data['reactions'] as List)
          .map((r) => Reaction.fromJson(r))
          .toList();

      final index = groupMessages.indexWhere((m) => m.id == messageId);
      if (index != -1) {
        groupMessages[index] = groupMessages[index].copyWith(reactions: reactions);
        groupMessages.refresh();
      }
    });

    // Reaction removed
    _socketService.onGroupReactionRemoved((data) {
      final messageId = data['messageId'];
      final reactions = (data['reactions'] as List)
          .map((r) => Reaction.fromJson(r))
          .toList();

      final index = groupMessages.indexWhere((m) => m.id == messageId);
      if (index != -1) {
        groupMessages[index] = groupMessages[index].copyWith(reactions: reactions);
        groupMessages.refresh();
      }
    });

    // Typing indicator
    _socketService.onGroupUserTyping((data) {
      final groupId = data['groupId'];
      final userId = data['userId'] as int;
      final username = data['username'] as String;

      if (currentGroup.value?.id == groupId) {
        typingUsers[userId] = username;
        typingUsers.refresh();

        // Remove after 3 seconds
        Future.delayed(const Duration(seconds: 3), () {
          typingUsers.remove(userId);
          typingUsers.refresh();
        });
      }
    });

    // Member added
    _socketService.onGroupMemberAdded((data) {
      final groupId = data['groupId'];
      final memberIds = List<int>.from(data['memberIds'] ?? []);

      final index = groups.indexWhere((g) => g.id == groupId);
      if (index != -1) {
        final updatedMembers = [...groups[index].members, ...memberIds];
        groups[index] = groups[index].copyWith(members: updatedMembers);
        groups.refresh();

        if (currentGroup.value?.id == groupId) {
          currentGroup.value = groups[index];
        }
      }
    });

    // Member removed
    _socketService.onGroupMemberRemoved((data) {
      final groupId = data['groupId'];
      final memberId = data['memberId'] as int;

      final index = groups.indexWhere((g) => g.id == groupId);
      if (index != -1) {
        final updatedMembers =
            groups[index].members.where((id) => id != memberId).toList();
        groups[index] = groups[index].copyWith(members: updatedMembers);
        groups.refresh();

        if (currentGroup.value?.id == groupId) {
          currentGroup.value = groups[index];
        }
      }
    });
  }

  void _updateGroupLastMessage(String groupId, Map<String, dynamic> messageData) {
    final index = groups.indexWhere((g) => g.id == groupId);
    if (index != -1) {
      groups[index] = groups[index].copyWith(
        lastMessage: LastMessage(
          text: messageData['text'] ?? (messageData['mediaType'] != null
              ? '[${messageData['mediaType']}]'
              : ''),
          senderId: messageData['senderId'],
          timestamp: messageData['timestamp'],
        ),
      );
      groups.refresh();
    }
  }

  // Fetch all groups
  Future<void> fetchGroups() async {
    isLoading.value = true;
    try {
      final token = await _authService.getToken();
      if (token == null) {
        Get.snackbar('Error', 'Not authenticated');
        return;
      }

      final response = await http.get(
        Uri.parse('${AppConfig.serverUrl}/api/groups/my-groups'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        groups.value = data.map((g) => Group.fromJson(g)).toList();

        // Join all group rooms
        if (groups.isNotEmpty) {
          _socketService.joinGroups(groups.map((g) => g.id).toList());
        }
      } else {
        Get.snackbar('Error', 'Failed to fetch groups');
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to fetch groups: $e');
    } finally {
      isLoading.value = false;
    }
  }

  // Set current group and fetch messages
  Future<void> setCurrentGroup(Group group) async {
    currentGroup.value = group;
    groupMessages.clear();
    await fetchGroupMessages(group.id);
  }

  // Fetch group messages
  Future<void> fetchGroupMessages(String groupId) async {
    isLoading.value = true;
    try {
      final token = await _authService.getToken();
      if (token == null) return;

      final response = await http.get(
        Uri.parse('${AppConfig.serverUrl}/api/groups/$groupId/messages'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        final currentUserId = _authController.user.value?.id;

        groupMessages.value = data
            .map((m) => GroupMessage.fromJson(m))
            .where((m) =>
                !m.deletedForEveryone &&
                (currentUserId == null || !m.deletedFor.contains(currentUserId)))
            .toList();

        _scrollToBottom();
        markMessagesAsRead();
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to fetch messages: $e');
    } finally {
      isLoading.value = false;
    }
  }

  // Send group message
  void sendGroupMessage() {
    if (currentGroup.value == null) return;

    if (messageText.value.trim().isEmpty && selectedFile.value == null) {
      return;
    }

    final message = {
      'groupId': currentGroup.value!.id,
      'text': messageText.value.trim(),
      'mediaUrl': null,
      'mediaType': selectedFileType.value.isEmpty ? null : selectedFileType.value,
      'fileName': selectedFileName.value.isEmpty ? null : selectedFileName.value,
      'fileSize': selectedFile.value?.size,
      'replyTo': selectedMessageForReply.value != null
          ? {
              'messageId': selectedMessageForReply.value!.id,
              'senderId': selectedMessageForReply.value!.senderId,
              'text': selectedMessageForReply.value!.text ?? '',
            }
          : null,
    };

    _socketService.sendGroupMessage(message);

    messageText.value = '';
    clearSelectedFile();
    cancelReply();
  }

  // Text changed
  void onTextChanged(String text) {
    messageText.value = text;

    if (currentGroup.value != null && text.isNotEmpty) {
      _socketService.sendGroupTyping(currentGroup.value!.id);
    }
  }

  // Mark messages as read
  void markMessagesAsRead() {
    if (currentGroup.value == null) return;

    final currentUserId = _authController.user.value?.id;
    if (currentUserId == null) return;

    final unreadMessages = groupMessages
        .where((m) =>
            m.senderId != currentUserId &&
            !m.readBy.any((r) => r.userId == currentUserId))
        .map((m) => m.id)
        .toList();

    if (unreadMessages.isNotEmpty) {
      _socketService.markGroupMessagesAsRead(
        currentGroup.value!.id,
        unreadMessages,
      );
    }
  }

  // Reply to message
  void replyToMessage(GroupMessage message) {
    selectedMessageForReply.value = message;
  }

  void cancelReply() {
    selectedMessageForReply.value = null;
  }

  // Edit message
  void editMessage(GroupMessage message) {
    selectedMessageForEdit.value = message;
    editMessageText.value = message.text ?? '';
  }

  void saveEditedMessage() {
    if (selectedMessageForEdit.value == null) return;

    _socketService.editGroupMessage(
      selectedMessageForEdit.value!.id,
      editMessageText.value,
    );

    cancelEdit();
  }

  void cancelEdit() {
    selectedMessageForEdit.value = null;
    editMessageText.value = '';
  }

  // Delete message
  void deleteGroupMessage(GroupMessage message, {required bool deleteForEveryone}) {
    _socketService.deleteGroupMessage(message.id, deleteForEveryone);
  }

  // Toggle reaction
  void toggleReaction(GroupMessage message, String emoji) {
    final currentUserId = _authController.user.value?.id;
    if (currentUserId == null) return;

    final hasReacted =
        message.reactions.any((r) => r.userId == currentUserId && r.emoji == emoji);

    if (hasReacted) {
      _socketService.removeGroupReaction(message.id);
    } else {
      _socketService.addGroupReaction(message.id, emoji);
    }
  }

  // File selection
  Future<void> pickImage(ImageSource source) async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: source);

    if (image != null) {
      selectedFile.value = PlatformFile(
        name: image.name,
        size: await image.length(),
        path: image.path,
      );
      selectedFileType.value = 'image';
      selectedFileName.value = image.name;
    }
  }

  Future<void> pickFile() async {
    final result = await FilePicker.platform.pickFiles();

    if (result != null && result.files.isNotEmpty) {
      selectedFile.value = result.files.first;
      selectedFileType.value = 'file';
      selectedFileName.value = result.files.first.name;
    }
  }

  void clearSelectedFile() {
    selectedFile.value = null;
    selectedFileType.value = '';
    selectedFileName.value = '';
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (scrollController.hasClients) {
        scrollController.animateTo(
          scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  // Get typing users text
  String get typingUsersText {
    if (typingUsers.isEmpty) return '';

    final names = typingUsers.values.toList();
    if (names.length == 1) {
      return '${names[0]} is typing...';
    } else if (names.length == 2) {
      return '${names[0]} and ${names[1]} are typing...';
    } else {
      return '${names[0]}, ${names[1]} and ${names.length - 2} others are typing...';
    }
  }
}
