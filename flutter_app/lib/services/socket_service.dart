import 'package:socket_io_client/socket_io_client.dart' as IO;
import '../models/message_model.dart';
import '../config/app_config.dart';

class SocketService {
  late IO.Socket socket;
  late String serverUrl;

  SocketService({
    String? serverUrl,
  }) {
    // Use provided serverUrl or get from AppConfig
    this.serverUrl = serverUrl ?? AppConfig.socketUrl;
  }

  void connect(String token) {
    socket = IO.io(serverUrl, <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': false,
      'auth': {'token': token},
    });

    socket.connect();

    socket.onConnect((_) {
      print('Connected to server');
    });

    socket.onDisconnect((_) {
      print('Disconnected from server');
    });

    socket.onConnectError((error) {
      print('Connection error: $error');
    });
  }

  void disconnect() {
    socket.disconnect();
  }

  // Send message with optional reply
  void sendMessage(
    int receiverId,
    String text, {
    String? mediaUrl,
    String? mediaType,
    String? replyTo,
  }) {
    socket.emit('message', {
      'receiverId': receiverId,
      'text': text,
      'mediaUrl': mediaUrl,
      'mediaType': mediaType,
      'replyTo': replyTo,
    });
  }

  // Mark message as delivered
  void markMessageDelivered(String messageId) {
    socket.emit('message_delivered', {'messageId': messageId});
  }

  // Mark message as read
  void markMessageRead(String messageId) {
    socket.emit('message_read', {'messageId': messageId});
  }

  // Send typing indicator
  void sendTypingIndicator(int receiverId, bool isTyping) {
    socket.emit('typing', {'receiverId': receiverId, 'isTyping': isTyping});
  }

  // Edit message
  void editMessage(String messageId, String newText) {
    socket.emit('edit_message', {'messageId': messageId, 'newText': newText});
  }

  // Delete message
  void deleteMessage(String messageId, bool deleteForEveryone) {
    socket.emit('delete_message', {
      'messageId': messageId,
      'deleteForEveryone': deleteForEveryone,
    });
  }

  // Add reaction to message
  void addReaction(String messageId, String emoji) {
    socket.emit('add_reaction', {'messageId': messageId, 'emoji': emoji});
  }

  // Remove reaction from message
  void removeReaction(String messageId) {
    socket.emit('remove_reaction', {'messageId': messageId});
  }

  // Event listeners
  void onReceiveMessage(Function(Message) callback) {
    socket.on('receive_message', (data) {
      final message = Message.fromJson(data);
      callback(message);
    });
  }

  void onMessageSent(Function(Message) callback) {
    socket.on('message_sent', (data) {
      final message = Message.fromJson(data);
      callback(message);
    });
  }

  void onMessageStatusUpdate(Function(Map<String, dynamic>) callback) {
    socket.on('message_status_update', (data) {
      callback(data);
    });
  }

  void onUserTyping(Function(Map<String, dynamic>) callback) {
    socket.on('user_typing', (data) {
      callback(data);
    });
  }

  void onMessageEdited(Function(Message) callback) {
    socket.on('message_edited', (data) {
      final message = Message.fromJson(data);
      callback(message);
    });
  }

  void onMessageDeleted(Function(Map<String, dynamic>) callback) {
    socket.on('message_deleted', (data) {
      callback(data);
    });
  }

  void onReactionAdded(Function(Map<String, dynamic>) callback) {
    socket.on('reaction_added', (data) {
      callback(data);
    });
  }

  void onReactionRemoved(Function(Map<String, dynamic>) callback) {
    socket.on('reaction_removed', (data) {
      callback(data);
    });
  }

  // Remove listeners
  void offReceiveMessage() {
    socket.off('receive_message');
  }

  void offMessageSent() {
    socket.off('message_sent');
  }

  void offMessageStatusUpdate() {
    socket.off('message_status_update');
  }

  void offUserTyping() {
    socket.off('user_typing');
  }

  void offMessageEdited() {
    socket.off('message_edited');
  }

  void offMessageDeleted() {
    socket.off('message_deleted');
  }

  void offReactionAdded() {
    socket.off('reaction_added');
  }

  void offReactionRemoved() {
    socket.off('reaction_removed');
  }

  // User Presence & Status
  void onUserStatusChanged(Function(Map<String, dynamic>) callback) {
    socket.on('user_status_changed', (data) {
      callback(data);
    });
  }

  void changeStatus(String status, {String? customStatus}) {
    socket.emit('change_status', {
      'status': status,
      'customStatus': customStatus,
    });
  }

  void sendActivity() {
    socket.emit('user_active', {});
  }

  void offUserStatusChanged() {
    socket.off('user_status_changed');
  }

  // ============ GROUP CHAT METHODS ============

  // Join group rooms
  void joinGroups(List<String> groupIds) {
    socket.emit('join_groups', {'groupIds': groupIds});
  }

  // Leave group room
  void leaveGroup(String groupId) {
    socket.emit('leave_group', {'groupId': groupId});
  }

  // Send group message
  void sendGroupMessage(Map<String, dynamic> messageData) {
    socket.emit('group_message', messageData);
  }

  // Send group typing indicator
  void sendGroupTyping(String groupId) {
    socket.emit('group_typing', {'groupId': groupId});
  }

  // Mark group messages as read
  void markGroupMessagesAsRead(String groupId, List<String> messageIds) {
    socket.emit('group_message_read', {
      'groupId': groupId,
      'messageIds': messageIds,
    });
  }

  // Edit group message
  void editGroupMessage(String messageId, String newText) {
    socket.emit('edit_group_message', {
      'messageId': messageId,
      'newText': newText,
    });
  }

  // Delete group message
  void deleteGroupMessage(String messageId, bool deleteForEveryone) {
    socket.emit('delete_group_message', {
      'messageId': messageId,
      'deleteForEveryone': deleteForEveryone,
    });
  }

  // Add reaction to group message
  void addGroupReaction(String messageId, String emoji) {
    socket.emit('add_group_reaction', {'messageId': messageId, 'emoji': emoji});
  }

  // Remove reaction from group message
  void removeGroupReaction(String messageId) {
    socket.emit('remove_group_reaction', {'messageId': messageId});
  }

  // Emit member added to group
  void emitMemberAddedToGroup(String groupId, List<int> memberIds) {
    socket.emit('member_added_to_group', {
      'groupId': groupId,
      'memberIds': memberIds,
    });
  }

  // Emit member removed from group
  void emitMemberRemovedFromGroup(String groupId, int memberId) {
    socket.emit('member_removed_from_group', {
      'groupId': groupId,
      'memberId': memberId,
    });
  }

  // ============ GROUP CHAT EVENT LISTENERS ============

  // Listen for group message received
  void onGroupMessageReceived(Function(Map<String, dynamic>) callback) {
    socket.on('group_message_received', (data) {
      callback(data);
    });
  }

  // Listen for group message delivered
  void onGroupMessageDelivered(Function(Map<String, dynamic>) callback) {
    socket.on('group_message_delivered', (data) {
      callback(data);
    });
  }

  // Listen for group messages read
  void onGroupMessagesRead(Function(Map<String, dynamic>) callback) {
    socket.on('group_messages_read', (data) {
      callback(data);
    });
  }

  // Listen for group message edited
  void onGroupMessageEdited(Function(Map<String, dynamic>) callback) {
    socket.on('group_message_edited', (data) {
      callback(data);
    });
  }

  // Listen for group message deleted
  void onGroupMessageDeleted(Function(Map<String, dynamic>) callback) {
    socket.on('group_message_deleted', (data) {
      callback(data);
    });
  }

  // Listen for group reaction added
  void onGroupReactionAdded(Function(Map<String, dynamic>) callback) {
    socket.on('group_reaction_added', (data) {
      callback(data);
    });
  }

  // Listen for group reaction removed
  void onGroupReactionRemoved(Function(Map<String, dynamic>) callback) {
    socket.on('group_reaction_removed', (data) {
      callback(data);
    });
  }

  // Listen for group user typing
  void onGroupUserTyping(Function(Map<String, dynamic>) callback) {
    socket.on('group_user_typing', (data) {
      callback(data);
    });
  }

  // Listen for group member added
  void onGroupMemberAdded(Function(Map<String, dynamic>) callback) {
    socket.on('group_member_added', (data) {
      callback(data);
    });
  }

  // Listen for group member removed
  void onGroupMemberRemoved(Function(Map<String, dynamic>) callback) {
    socket.on('group_member_removed', (data) {
      callback(data);
    });
  }

  // Remove group event listeners
  void offGroupMessageReceived() {
    socket.off('group_message_received');
  }

  void offGroupMessageDelivered() {
    socket.off('group_message_delivered');
  }

  void offGroupMessagesRead() {
    socket.off('group_messages_read');
  }

  void offGroupMessageEdited() {
    socket.off('group_message_edited');
  }

  void offGroupMessageDeleted() {
    socket.off('group_message_deleted');
  }

  void offGroupReactionAdded() {
    socket.off('group_reaction_added');
  }

  void offGroupReactionRemoved() {
    socket.off('group_reaction_removed');
  }

  void offGroupUserTyping() {
    socket.off('group_user_typing');
  }

  void offGroupMemberAdded() {
    socket.off('group_member_added');
  }

  void offGroupMemberRemoved() {
    socket.off('group_member_removed');
  }

  // Calculator events
  void calculate(String expression) {
    socket.emit('calculate', {'expression': expression});
  }

  void onCalculationResult(Function(Map<String, dynamic>) callback) {
    socket.on('calculation_result', (data) {
      callback(data as Map<String, dynamic>);
    });
  }

  void offCalculationResult() {
    socket.off('calculation_result');
  }

  // Remove all listeners at once (for cleanup)
  void removeAllListeners() {
    // Direct messaging listeners
    offReceiveMessage();
    offMessageSent();
    offMessageStatusUpdate();
    offUserTyping();
    offMessageEdited();
    offMessageDeleted();
    offReactionAdded();
    offReactionRemoved();
    offUserStatusChanged();

    // Group messaging listeners
    offGroupMessageReceived();
    offGroupMessageDelivered();
    offGroupMessagesRead();
    offGroupMessageEdited();
    offGroupMessageDeleted();
    offGroupReactionAdded();
    offGroupReactionRemoved();
    offGroupUserTyping();
    offGroupMemberAdded();
    offGroupMemberRemoved();

    // Calculator listeners
    offCalculationResult();
  }
}
