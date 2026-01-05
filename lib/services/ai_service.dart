// lib/services/ai_service.dart

import 'package:smarttrafficapp/services/traffic_data_service.dart';

class AIService {
  // Instance Data Service
  final TrafficDataService _dataService = TrafficDataService();

  AIService() {
    // Load data CSV saat service dibuat
    _dataService.loadAllData();
  }

  // LOGIKA CHATBOT LOKAL (Tanpa Internet/API)
  Future<String> sendMessage(String message) async {
    // Simulasi berpikir sejenak
    await Future.delayed(const Duration(milliseconds: 800));

    // 1. Normalisasi teks (kecilkan huruf biar mudah dideteksi)
    String text = message.toLowerCase();

    // 2. Deteksi Kata Kunci (Keyword Matching)
    
    // --- TOPIK: HUJAN / CUACA ---
    if (text.contains('hujan') || text.contains('basah') || text.contains('cuaca')) {
      int count = _dataService.getAccidentsByWeather('rain'); // Cari kata 'rain' di CSV
      if (text.contains('aman') || text.contains('bahaya')) {
        return "Berdasarkan data historis kami, tercatat ada $count kecelakaan yang terjadi saat kondisi hujan. Sebaiknya kurangi kecepatan dan berhati-hati saat jalan basah.";
      }
      return "Data mencatat ada $count insiden kecelakaan saat kondisi hujan.";
    }

    // --- TOPIK: TOTAL KECELAKAAN ---
    else if (text.contains('total') && text.contains('kecelakaan')) {
      int total = _dataService.getTotalAccidents();
      return "Total data kecelakaan yang tercatat dalam sistem kami berjumlah $total kasus.";
    }

    // --- TOPIK: FATAL / KEMATIAN ---
    else if (text.contains('fatal') || text.contains('meninggal') || text.contains('parah')) {
      int fatal = _dataService.getFatalAccidents();
      return "Terdapat $fatal kasus kecelakaan yang tergolong fatal (mengakibatkan kematian). Harap patuhi rambu lalu lintas.";
    }

    // --- TOPIK: MACET / TRAFFIC ---
    else if (text.contains('macet') || text.contains('padat') || text.contains('lalu lintas')) {
      String status = _dataService.getTrafficStatus();
      return "Status Lalu Lintas: $status";
    }

    // --- SAPAAN ---
    else if (text.contains('halo') || text.contains('hai') || text.contains('selamat')) {
      return "Halo! Saya SmartTraffic Bot (Offline Mode). Silakan tanya seputar data kecelakaan (misal: 'berapa kecelakaan saat hujan?') atau kondisi lalu lintas.";
    }

    // --- JIKA TIDAK MENGERTI ---
    else {
      return "Maaf, saya adalah bot offline yang hanya bisa menjawab pertanyaan seputar data kecelakaan dan lalu lintas. Coba gunakan kata kunci seperti 'hujan', 'total kecelakaan', atau 'macet'.";
    }
  }

  void resetChat() {
    // Tidak ada sesi yang perlu direset karena ini stateless logic
  }
}