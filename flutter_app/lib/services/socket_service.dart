import 'package:socket_io_client/socket_io_client.dart' as IO;
import '../models/message_model.dart';

class SocketService {
  late IO.Socket socket;
  final String serverUrl;

  SocketService({
    this.serverUrl =
        'http://192.168.1.6:3000', // Your computer's IP address for physical device
  });

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

  void sendMessage(
    int receiverId,
    String text, {
    String? mediaUrl,
    String? mediaType,
  }) {
    socket.emit('message', {
      'receiverId': receiverId,
      'text': text,
      'mediaUrl': mediaUrl,
      'mediaType': mediaType,
    });
  }

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

  void offReceiveMessage() {
    socket.off('receive_message');
  }

  void offMessageSent() {
    socket.off('message_sent');
  }
}
