import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart'; // Untuk debugPrint

class GeminiService {
  // Ganti dengan API Key Anda dari Google AI Studio!
  // PENTING: Untuk produksi, JANGAN simpan API Key langsung di kode frontend!
  final String _apiKey = 'AIzaSyA-0Xy3I_Ql6TA1G8OxAKOb5M4xB89gK_M'; // <--- PASTIKAN INI SUDAH DIGANTI!

  final String _modelId = 'gemini-pro';
  String get _apiUrl => 'https://generativelanguage.googleapis.com/v1beta/models/$_modelId:generateContent?key=$_apiKey';

  // Riwayat chat untuk menjaga konteks percakapan
  // Setiap elemen adalah Map<String, dynamic> karena 'parts' adalah List
  List<Map<String, dynamic>> _chatHistory = [];

  // System Instruction awal untuk model (ini akan menjadi bagian dari setiap request chat)
  final String _systemInstruction = """
    You are SmartTrafficAI, a helpful assistant for the SmartTrafficVision app. Your primary function is to answer user questions about traffic conditions, CCTV locations, road information in Central Java, and provide basic explanations about the app's features like route planning or congestion warnings. Keep your answers concise and informative. If asked about something outside traffic or the app, politely decline and suggest focusing on traffic-related topics.
    """;

  // Method untuk mengirim pesan ke Gemini API
  Future<String> sendMessage(String message) async {
    // Tambahkan pesan pengguna ke riwayat chat sebelum dikirim
    _chatHistory.add({'role': 'user', 'parts': [{'text': message}]}); // Perbaikan di sini

    // Buat daftar contents untuk request
    // Tambahkan system instruction sebagai item pertama dari 'model'
    // ini adalah cara yang umum digunakan untuk memberikan konteks awal atau persona
    final List<Map<String, dynamic>> contents = [
      {'role': 'model', 'parts': [{'text': _systemInstruction}]},
      ..._chatHistory, // Tambahkan riwayat chat yang sudah ada
    ];

    try {
      final response = await http.post(
        Uri.parse(_apiUrl),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          "contents": contents, // Gunakan list contents yang sudah digabung
          "generationConfig": {
            "temperature": 0.7, // Kontrol kreativitas respons (0.0-1.0)
            "topK": 40,
            "topP": 0.95,
            "maxOutputTokens": 200, // Tingkatkan sedikit maxOutputTokens
          },
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        // Periksa apakah ada 'candidates' dan 'content' sebelum mengaksesnya
        if (data['candidates'] != null && data['candidates'].isNotEmpty &&
            data['candidates'][0]['content'] != null &&
            data['candidates'][0]['content']['parts'] != null &&
            data['candidates'][0]['content']['parts'].isNotEmpty) {
          final String botResponse = data['candidates'][0]['content']['parts'][0]['text'];
          // Tambahkan balasan bot ke riwayat chat
          _chatHistory.add({'role': 'model', 'parts': [{'text': botResponse}]}); // Perbaikan di sini
          return botResponse;
        } else {
          debugPrint('Gemini response missing expected data: $data');
          return 'Maaf, AI tidak memberikan respons yang jelas.';
        }
      } else {
        debugPrint('Error sending message to Gemini: ${response.statusCode} - ${response.body}');
        return 'Maaf, terjadi kesalahan saat menghubungi AI. Kode: ${response.statusCode}. Detail: ${response.body}';
      }
    } catch (e) {
      debugPrint('Exception while sending message to Gemini: $e');
      return 'Maaf, terjadi masalah koneksi atau server: $e';
    }
  }

  // Method untuk mereset riwayat chat
  void resetChat() {
    _chatHistory = []; // Reset riwayat
  }
}