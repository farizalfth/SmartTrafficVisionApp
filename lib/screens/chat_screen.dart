import 'package:flutter/material.dart';
import 'package:smarttrafficapp/services/ai_service.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final AIService _aiService = AIService(); 
  final List<ChatMessage> _messages = [];
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    // Inisialisasi dataset CSV
    _aiService.init();
    
    _addMessage(
      const ChatMessage(
        text: "Halo! Saya Asisten Pakar Lalu Lintas. Silakan tanyakan apa saja mengenai aturan jalan raya.",
        isUser: false,
      ),
    );
  }

  void _sendMessage() async {
    final String text = _messageController.text.trim();
    if (text.isEmpty) return;

    _messageController.clear();
    _addMessage(ChatMessage(text: text, isUser: true));

    setState(() {
      _isSending = true;
    });

    try {
      // Mengambil jawaban dari CSV secara Offline
      final String botResponse = await _aiService.sendMessage(text);
      _addMessage(ChatMessage(text: botResponse, isUser: false));
    } catch (e) {
      _addMessage(ChatMessage(text: "Terjadi kesalahan saat mencari data.", isUser: false));
    } finally {
      if (mounted) {
        setState(() {
          _isSending = false;
        });
      }
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
        title: const Text('Smart Traffic AI Assistant'),
        centerTitle: true,
        backgroundColor: const Color(0xFF1A1A1A),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() {
                _messages.clear();
                _addMessage(
                  const ChatMessage(
                    text: "Halo! Saya Asisten Pakar Lalu Lintas. Ada yang bisa saya bantu?",
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
              reverse: true, // Pesan terbaru di bawah
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                return _messages[_messages.length - 1 - index];
              },
            ),
          ),
          if (_isSending)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0),
              child: LinearProgressIndicator(
                color: Colors.blueAccent, 
                backgroundColor: Color(0xFF2C2C2C),
              ),
            ),
          _buildMessageInput(),
        ],
      ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: const BoxDecoration(
        color: Color(0xFF2C2C2C),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Tanya aturan jalan...',
                hintStyle: TextStyle(color: Colors.grey[600]),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30.0),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: const Color(0xFF1A1A1A),
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              ),
              onSubmitted: (_) => _sendMessage(),
            ),
          ),
          const SizedBox(width: 10),
          IconButton(
            onPressed: _isSending ? null : _sendMessage,
            icon: const Icon(Icons.send, color: Colors.blueAccent),
          ),
        ],
      ),
    );
  }
}

class ChatMessage extends StatelessWidget {
  const ChatMessage({super.key, required this.text, required this.isUser});
  final String text;
  final bool isUser;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 5),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isUser ? Colors.blueAccent : const Color(0xFF383838),
          borderRadius: BorderRadius.circular(15),
        ),
        child: Text(text, style: const TextStyle(color: Colors.white)),
      ),
    );
  }
}