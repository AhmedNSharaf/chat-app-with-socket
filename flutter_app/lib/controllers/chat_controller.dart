import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:record/record.dart';
import 'package:just_audio/just_audio.dart';
import '../models/message_model.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/socket_service.dart';
import '../config/app_config.dart';

class ChatController extends GetxController {
  final AuthService _authService = AuthService();
  late SocketService _socketService;
  final ImagePicker _imagePicker = ImagePicker();
  final AudioRecorder _audioRecorder = AudioRecorder();
  final AudioPlayer _audioPlayer = AudioPlayer();

  var isLoading = false.obs;
  var messages = <Message>[].obs;
  var currentUser = Rxn<User>();
  var chatUser = Rxn<User>();
  var messageText = ''.obs;
  var selectedFile = Rxn<File>();
  var selectedFileName = ''.obs;
  var selectedFileType = ''.obs;
  var scrollController = ScrollController();
  var isRecording = false.obs;
  var recordingDuration = 0.obs;
  var isPlayingAudio = false.obs;
  var isPausedAudio = false.obs;
  var audioPosition = Duration.zero.obs;
  var audioDuration = Duration.zero.obs;
  var isTyping = false.obs;
  var otherUserTyping = false.obs;
  var selectedMessageForReply = Rxn<Message>();
  var selectedMessageForEdit = Rxn<Message>();
  var editMessageText = ''.obs;
  var searchQuery = ''.obs;
  var filteredMessages = <Message>[].obs;
  Timer? _typingTimer;

  void scrollToBottom() {
    // Use multiple attempts with jumpTo for immediate scrolling
    Future.delayed(const Duration(milliseconds: 50), () => _attemptScroll());
    Future.delayed(const Duration(milliseconds: 300), () => _attemptScroll());
    Future.delayed(const Duration(milliseconds: 300), () => _attemptScroll());
  }

  void _attemptScroll() {
    if (scrollController.hasClients) {
      final maxScroll = scrollController.position.maxScrollExtent;
      if (maxScroll > 0) {
        scrollController.jumpTo(maxScroll);
      }
    }
  }

  @override
  void onInit() {
    super.onInit();
    _initializeChat();
  }

  void _initializeChat() async {
    currentUser.value = await _authService.getUser();
    final token = await _authService.getToken();

    if (token != null) {
      _socketService = SocketService();
      _socketService.connect(token);

      // Listen for received messages
      _socketService.onReceiveMessage((message) {
        // Check if message already exists to prevent duplication
        final existingIndex = messages.indexWhere((m) => m.id == message.id);
        if (existingIndex == -1) {
          // Mark as delivered when received
          _socketService.markMessageDelivered(message.id);

          messages.add(message);
          _applySearchFilter();
          Future.delayed(
            const Duration(milliseconds: 100),
            () => scrollToBottom(),
          );
        }
      });

      // Listen for sent messages
      _socketService.onMessageSent((message) {
        // Check if message already exists to prevent duplication
        final existingIndex = messages.indexWhere((m) => m.id == message.id);
        if (existingIndex == -1) {
          messages.add(message);
          _applySearchFilter();
          Future.delayed(
            const Duration(milliseconds: 100),
            () => scrollToBottom(),
          );
        }
      });

      // Listen for message status updates
      _socketService.onMessageStatusUpdate((data) {
        final messageId = data['messageId'] as String;
        final status = data['status'] as String;

        final index = messages.indexWhere((m) => m.id == messageId);
        if (index != -1) {
          messages[index] = messages[index].copyWith(
            status: status,
            deliveredAt: data['deliveredAt'],
            readAt: data['readAt'],
          );
          messages.refresh();
        }
      });

      // Listen for typing indicator
      _socketService.onUserTyping((data) {
        final userId = data['userId'] as int;
        final isTypingNow = data['isTyping'] as bool;

        if (chatUser.value != null && userId == chatUser.value!.id) {
          otherUserTyping.value = isTypingNow;
        }
      });

      // Listen for message edits
      _socketService.onMessageEdited((editedMessage) {
        final index = messages.indexWhere((m) => m.id == editedMessage.id);
        if (index != -1) {
          messages[index] = editedMessage;
          messages.refresh();
          _applySearchFilter();
        }
      });

      // Listen for message deletions
      _socketService.onMessageDeleted((data) {
        final messageId = data['messageId'] as String;
        final deleteForEveryone = data['deleteForEveryone'] as bool;

        if (deleteForEveryone) {
          messages.removeWhere((m) => m.id == messageId);
        } else {
          final index = messages.indexWhere((m) => m.id == messageId);
          if (index != -1 && currentUser.value != null) {
            final updatedDeletedFor = List<int>.from(messages[index].deletedFor);
            if (!updatedDeletedFor.contains(currentUser.value!.id)) {
              updatedDeletedFor.add(currentUser.value!.id);
            }
            messages[index] = messages[index].copyWith(deletedFor: updatedDeletedFor);
            messages.refresh();
          }
        }
        _applySearchFilter();
      });

      // Listen for reactions
      _socketService.onReactionAdded((data) {
        final messageId = data['messageId'] as String;
        final reactions = (data['reactions'] as List)
            .map((r) => MessageReaction.fromJson(r))
            .toList();

        final index = messages.indexWhere((m) => m.id == messageId);
        if (index != -1) {
          messages[index] = messages[index].copyWith(reactions: reactions);
          messages.refresh();
        }
      });

      _socketService.onReactionRemoved((data) {
        final messageId = data['messageId'] as String;
        final reactions = (data['reactions'] as List)
            .map((r) => MessageReaction.fromJson(r))
            .toList();

        final index = messages.indexWhere((m) => m.id == messageId);
        if (index != -1) {
          messages[index] = messages[index].copyWith(reactions: reactions);
          messages.refresh();
        }
      });
    }
  }

  void setChatUser(User user) {
    chatUser.value = user;
    fetchMessages();
  }

  Future<void> fetchMessages() async {
    if (chatUser.value == null) return;

    isLoading.value = true;
    try {
      final token = await _authService.getToken();
      if (token == null) return;

      final response = await http.get(
        Uri.parse(
          '${AppConfig.apiBaseUrl}/messages/${chatUser.value!.id}',
        ),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        messages.value = data.map((json) => Message.fromJson(json)).toList();
        // Scroll to bottom after loading messages with delay
        Future.delayed(
          const Duration(milliseconds: 200),
          () => scrollToBottom(),
        );
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to fetch messages',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> pickImage(ImageSource source) async {
    try {
      final XFile? image = await _imagePicker.pickImage(source: source);
      if (image != null) {
        selectedFile.value = File(image.path);
        selectedFileName.value = image.name;
        selectedFileType.value = 'image';
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to pick image',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  Future<void> pickFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx', 'txt'],
      );

      if (result != null) {
        selectedFile.value = File(result.files.single.path!);
        selectedFileName.value = result.files.single.name;
        selectedFileType.value = 'file';
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to pick file',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  void clearSelectedFile() {
    selectedFile.value = null;
    selectedFileName.value = '';
    selectedFileType.value = '';
  }

  Future<void> startRecording() async {
    try {
      if (await _audioRecorder.hasPermission()) {
        final path =
            '${Directory.systemTemp.path}/audio_${DateTime.now().millisecondsSinceEpoch}.m4a';
        await _audioRecorder.start(const RecordConfig(), path: path);
        isRecording.value = true;
        recordingDuration.value = 0;

        // Start timer to update recording duration
        Timer.periodic(const Duration(seconds: 1), (timer) {
          if (isRecording.value) {
            recordingDuration.value++;
          } else {
            timer.cancel();
          }
        });
      } else {
        Get.snackbar(
          'Permission Denied',
          'Microphone permission is required for recording',
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to start recording',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  Future<void> stopRecording() async {
    try {
      final path = await _audioRecorder.stop();
      isRecording.value = false;

      if (path != null) {
        final audioFile = File(path);
        selectedFile.value = audioFile;
        selectedFileName.value = 'Voice message (${recordingDuration.value}s)';
        selectedFileType.value = 'audio';
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to stop recording',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  Future<void> playAudio(String url) async {
    try {
      if (isPausedAudio.value) {
        // Resume from pause
        await _audioPlayer.play();
        isPlayingAudio.value = true;
        isPausedAudio.value = false;
      } else {
        // Start new playback
        isPlayingAudio.value = true;
        await _audioPlayer.setUrl(AppConfig.getMediaUrl(url));
        await _audioPlayer.play();
      }

      _audioPlayer.playerStateStream.listen((state) {
        if (state.processingState == ProcessingState.completed) {
          isPlayingAudio.value = false;
          isPausedAudio.value = false;
          audioPosition.value = Duration.zero;
        }
      });

      _audioPlayer.positionStream.listen((position) {
        audioPosition.value = position;
      });

      _audioPlayer.durationStream.listen((duration) {
        if (duration != null) {
          audioDuration.value = duration;
        }
      });
    } catch (e) {
      isPlayingAudio.value = false;
      isPausedAudio.value = false;
      Get.snackbar(
        'Error',
        'Failed to play audio',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  Future<void> pauseAudio() async {
    await _audioPlayer.pause();
    isPlayingAudio.value = false;
    isPausedAudio.value = true;
  }

  Future<void> stopAudio() async {
    await _audioPlayer.stop();
    isPlayingAudio.value = false;
    isPausedAudio.value = false;
    audioPosition.value = Duration.zero;
  }

  void seekAudio(Duration position) {
    _audioPlayer.seek(position);
  }

  Future<void> sendMessage() async {
    if (chatUser.value == null) return;

    String text = messageText.value.trim();
    String? mediaUrl;
    String? mediaType;

    // If there's a selected file, upload it first
    if (selectedFile.value != null) {
      mediaUrl = await uploadFile(selectedFile.value!, selectedFileType.value);
      debugPrint(mediaUrl);
      if (mediaUrl != null) {
        mediaType = selectedFileType.value;
        clearSelectedFile();
      } else {
        Get.snackbar(
          'Error',
          'Failed to upload file',
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        return;
      }
    }

    // Send message only if there's text or media
    if (text.isNotEmpty || mediaUrl != null) {
      _socketService.sendMessage(
        chatUser.value!.id,
        text,
        mediaUrl: mediaUrl,
        mediaType: mediaType,
        replyTo: selectedMessageForReply.value?.id,
      );
      messageText.value = '';
      selectedMessageForReply.value = null;

      // Stop typing indicator
      if (isTyping.value) {
        isTyping.value = false;
        _socketService.sendTypingIndicator(chatUser.value!.id, false);
      }
    }
  }

  // Mark messages as read when user views them
  void markMessagesAsRead() {
    if (chatUser.value == null || currentUser.value == null) return;

    for (var message in messages) {
      if (message.receiverId == currentUser.value!.id &&
          message.status != 'read') {
        _socketService.markMessageRead(message.id);
      }
    }
  }

  // Typing indicator
  void onTextChanged(String text) {
    messageText.value = text;

    if (chatUser.value == null) return;

    if (text.isNotEmpty && !isTyping.value) {
      isTyping.value = true;
      _socketService.sendTypingIndicator(chatUser.value!.id, true);
    }

    // Cancel previous timer
    _typingTimer?.cancel();

    // Set new timer to stop typing indicator after 2 seconds of inactivity
    _typingTimer = Timer(const Duration(seconds: 2), () {
      if (isTyping.value) {
        isTyping.value = false;
        _socketService.sendTypingIndicator(chatUser.value!.id, false);
      }
    });
  }

  // Reply to message
  void replyToMessage(Message message) {
    selectedMessageForReply.value = message;
  }

  void cancelReply() {
    selectedMessageForReply.value = null;
  }

  // Edit message
  void editMessage(Message message) {
    if (currentUser.value == null || message.senderId != currentUser.value!.id) {
      Get.snackbar(
        'Error',
        'You can only edit your own messages',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }

    selectedMessageForEdit.value = message;
    editMessageText.value = message.text;
  }

  void cancelEdit() {
    selectedMessageForEdit.value = null;
    editMessageText.value = '';
  }

  Future<void> saveEditedMessage() async {
    if (selectedMessageForEdit.value == null) return;

    final newText = editMessageText.value.trim();
    if (newText.isEmpty) {
      Get.snackbar(
        'Error',
        'Message cannot be empty',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }

    _socketService.editMessage(selectedMessageForEdit.value!.id, newText);
    cancelEdit();
  }

  // Delete message
  void deleteMessage(Message message, {bool deleteForEveryone = false}) {
    if (currentUser.value == null) return;

    if (deleteForEveryone && message.senderId != currentUser.value!.id) {
      Get.snackbar(
        'Error',
        'You can only delete your own messages for everyone',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }

    Get.defaultDialog(
      title: 'Delete Message',
      middleText: deleteForEveryone
          ? 'Delete this message for everyone?'
          : 'Delete this message for you?',
      textConfirm: 'Delete',
      textCancel: 'Cancel',
      confirmTextColor: Colors.white,
      onConfirm: () {
        _socketService.deleteMessage(message.id, deleteForEveryone);
        Get.back();
      },
    );
  }

  // Reactions
  void toggleReaction(Message message, String emoji) {
    if (currentUser.value == null) return;

    // Check if user already reacted with this emoji
    final existingReaction = message.reactions.firstWhereOrNull(
      (r) => r.userId == currentUser.value!.id,
    );

    if (existingReaction != null && existingReaction.emoji == emoji) {
      // Remove reaction
      _socketService.removeReaction(message.id);
    } else {
      // Add/change reaction
      _socketService.addReaction(message.id, emoji);
    }
  }

  // Search messages
  void searchMessages(String query) {
    searchQuery.value = query;
    _applySearchFilter();
  }

  void _applySearchFilter() {
    if (searchQuery.value.isEmpty) {
      filteredMessages.value = messages
          .where((m) => !m.deletedFor.contains(currentUser.value?.id ?? 0))
          .toList();
    } else {
      filteredMessages.value = messages
          .where((m) =>
              !m.deletedFor.contains(currentUser.value?.id ?? 0) &&
              m.text.toLowerCase().contains(searchQuery.value.toLowerCase()))
          .toList();
    }
  }

  void clearSearch() {
    searchQuery.value = '';
    _applySearchFilter();
  }

  // Get display messages (filtered by deletedFor and search)
  List<Message> get displayMessages {
    if (currentUser.value == null) return [];

    var msgs = messages.where((m) {
      // Filter out deleted messages
      if (m.deletedForEveryone) return false;
      if (m.deletedFor.contains(currentUser.value!.id)) return false;
      return true;
    }).toList();

    // Apply search filter
    if (searchQuery.value.isNotEmpty) {
      msgs = msgs
          .where((m) =>
              m.text.toLowerCase().contains(searchQuery.value.toLowerCase()))
          .toList();
    }

    return msgs;
  }

  Future<String?> uploadFile(File file, String type) async {
    try {
      final token = await _authService.getToken();
      if (token == null) return null;

      var request = http.MultipartRequest(
        'POST',
        Uri.parse('${AppConfig.apiBaseUrl}/upload'),
      );

      request.headers['Authorization'] = 'Bearer $token';
      request.files.add(await http.MultipartFile.fromPath('file', file.path));
      debugPrint('Uploading file: ${file.path}');

      var response = await request.send();
      debugPrint('Status code: ${response.statusCode}');

      if (response.statusCode == 200) {
        var responseData = await response.stream.bytesToString();
        var jsonResponse = jsonDecode(responseData);
        return jsonResponse['fileUrl'];
      }
    } catch (e) {
      print('Upload error: $e');
    }
    return null;
  }

  @override
  void onClose() {
    _typingTimer?.cancel();
    _socketService.removeAllListeners();
    _socketService.disconnect();
    _audioPlayer.dispose();
    _audioRecorder.dispose();
    super.onClose();
  }
}
