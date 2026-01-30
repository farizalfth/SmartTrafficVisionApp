import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:smarttrafficapp/services/traffic_data_service.dart';

class AIService {
  final TrafficDataService _dataService = TrafficDataService();
  bool _isLoaded = false;

  // Konfigurasi Hugging Face
  final String _hfToken = "<HF_TOKEN>";
  final String _modelUrl = "";

  // --- DATASET BASA-BASI LOKAL ---
  final Map<String, String> _smallTalk = {
    "halo": "Halo! Saya asisten cerdas lalu lintas Anda. Ada yang bisa saya bantu hari ini?",
    "hai": "Hai juga! Ada pertanyaan seputar aturan lalu lintas atau rambu jalan?",
    "hello": "Hello! Senang bertemu Anda. Mari bicara tentang keselamatan di jalan raya.",
    "selamat pagi": "Selamat pagi! Pastikan cek kelengkapan berkendara sebelum berangkat ya.",
    "selamat siang": "Selamat siang! Tetap fokus berkendara meski cuaca panas ya.",
    "selamat sore": "Selamat sore! Hati-hati di jalan saat jam pulang kantor yang padat.",
    "selamat malam": "Selamat malam! Pastikan lampu kendaraan Anda berfungsi dengan baik.",
    "terima kasih": "Sama-sama! Selalu utamakan keselamatan daripada kecepatan ya.",
    "makasih": "Sama-sama! Ada lagi yang ingin Anda tanyakan?",
    "apa kabar": "Kabar saya baik sebagai AI! Bagaimana dengan Anda? Semoga sehat dan aman di perjalanan.",
    "siapa kamu": "Saya adalah Smart Traffic Assistant, asisten virtual yang membantu Anda memahami aturan lalu lintas.",
    "bye": "Sampai jumpa! Tetap patuhi rambu lalu lintas dan hati-hati di jalan.",
    "sampai jumpa": "Sampai jumpa kembali! Salam keselamatan jalan raya.",
  };

  Future<void> init() async {
    if (!_isLoaded) {
      await _dataService.loadAllData();
      _isLoaded = true;
    }
  }

  Future<String> sendMessage(String message) async {
    await init();
    String userQuery = message.toLowerCase().trim();

    // --- 1. CEK BASA-BASI (Small Talk) ---
    // Mencari apakah ada kata kunci basa-basi di dalam pesan user
    for (var entry in _smallTalk.entries) {
      if (userQuery.contains(entry.key)) {
        return entry.value;
      }
    }

    // --- 2. CARI DI DATABASE LOKAL (CSV - Data Lalu Lintas) ---
    // Pencarian Exact Match
    for (var item in _dataService.qaData) {
      if (userQuery.contains(item['question']!.toLowerCase()) || 
          item['question']!.toLowerCase().contains(userQuery)) {
        return item['answer']!;
      }
    }

    // Pencarian berdasarkan Skor Kata Kunci
    List<String> keywords = userQuery.split(' ');
    Map<String, int> scores = {};

    for (var item in _dataService.qaData) {
      int score = 0;
      for (var word in keywords) {
        if (word.length > 3 && item['question']!.toLowerCase().contains(word)) {
          score++;
        }
      }
      if (score > 0) {
        scores[item['answer']!] = score;
      }
    }

    if (scores.isNotEmpty) {
      var sortedEntries = scores.entries.toList()
        ..sort((e1, e2) => e2.value.compareTo(e1.value));
      return sortedEntries.first.key;
    }

    // --- 3. FALLBACK KE GEMMA AI ---
    // Jika tidak ada di Basa-basi dan tidak ada di CSV
    return await _askGemmaAI(message);
  }

  Future<String> _askGemmaAI(String prompt) async {
    try {
      final response = await http.post(
        Uri.parse(_modelUrl),
        headers: {
          'Authorization': 'Bearer $_hfToken',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          "inputs": "Berperanlah sebagai asisten cerdas lalu lintas yang ramah. Jawablah pertanyaan berikut dalam Bahasa Indonesia yang singkat: $prompt",
          "parameters": {
            "max_new_tokens": 200,
            "temperature": 0.7,
            "return_full_text": false,
          }
        }),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        if (data.isNotEmpty && data[0]['generated_text'] != null) {
          return data[0]['generated_text'].trim();
        }
      } else if (response.statusCode == 503) {
        return "Saya sedang menyiapkan data cerdas, mohon coba lagi dalam beberapa detik.";
      }
      
      return "Maaf, database saya belum mencakup hal tersebut secara spesifik. Bisa coba tanyakan soal rambu atau aturan jalan?";
    } catch (e) {
      return "Koneksi bermasalah. Pastikan Anda terhubung ke internet.";
    }
  }

  void resetChat() {}
}