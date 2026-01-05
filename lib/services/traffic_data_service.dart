// lib/services/traffic_data_service.dart

import 'package:flutter/services.dart' show rootBundle;
import 'package:csv/csv.dart';

class TrafficDataService {
  List<List<dynamic>> _accidentData = [];
  List<List<dynamic>> _trafficData = [];
  bool isLoading = false;

  // Load semua data saat inisialisasi
  Future<void> loadAllData() async {
    isLoading = true;
    await _loadAccidentData();
    await _loadTrafficData();
    isLoading = false;
  }

  Future<void> _loadAccidentData() async {
    try {
      // Pastikan nama file sesuai yang ada di folder assets
      final rawData = await rootBundle.loadString('assets/datasets/RTA Dataset.csv');
      _accidentData = const CsvToListConverter().convert(rawData);
    } catch (e) {
      print("Error load accident CSV: $e");
    }
  }

  Future<void> _loadTrafficData() async {
    try {
      final rawData = await rootBundle.loadString('assets/datasets/traffic.csv');
      _trafficData = const CsvToListConverter().convert(rawData);
    } catch (e) {
      print("Error load traffic CSV: $e");
    }
  }

  // --- FUNGSI PENCARIAN DATA (LOGIKA LOKAL) ---

  // 1. Hitung total kecelakaan
  int getTotalAccidents() {
    // Dikurangi 1 untuk header
    return _accidentData.isNotEmpty ? _accidentData.length - 1 : 0;
  }

  // 2. Cari kecelakaan berdasarkan cuaca (Keyword: Hujan, Cerah, Kabut)
  int getAccidentsByWeather(String keyword) {
    if (_accidentData.isEmpty) return 0;
    int count = 0;
    // Asumsi Kolom ke-10 adalah Weather_Conditions (Sesuaikan dengan CSV Anda)
    int weatherColumnIndex = 10; 

    // Loop data (skip header)
    for (var i = 1; i < _accidentData.length; i++) {
      if (_accidentData[i].length > weatherColumnIndex) {
        String weather = _accidentData[i][weatherColumnIndex].toString().toLowerCase();
        if (weather.contains(keyword.toLowerCase())) {
          count++;
        }
      }
    }
    return count;
  }

  // 3. Cari kecelakaan Fatal
  int getFatalAccidents() {
    if (_accidentData.isEmpty) return 0;
    int count = 0;
    // Asumsi Kolom ke-1 adalah Severity (1 = Fatal)
    int severityIndex = 1; 

    for (var i = 1; i < _accidentData.length; i++) {
      if (_accidentData[i].length > severityIndex) {
        // Cek kode '1' (Fatal)
        if (_accidentData[i][severityIndex].toString() == '1') {
          count++;
        }
      }
    }
    return count;
  }

  // 4. Info Traffic (Simulasi baca CSV Traffic)
  String getTrafficStatus() {
    if (_trafficData.isEmpty) return "Data lalu lintas belum tersedia.";
    // Contoh: Mengambil baris pertama data traffic sebagai sampel
    // Nanti bisa disesuaikan rumus hitungnya
    return "Terpantau padat di jam sibuk pagi (07:00) dan sore (17:00).";
  }
}