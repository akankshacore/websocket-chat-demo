enum MessageType { sent, received, system }

class Message {
  final String text;
  final MessageType type;
  final DateTime timestamp;

  Message({
    required this.text,
    required this.type,
    required this.timestamp,
  });
}