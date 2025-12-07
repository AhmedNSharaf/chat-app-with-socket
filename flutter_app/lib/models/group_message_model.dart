// Group Message model for the Flutter app
class GroupMessage {
  final String id;
  final String groupId;
  final int senderId;
  final String? text;
  final String? mediaUrl;
  final String? mediaType; // 'image', 'video', 'audio', 'file'
  final String? fileName;
  final int? fileSize;
  final String timestamp;
  final bool isEdited;
  final String? editedAt;
  final bool deletedForEveryone;
  final List<int> deletedFor;
  final ReplyTo? replyTo;
  final List<Reaction> reactions;
  final List<ReadReceipt> readBy;
  final List<DeliveryReceipt> deliveredTo;

  GroupMessage({
    required this.id,
    required this.groupId,
    required this.senderId,
    this.text,
    this.mediaUrl,
    this.mediaType,
    this.fileName,
    this.fileSize,
    required this.timestamp,
    this.isEdited = false,
    this.editedAt,
    this.deletedForEveryone = false,
    this.deletedFor = const [],
    this.replyTo,
    this.reactions = const [],
    this.readBy = const [],
    this.deliveredTo = const [],
  });

  factory GroupMessage.fromJson(Map<String, dynamic> json) {
    return GroupMessage(
      id: json['_id'],
      groupId: json['groupId'],
      senderId: json['senderId'],
      text: json['text'],
      mediaUrl: json['mediaUrl'],
      mediaType: json['mediaType'],
      fileName: json['fileName'],
      fileSize: json['fileSize'],
      timestamp: json['timestamp'],
      isEdited: json['isEdited'] ?? false,
      editedAt: json['editedAt'],
      deletedForEveryone: json['deletedForEveryone'] ?? false,
      deletedFor: List<int>.from(json['deletedFor'] ?? []),
      replyTo:
          json['replyTo'] != null ? ReplyTo.fromJson(json['replyTo']) : null,
      reactions: (json['reactions'] as List?)
              ?.map((r) => Reaction.fromJson(r))
              .toList() ??
          [],
      readBy: (json['readBy'] as List?)
              ?.map((r) => ReadReceipt.fromJson(r))
              .toList() ??
          [],
      deliveredTo: (json['deliveredTo'] as List?)
              ?.map((d) => DeliveryReceipt.fromJson(d))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'groupId': groupId,
      'senderId': senderId,
      'text': text,
      'mediaUrl': mediaUrl,
      'mediaType': mediaType,
      'fileName': fileName,
      'fileSize': fileSize,
      'timestamp': timestamp,
      'isEdited': isEdited,
      'editedAt': editedAt,
      'deletedForEveryone': deletedForEveryone,
      'deletedFor': deletedFor,
      'replyTo': replyTo?.toJson(),
      'reactions': reactions.map((r) => r.toJson()).toList(),
      'readBy': readBy.map((r) => r.toJson()).toList(),
      'deliveredTo': deliveredTo.map((d) => d.toJson()).toList(),
    };
  }

  GroupMessage copyWith({
    String? id,
    String? groupId,
    int? senderId,
    String? text,
    String? mediaUrl,
    String? mediaType,
    String? fileName,
    int? fileSize,
    String? timestamp,
    bool? isEdited,
    String? editedAt,
    bool? deletedForEveryone,
    List<int>? deletedFor,
    ReplyTo? replyTo,
    List<Reaction>? reactions,
    List<ReadReceipt>? readBy,
    List<DeliveryReceipt>? deliveredTo,
  }) {
    return GroupMessage(
      id: id ?? this.id,
      groupId: groupId ?? this.groupId,
      senderId: senderId ?? this.senderId,
      text: text ?? this.text,
      mediaUrl: mediaUrl ?? this.mediaUrl,
      mediaType: mediaType ?? this.mediaType,
      fileName: fileName ?? this.fileName,
      fileSize: fileSize ?? this.fileSize,
      timestamp: timestamp ?? this.timestamp,
      isEdited: isEdited ?? this.isEdited,
      editedAt: editedAt ?? this.editedAt,
      deletedForEveryone: deletedForEveryone ?? this.deletedForEveryone,
      deletedFor: deletedFor ?? this.deletedFor,
      replyTo: replyTo ?? this.replyTo,
      reactions: reactions ?? this.reactions,
      readBy: readBy ?? this.readBy,
      deliveredTo: deliveredTo ?? this.deliveredTo,
    );
  }
}

class ReplyTo {
  final String? messageId;
  final int? senderId;
  final String? text;

  ReplyTo({
    this.messageId,
    this.senderId,
    this.text,
  });

  factory ReplyTo.fromJson(Map<String, dynamic> json) {
    return ReplyTo(
      messageId: json['messageId'],
      senderId: json['senderId'],
      text: json['text'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'messageId': messageId,
      'senderId': senderId,
      'text': text,
    };
  }
}

class Reaction {
  final int userId;
  final String emoji;
  final String timestamp;

  Reaction({
    required this.userId,
    required this.emoji,
    required this.timestamp,
  });

  factory Reaction.fromJson(Map<String, dynamic> json) {
    return Reaction(
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

class ReadReceipt {
  final int userId;
  final String readAt;

  ReadReceipt({
    required this.userId,
    required this.readAt,
  });

  factory ReadReceipt.fromJson(Map<String, dynamic> json) {
    return ReadReceipt(
      userId: json['userId'],
      readAt: json['readAt'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'readAt': readAt,
    };
  }
}

class DeliveryReceipt {
  final int userId;
  final String deliveredAt;

  DeliveryReceipt({
    required this.userId,
    required this.deliveredAt,
  });

  factory DeliveryReceipt.fromJson(Map<String, dynamic> json) {
    return DeliveryReceipt(
      userId: json['userId'],
      deliveredAt: json['deliveredAt'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'deliveredAt': deliveredAt,
    };
  }
}
