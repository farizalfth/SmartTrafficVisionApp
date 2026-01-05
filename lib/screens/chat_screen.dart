// FILE: lib/screens/chat_screen.dart

import 'package:flutter/material.dart';
import 'package:smarttrafficapp/services/ai_service.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  
  // Panggil AIService
  final AIService _aiService = AIService(); 
  
  final List<ChatMessage> _messages = [];
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    _addMessage(
      const ChatMessage(
        text: "Halo! Saya Smart Traffic AI, asisten virtual Anda. Ada yang bisa saya bantu terkait lalu lintas atau aplikasi?",
        isUser: false,
      ),
    );
  }

  void _sendMessage() async {
    final String text = _messageController.text.trim();
    _messageController.clear();

    if (text.isEmpty) return;

    _addMessage(ChatMessage(text: text, isUser: true));

    setState(() {
      _isSending = true;
    });

    try {
      final String botResponse = await _aiService.sendMessage(text);
      _addMessage(ChatMessage(text: botResponse, isUser: false));
    } catch (e) {
      _addMessage(ChatMessage(text: "Maaf, terjadi kesalahan: $e", isUser: false));
    } finally {
      setState(() {
        _isSending = false;
      });
    }
  }

  void _addMessage(ChatMessage message) {
    if (mounted) {
      setState(() {
        _messages.add(message);
      });
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      appBar: AppBar(
        title: const Text('Smart Traffic AI'),
        centerTitle: true,
        backgroundColor: const Color(0xFF1A1A1A),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Reset Chat',
            onPressed: () {
              setState(() {
                _messages.clear();
                _aiService.resetChat();
                _addMessage(
                  const ChatMessage(
                    text: "Halo! Saya Smart Traffic AI, asisten virtual Anda. Ada yang bisa saya bantu terkait lalu lintas atau aplikasi?",
                    isUser: false,
                  ),
                );
              });
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16.0),
              reverse: true,
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                return _messages[_messages.length - 1 - index];
              },
            ),
          ),
          if (_isSending)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: LinearProgressIndicator(color: Colors.blueAccent, backgroundColor: Colors.grey),
            ),
          _buildMessageInput(),
        ],
      ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: const Color(0xFF2C2C2C),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Ketik pesan Anda...',
                hintStyle: TextStyle(color: Colors.grey[600]),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30.0),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: const Color(0xFF1A1A1A),
                contentPadding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
              ),
              maxLines: null,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _sendMessage(),
            ),
          ),
          const SizedBox(width: 10.0),
          FloatingActionButton(
            onPressed: _isSending ? null : _sendMessage,
            backgroundColor: Colors.blueAccent,
            elevation: 2,
            child: _isSending
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                  )
                : const Icon(Icons.send, color: Colors.white),
          ),
        ],
      ),
    );
  }
}

class ChatMessage extends StatelessWidget {
  const ChatMessage({
    super.key,
    required this.text,
    required this.isUser,
  });

  final String text;
  final bool isUser;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6.0),
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        decoration: BoxDecoration(
          color: isUser ? Colors.blueAccent : const Color(0xFF383838),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16.0),
            topRight: const Radius.circular(16.0),
            bottomLeft: isUser ? const Radius.circular(16.0) : Radius.zero,
            bottomRight: isUser ? Radius.zero : const Radius.circular(16.0),
          ),
        ),
        child: Text(
          text,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 15,
          ),
        ),
      ),
    );
  }
}