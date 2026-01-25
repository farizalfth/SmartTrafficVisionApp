import 'package:smarttrafficapp/services/traffic_data_service.dart';

class AIService {
  final TrafficDataService _dataService = TrafficDataService();
  bool _isLoaded = false;

  // Konfigurasi Hugging Face
  final String _hfToken = "<HF_TOKEN>";
  final String _modelUrl = "https://api-inference.huggingface.co/models/google/gemma-1.1-2b-it";

  // Inisialisasi data
  Future<void> init() async {
    if (!_isLoaded) {
      await _dataService.loadAllData();
      _isLoaded = true;
    }
  }

  Future<String> sendMessage(String message) async {
    await init(); // Pastikan data sudah dimuat

    // Simulasi delay sedikit
    await Future.delayed(const Duration(milliseconds: 500));

    String userQuery = message.toLowerCase().trim();

    // 1. Cari kecocokan langsung (Exact Match atau Contains)
    for (var item in _dataService.qaData) {
      if (userQuery.contains(item['question']!) || item['question']!.contains(userQuery)) {
        return item['answer']!;
      }
    }

    // 2. Jika tidak ketemu, cari berdasarkan keyword (Pencarian Kata Kunci)
    List<String> keywords = userQuery.split(' ');
    Map<String, int> scores = {};

    for (var item in _dataService.qaData) {
      int score = 0;
      for (var word in keywords) {
        if (word.length > 3 && item['question']!.contains(word)) {
          score++;
        }
      }
      if (score > 0) {
        scores[item['answer']!] = score;
      }
    }

    if (scores.isNotEmpty) {
      // Ambil jawaban dengan skor tertinggi (paling banyak kata kunci yang cocok)
      var sortedEntries = scores.entries.toList()
        ..sort((e1, e2) => e2.value.compareTo(e1.value));
      return sortedEntries.first.key;
    }

    // 3. Jika benar-benar tidak ada yang cocok
    return "Maaf, saya belum memiliki informasi spesifik mengenai hal tersebut dalam database lalu lintas saya. Bisa coba tanyakan hal lain seperti 'arti lampu merah', 'fungsi helm', atau 'nomor darurat'?";
  }

  void resetChat() {
    // Tidak perlu reset karena data bersifat statis dari CSV
  }
}