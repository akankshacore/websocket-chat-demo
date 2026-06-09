import 'dart:async';
import 'package:web_socket_channel/web_socket_channel.dart';

enum ConnectionStatus { disconnected, connecting, connected, error }

class WebSocketService {
  WebSocketChannel? _channel;
  StreamController<String>? _messageController;
  StreamController<ConnectionStatus>? _statusController;

  Stream<String> get messages => _messageController!.stream;
  Stream<ConnectionStatus> get status => _statusController!.stream;

  // main logic is here.... stream controller for messages and connection status
  WebSocketService() {
    _messageController = StreamController<String>.broadcast(); //broadcast() means multiple listeners can subscribe
    _statusController = StreamController<ConnectionStatus>.broadcast();
  }

  /// Connect to a WebSocket server.
  /// Uses wss://echo.websocket.org as a free echo server for demo purposes.
  Future<void> connect(String url) async {
    _statusController!.add(ConnectionStatus.connecting);
    try {
      _channel = WebSocketChannel.connect(Uri.parse(url)); //This opens the actual TCP socket and performs the WebSocket handshake
      _statusController!.add(ConnectionStatus.connected);

      _channel!.stream.listen(
        (message) {
          _messageController!.add(message.toString());
        },
        onError: (error) {
          _statusController!.add(ConnectionStatus.error);
        },
        onDone: () {
          _statusController!.add(ConnectionStatus.disconnected);
        },
      );
    } catch (e) {
      _statusController!.add(ConnectionStatus.error);
    }
  }

  void sendMessage(String message) {
    if (_channel != null) {
      _channel!.sink.add(message);
    }
  }

  void disconnect() {
    _channel?.sink.close();
    _statusController!.add(ConnectionStatus.disconnected);
  }

  void dispose() {
    disconnect();
    _messageController?.close();
    _statusController?.close();
  }
}