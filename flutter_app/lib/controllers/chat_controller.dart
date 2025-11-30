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

      _socketService.onReceiveMessage((message) {
        messages.add(message);
        // Scroll after a short delay to ensure UI updates
        Future.delayed(
          const Duration(milliseconds: 100),
          () => scrollToBottom(),
        );
      });

      _socketService.onMessageSent((message) {
        messages.add(message);
        // Scroll after a short delay to ensure UI updates
        Future.delayed(
          const Duration(milliseconds: 100),
          () => scrollToBottom(),
        );
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
          'http://192.168.1.6:3000/api/auth/messages/${chatUser.value!.id}',
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
        await _audioPlayer.setUrl('http://192.168.1.6:3000$url');
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
      );
      messageText.value = '';
    }
  }

  Future<String?> uploadFile(File file, String type) async {
    try {
      final token = await _authService.getToken();
      if (token == null) return null;

      var request = http.MultipartRequest(
        'POST',
        Uri.parse('http://192.168.1.6:3000/api/auth/upload'),
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
    _socketService.disconnect();
    super.onClose();
  }
}
