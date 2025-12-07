// Group model for the Flutter app
class Group {
  final String id;
  final String name;
  final String? description;
  final String? groupPhoto;
  final int createdBy;
  final List<int> admins;
  final List<int> members;
  final String createdAt;
  final String updatedAt;
  final bool isPublic;
  final bool allowMembersToAddOthers;
  final List<MutedInfo> mutedBy;
  final LastMessage? lastMessage;

  Group({
    required this.id,
    required this.name,
    this.description,
    this.groupPhoto,
    required this.createdBy,
    required this.admins,
    required this.members,
    required this.createdAt,
    required this.updatedAt,
    this.isPublic = false,
    this.allowMembersToAddOthers = false,
    this.mutedBy = const [],
    this.lastMessage,
  });

  factory Group.fromJson(Map<String, dynamic> json) {
    return Group(
      id: json['_id'],
      name: json['name'],
      description: json['description'],
      groupPhoto: json['groupPhoto'],
      createdBy: json['createdBy'],
      admins: List<int>.from(json['admins'] ?? []),
      members: List<int>.from(json['members'] ?? []),
      createdAt: json['createdAt'],
      updatedAt: json['updatedAt'],
      isPublic: json['isPublic'] ?? false,
      allowMembersToAddOthers: json['allowMembersToAddOthers'] ?? false,
      mutedBy: (json['mutedBy'] as List?)
              ?.map((m) => MutedInfo.fromJson(m))
              .toList() ??
          [],
      lastMessage: json['lastMessage'] != null
          ? LastMessage.fromJson(json['lastMessage'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'name': name,
      'description': description,
      'groupPhoto': groupPhoto,
      'createdBy': createdBy,
      'admins': admins,
      'members': members,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'isPublic': isPublic,
      'allowMembersToAddOthers': allowMembersToAddOthers,
      'mutedBy': mutedBy.map((m) => m.toJson()).toList(),
      'lastMessage': lastMessage?.toJson(),
    };
  }

  Group copyWith({
    String? id,
    String? name,
    String? description,
    String? groupPhoto,
    int? createdBy,
    List<int>? admins,
    List<int>? members,
    String? createdAt,
    String? updatedAt,
    bool? isPublic,
    bool? allowMembersToAddOthers,
    List<MutedInfo>? mutedBy,
    LastMessage? lastMessage,
  }) {
    return Group(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      groupPhoto: groupPhoto ?? this.groupPhoto,
      createdBy: createdBy ?? this.createdBy,
      admins: admins ?? this.admins,
      members: members ?? this.members,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isPublic: isPublic ?? this.isPublic,
      allowMembersToAddOthers:
          allowMembersToAddOthers ?? this.allowMembersToAddOthers,
      mutedBy: mutedBy ?? this.mutedBy,
      lastMessage: lastMessage ?? this.lastMessage,
    );
  }

  // Helper methods
  bool isAdmin(int userId) => admins.contains(userId);
  bool isMember(int userId) => members.contains(userId);
  bool isCreator(int userId) => createdBy == userId;

  bool isMutedBy(int userId) {
    final mute = mutedBy.firstWhere(
      (m) => m.userId == userId,
      orElse: () => MutedInfo(userId: -1, mutedUntil: null),
    );

    if (mute.userId == -1) return false;
    if (mute.mutedUntil == null) return true; // Muted forever

    return DateTime.parse(mute.mutedUntil!).isAfter(DateTime.now());
  }
}

class MutedInfo {
  final int userId;
  final String? mutedUntil; // null = forever

  MutedInfo({
    required this.userId,
    this.mutedUntil,
  });

  factory MutedInfo.fromJson(Map<String, dynamic> json) {
    return MutedInfo(
      userId: json['userId'],
      mutedUntil: json['mutedUntil'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'mutedUntil': mutedUntil,
    };
  }
}

class LastMessage {
  final String? text;
  final int? senderId;
  final String? timestamp;

  LastMessage({
    this.text,
    this.senderId,
    this.timestamp,
  });

  factory LastMessage.fromJson(Map<String, dynamic> json) {
    return LastMessage(
      text: json['text'],
      senderId: json['senderId'],
      timestamp: json['timestamp'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'text': text,
      'senderId': senderId,
      'timestamp': timestamp,
    };
  }
}
