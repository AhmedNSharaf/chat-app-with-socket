// Message model for the Flutter app
class MessageReaction {
  final int userId;
  final String emoji;
  final String timestamp;

  MessageReaction({
    required this.userId,
    required this.emoji,
    required this.timestamp,
  });

  factory MessageReaction.fromJson(Map<String, dynamic> json) {
    return MessageReaction(
      userId: json['userId'],
      emoji: json['emoji'],
      timestamp: json['timestamp'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'emoji': emoji,
      'timestamp': timestamp,
    };
  }
}

class Message {
  final String id;
  final int senderId;
  final int receiverId;
  final String text;
  final String timestamp;
  final String? mediaUrl;
  final String? mediaType;
  final String status; // 'sent', 'delivered', 'read'
  final String? deliveredAt;
  final String? readAt;
  final bool isEdited;
  final String? editedAt;
  final List<int> deletedFor;
  final bool deletedForEveryone;
  final String? replyToId;
  final Message? replyToMessage;
  final List<MessageReaction> reactions;

  Message({
    required this.id,
    required this.senderId,
    required this.receiverId,
    required this.text,
    required this.timestamp,
    this.mediaUrl,
    this.mediaType,
    this.status = 'sent',
    this.deliveredAt,
    this.readAt,
    this.isEdited = false,
    this.editedAt,
    this.deletedFor = const [],
    this.deletedForEveryone = false,
    this.replyToId,
    this.replyToMessage,
    this.reactions = const [],
  });

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      id: json['_id'] ?? json['id'],
      senderId: json['senderId'],
      receiverId: json['receiverId'],
      text: json['text'] ?? '',
      timestamp: json['timestamp'],
      mediaUrl: json['mediaUrl'],
      mediaType: json['mediaType'],
      status: json['status'] ?? 'sent',
      deliveredAt: json['deliveredAt'],
      readAt: json['readAt'],
      isEdited: json['isEdited'] ?? false,
      editedAt: json['editedAt'],
      deletedFor: json['deletedFor'] != null
          ? List<int>.from(json['deletedFor'])
          : [],
      deletedForEveryone: json['deletedForEveryone'] ?? false,
      replyToId: json['replyTo'] is String ? json['replyTo'] : json['replyTo']?['_id'],
      replyToMessage: json['replyTo'] is Map ? Message.fromJson(json['replyTo']) : null,
      reactions: json['reactions'] != null
          ? (json['reactions'] as List)
              .map((r) => MessageReaction.fromJson(r))
              .toList()
          : [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'senderId': senderId,
      'receiverId': receiverId,
      'text': text,
      'timestamp': timestamp,
      'mediaUrl': mediaUrl,
      'mediaType': mediaType,
      'status': status,
      'deliveredAt': deliveredAt,
      'readAt': readAt,
      'isEdited': isEdited,
      'editedAt': editedAt,
      'deletedFor': deletedFor,
      'deletedForEveryone': deletedForEveryone,
      'replyTo': replyToId,
      'reactions': reactions.map((r) => r.toJson()).toList(),
    };
  }

  bool get isSent =>
      senderId == receiverId; // This will be set by the controller

  bool get hasMedia => mediaUrl != null && mediaUrl!.isNotEmpty;

  // Create a copy of the message with updated fields
  Message copyWith({
    String? id,
    int? senderId,
    int? receiverId,
    String? text,
    String? timestamp,
    String? mediaUrl,
    String? mediaType,
    String? status,
    String? deliveredAt,
    String? readAt,
    bool? isEdited,
    String? editedAt,
    List<int>? deletedFor,
    bool? deletedForEveryone,
    String? replyToId,
    Message? replyToMessage,
    List<MessageReaction>? reactions,
  }) {
    return Message(
      id: id ?? this.id,
      senderId: senderId ?? this.senderId,
      receiverId: receiverId ?? this.receiverId,
      text: text ?? this.text,
      timestamp: timestamp ?? this.timestamp,
      mediaUrl: mediaUrl ?? this.mediaUrl,
      mediaType: mediaType ?? this.mediaType,
      status: status ?? this.status,
      deliveredAt: deliveredAt ?? this.deliveredAt,
      readAt: readAt ?? this.readAt,
      isEdited: isEdited ?? this.isEdited,
      editedAt: editedAt ?? this.editedAt,
      deletedFor: deletedFor ?? this.deletedFor,
      deletedForEveryone: deletedForEveryone ?? this.deletedForEveryone,
      replyToId: replyToId ?? this.replyToId,
      replyToMessage: replyToMessage ?? this.replyToMessage,
      reactions: reactions ?? this.reactions,
    );
  }
}
