import 'package:csv/csv.dart';
import 'package:flutter/services.dart';

class TrafficDataService {
  List<Map<String, String>> _qaData = [];

  // Fungsi untuk memuat file CSV dari Assets
  Future<void> loadAllData() async {
    try {
      final String rawData = await rootBundle.loadString("assets/datasets/dataset_lalu_lintas.csv");
      
      // Mengonversi CSV menjadi List of Lists
      List<List<dynamic>> listData = const CsvToListConverter(
        fieldDelimiter: ',',
        eol: '\n',
        shouldParseNumbers: false,
      ).convert(rawData);

      // Mengubah List of Lists menjadi List of Maps (Question -> Answer)
      // Indeks 0: instruction, 1: input, 2: output
      _qaData = listData.skip(1).map((row) {
        return {
          'question': row[0].toString().toLowerCase().trim(),
          'answer': row[2].toString().trim(),
        };
      }).toList();

      print("Berhasil memuat ${_qaData.length} data lalu lintas.");
    } catch (e) {
      print("Gagal memuat CSV: $e");
    }
  }

  List<Map<String, String>> get qaData => _qaData;
}