import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/user_model.dart';
import '../services/auth_service.dart';

class UsersController extends GetxController {
  final AuthService _authService = AuthService();

  var isLoading = false.obs;
  var users = <User>[].obs;
  var lastMessages = <int, Map<String, String>>{}
      .obs; // userId -> {'text': message, 'timestamp': time}

  @override
  void onInit() {
    super.onInit();
    fetchUsers();
  }

  Future<void> fetchUsers() async {
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
        return;
      }

      final response = await http.get(
        Uri.parse(
          'http://192.168.1.6:3000/api/auth/users',
        ), // Change to your backend URL
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        users.value = data.map((json) => User.fromJson(json)).toList();

        // Fetch last messages for each user
        await fetchLastMessages();

        // Sort users by last message timestamp (most recent first)
        _sortUsersByLastMessage();
      } else {
        Get.snackbar(
          'Error',
          'Failed to fetch users',
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Network error',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> fetchLastMessages() async {
    try {
      final token = await _authService.getToken();
      if (token == null) return;

      for (final user in users) {
        try {
          final response = await http.get(
            Uri.parse('http://192.168.1.6:3000/api/auth/messages/${user.id}'),
            headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json',
            },
          );

          if (response.statusCode == 200) {
            final List<dynamic> messages = jsonDecode(response.body);
            if (messages.isNotEmpty) {
              final lastMessage = messages.last;
              String messageText = lastMessage['text'] ?? '';
              if (messageText.isEmpty && lastMessage['mediaType'] != null) {
                messageText = _getMediaTypeText(lastMessage['mediaType']);
              }
              String timestamp = lastMessage['timestamp'] ?? '';
              lastMessages[user.id] = {
                'text': messageText,
                'timestamp': timestamp,
              };
            } else {
              lastMessages[user.id] = {
                'text': 'No messages yet',
                'timestamp': '',
              };
            }
          }
        } catch (e) {
          lastMessages[user.id] = {'text': 'No messages yet', 'timestamp': ''};
        }
      }
      lastMessages.refresh();
    } catch (e) {
      // Handle error silently
    }
  }

  String _getMediaTypeText(String mediaType) {
    switch (mediaType) {
      case 'image':
        return '📷 Photo';
      case 'audio':
        return '🎵 Voice message';
      case 'file':
        return '📄 File';
      default:
        return 'Media';
    }
  }

  void _sortUsersByLastMessage() {
    users.sort((a, b) {
      final aMessageData = lastMessages[a.id];
      final bMessageData = lastMessages[b.id];

      // If either user has no messages, put them at the end
      if (aMessageData == null && bMessageData == null) return 0;
      if (aMessageData == null) return 1;
      if (bMessageData == null) return -1;

      final aTimestamp = aMessageData['timestamp'] ?? '';
      final bTimestamp = bMessageData['timestamp'] ?? '';

      // If either timestamp is empty, put them at the end
      if (aTimestamp.isEmpty && bTimestamp.isEmpty) return 0;
      if (aTimestamp.isEmpty) return 1;
      if (bTimestamp.isEmpty) return -1;

      try {
        final aDateTime = DateTime.parse(aTimestamp);
        final bDateTime = DateTime.parse(bTimestamp);
        return bDateTime.compareTo(aDateTime); // Most recent first
      } catch (e) {
        return 0;
      }
    });

    users.refresh();
  }
}
