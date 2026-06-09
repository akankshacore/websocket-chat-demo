import 'dart:async';
import 'package:flutter/material.dart';
import '../models/message_model.dart';
import '../services/websocket_service.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final WebSocketService _wsService = WebSocketService();
  final TextEditingController _messageController = TextEditingController();
  final TextEditingController _urlController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  final List<Message> _messages = [];
  ConnectionStatus _connectionStatus = ConnectionStatus.disconnected;

  StreamSubscription<String>? _messageSub;
  StreamSubscription<ConnectionStatus>? _statusSub;

  // Free public echo WebSocket server — great for demos
  static const String _defaultUrl = 'wss://echo.websocket.org';

  @override
  void initState() {
    super.initState();
    _urlController.text = _defaultUrl;
    _listenToStreams();
  }

  void _listenToStreams() {
    _statusSub = _wsService.status.listen((status) { // calls setState() to rebuild the UI.
      setState(() => _connectionStatus = status);

      String systemMsg = '';
      switch (status) {
        case ConnectionStatus.connecting:
          systemMsg = '🔄 Connecting...';
          break;
        case ConnectionStatus.connected:
          systemMsg = '✅ Connected to ${_urlController.text}';
          break;
        case ConnectionStatus.disconnected:
          systemMsg = '🔌 Disconnected';
          break;
        case ConnectionStatus.error:
          systemMsg = '❌ Connection error';
          break;
      }

      if (systemMsg.isNotEmpty) {
        _addMessage(systemMsg, MessageType.system);
      }
    });

    _messageSub = _wsService.messages.listen((msg) {
      _addMessage(msg, MessageType.received);
    });
  }

  void _addMessage(String text, MessageType type) {
    setState(() {
      _messages.add(Message(text: text, type: type, timestamp: DateTime.now()));
    });
    Future.delayed(const Duration(milliseconds: 100), _scrollToBottom);
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  void _connect() {
    final url = _urlController.text.trim();
    if (url.isEmpty) return;
    _wsService.connect(url);
  }

  void _disconnect() => _wsService.disconnect();

  void _sendMessage() {
    final text = _messageController.text.trim();
    if (text.isEmpty || _connectionStatus != ConnectionStatus.connected) return;
    _wsService.sendMessage(text);
    _addMessage(text, MessageType.sent);
    _messageController.clear();
  }

  @override
  void dispose() {
    _messageSub?.cancel();
    _statusSub?.cancel();
    _wsService.dispose();
    _messageController.dispose();
    _urlController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // ─── UI Helpers ───────────────────────────────────────────────────

  Color get _statusColor {
    switch (_connectionStatus) {
      case ConnectionStatus.connected:
        return const Color(0xFF4CAF50);
      case ConnectionStatus.connecting:
        return const Color(0xFFFFC107);
      case ConnectionStatus.error:
        return const Color(0xFFF44336);
      case ConnectionStatus.disconnected:
        return const Color(0xFF9E9E9E);
    }
  }

  String get _statusLabel {
    switch (_connectionStatus) {
      case ConnectionStatus.connected:
        return 'Connected';
      case ConnectionStatus.connecting:
        return 'Connecting…';
      case ConnectionStatus.error:
        return 'Error';
      case ConnectionStatus.disconnected:
        return 'Disconnected';
    }
  }

  // ─── Build ────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F1117),
      appBar: _buildAppBar(),
      body: Column(
        children: [
          _buildConnectionPanel(),
          const Divider(color: Color(0xFF2A2D3E), height: 1),
          Expanded(child: _buildMessageList()),
          const Divider(color: Color(0xFF2A2D3E), height: 1),
          _buildInputRow(),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: const Color(0xFF161820),
      elevation: 0,
      title: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: _statusColor,
              shape: BoxShape.circle,
              boxShadow: [BoxShadow(color: _statusColor.withOpacity(0.6), blurRadius: 6)],
            ),
          ),
          const SizedBox(width: 10),
          const Text(
            'WebSocket Chat',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 17,
              letterSpacing: 0.4,
            ),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: _statusColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _statusColor.withOpacity(0.4)),
            ),
            child: Text(
              _statusLabel,
              style: TextStyle(
                color: _statusColor,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConnectionPanel() {
    final isConnected = _connectionStatus == ConnectionStatus.connected;
    return Container(
      color: const Color(0xFF161820),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _urlController,
              enabled: !isConnected,
              style: const TextStyle(color: Colors.white, fontSize: 13),
              decoration: InputDecoration(
                hintText: 'wss://your-server.com/ws',
                hintStyle: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 13),
                prefixIcon: Icon(Icons.link, color: Colors.white.withOpacity(0.4), size: 18),
                filled: true,
                fillColor: const Color(0xFF0F1117),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Color(0xFF2A2D3E)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Color(0xFF2A2D3E)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Color(0xFF5C6BC0)),
                ),
                disabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: const Color(0xFF2A2D3E).withOpacity(0.5)),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          ElevatedButton(
            onPressed: isConnected ? _disconnect : _connect,
            style: ElevatedButton.styleFrom(
              backgroundColor: isConnected ? const Color(0xFFF44336) : const Color(0xFF5C6BC0),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              elevation: 0,
            ),
            child: Text(
              isConnected ? 'Disconnect' : 'Connect',
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageList() {
    if (_messages.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.chat_bubble_outline, color: Colors.white.withOpacity(0.15), size: 48),
            const SizedBox(height: 12),
            Text(
              'Connect to a WebSocket server\nand start sending messages',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 14, height: 1.6),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      itemCount: _messages.length,
      itemBuilder: (context, index) => _buildMessageBubble(_messages[index]),
    );
  }

  Widget _buildMessageBubble(Message message) {
    if (message.type == MessageType.system) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              color: const Color(0xFF2A2D3E),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              message.text,
              style: TextStyle(
                color: Colors.white.withOpacity(0.5),
                fontSize: 11.5,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ),
      );
    }

    final isSent = message.type == MessageType.sent;
    final timeStr =
        '${message.timestamp.hour.toString().padLeft(2, '0')}:${message.timestamp.minute.toString().padLeft(2, '0')}';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: isSent ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isSent) ...[
            CircleAvatar(
              radius: 14,
              backgroundColor: const Color(0xFF5C6BC0).withOpacity(0.2),
              child: const Icon(Icons.computer, color: Color(0xFF5C6BC0), size: 14),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment: isSent ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                Text(
                  isSent ? 'You' : 'Server Echo',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.35),
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 3),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: isSent ? const Color(0xFF5C6BC0) : const Color(0xFF1E2130),
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(16),
                      topRight: const Radius.circular(16),
                      bottomLeft: Radius.circular(isSent ? 16 : 4),
                      bottomRight: Radius.circular(isSent ? 4 : 16),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    message.text,
                    style: const TextStyle(color: Colors.white, fontSize: 14, height: 1.4),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  timeStr,
                  style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 10.5),
                ),
              ],
            ),
          ),
          if (isSent) ...[
            const SizedBox(width: 8),
            const CircleAvatar(
              radius: 14,
              backgroundColor: Color(0xFF5C6BC0),
              child: Icon(Icons.person, color: Colors.white, size: 14),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInputRow() {
    final canSend = _connectionStatus == ConnectionStatus.connected;
    return Container(
      color: const Color(0xFF161820),
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 20),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              enabled: canSend,
              style: const TextStyle(color: Colors.white, fontSize: 14),
              onSubmitted: (_) => _sendMessage(),
              decoration: InputDecoration(
                hintText: canSend ? 'Type a message…' : 'Connect first to send messages',
                hintStyle: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 13),
                filled: true,
                fillColor: const Color(0xFF0F1117),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: const BorderSide(color: Color(0xFF2A2D3E)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: const BorderSide(color: Color(0xFF2A2D3E)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: const BorderSide(color: Color(0xFF5C6BC0)),
                ),
                disabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide(color: const Color(0xFF2A2D3E).withOpacity(0.4)),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: canSend ? const Color(0xFF5C6BC0) : const Color(0xFF2A2D3E),
              boxShadow: canSend
                  ? [BoxShadow(color: const Color(0xFF5C6BC0).withOpacity(0.4), blurRadius: 8)]
                  : [],
            ),
            child: IconButton(
              onPressed: canSend ? _sendMessage : null,
              icon: const Icon(Icons.send_rounded),
              color: canSend ? Colors.white : Colors.white24,
            ),
          ),
        ],
      ),
    );
  }
}