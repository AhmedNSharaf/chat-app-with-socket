// Message model for the Flutter app
class Message {
  final String id;
  final int senderId;
  final int receiverId;
  final String text;
  final String timestamp;
  final String? mediaUrl;
  final String? mediaType;

  Message({
    required this.id,
    required this.senderId,
    required this.receiverId,
    required this.text,
    required this.timestamp,
    this.mediaUrl,
    this.mediaType,
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
    };
  }

  bool get isSent =>
      senderId == receiverId; // This will be set by the controller

  bool get hasMedia => mediaUrl != null && mediaUrl!.isNotEmpty;
}
