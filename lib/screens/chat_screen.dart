import 'package:flutter/material.dart';
import 'package:smarttrafficapp/services/gemini_service.dart'; // Import service Gemini

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final GeminiService _geminiService = GeminiService(); // Inisialisasi service Gemini
  final List<ChatMessage> _messages = []; // List untuk menyimpan pesan di UI
  bool _isSending = false; // Status untuk menunjukkan apakah pesan sedang dikirim

  // Tambahkan pesan pembuka dari AI
  @override
  void initState() {
    super.initState();
    _addMessage(
      ChatMessage(
        text: "Halo! Saya SmartTrafficAI, asisten virtual Anda. Ada yang bisa saya bantu terkait lalu lintas atau aplikasi?",
        isUser: false,
      ),
    );
  }

  void _sendMessage() async {
    final String text = _messageController.text.trim();
    _messageController.clear(); // Hapus teks setelah dikirim

    if (text.isEmpty) return;

    // Tambahkan pesan pengguna ke UI
    _addMessage(ChatMessage(text: text, isUser: true));

    setState(() {
      _isSending = true; // Set status mengirim
    });

    try {
      // Kirim pesan ke Gemini API dan tunggu balasannya
      final String botResponse = await _geminiService.sendMessage(text);

      // Tambahkan balasan bot ke UI
      _addMessage(ChatMessage(text: botResponse, isUser: false));
    } catch (e) {
      // Tangani error jika terjadi
      _addMessage(ChatMessage(text: "Maaf, terjadi kesalahan: $e", isUser: false));
    } finally {
      setState(() {
        _isSending = false; // Reset status mengirim
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
      appBar: AppBar(
        title: const Text('SmartTrafficAI'),
        backgroundColor: Theme.of(context).primaryColor,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Reset Chat',
            onPressed: () {
              setState(() {
                _messages.clear();
                _geminiService.resetChat(); // Reset riwayat di service juga
                _addMessage(
                  ChatMessage(
                    text: "Halo! Saya SmartTrafficAI, asisten virtual Anda. Ada yang bisa saya bantu terkait lalu lintas atau aplikasi?",
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
              padding: const EdgeInsets.all(8.0),
              reverse: true, // Pesan terbaru di bawah
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                // Tampilkan pesan dalam urutan terbalik (terbaru di bawah)
                return _messages[_messages.length - 1 - index];
              },
            ),
          ),
          if (_isSending) // Tampilkan indikator loading saat mengirim pesan
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8.0),
              child: LinearProgressIndicator(),
            ),
          _buildMessageInput(),
        ],
      ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor, // Warna background input
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, -3), // shadow di atas
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              decoration: InputDecoration(
                hintText: 'Ketik pesan Anda...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20.0),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Theme.of(context).scaffoldBackgroundColor, // Warna field input
                contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              ),
              maxLines: null, // Memungkinkan input multi-baris
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _sendMessage(),
            ),
          ),
          const SizedBox(width: 8.0),
          FloatingActionButton(
            onPressed: _isSending ? null : _sendMessage, // Nonaktifkan tombol saat mengirim
            backgroundColor: Theme.of(context).primaryColor,
            elevation: 0,
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

// Widget terpisah untuk menampilkan setiap pesan (mirip bubble WhatsApp)
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
        margin: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
        padding: const EdgeInsets.all(12.0),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        decoration: BoxDecoration(
          color: isUser ? Colors.blue.shade600 : Theme.of(context).cardColor,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(12.0),
            topRight: const Radius.circular(12.0),
            bottomLeft: isUser ? const Radius.circular(12.0) : const Radius.circular(4.0),
            bottomRight: isUser ? const Radius.circular(4.0) : const Radius.circular(12.0),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 2,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Text(
          text,
          style: TextStyle(
            color: isUser ? Colors.white : Theme.of(context).textTheme.bodyLarge?.color,
          ),
        ),
      ),
    );
  }
}