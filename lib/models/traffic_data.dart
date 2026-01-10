// lib/models/traffic_data.dart

class TrafficData {
  final String cctvId;
  final DateTime timestamp;
  final int vehicleCount;
  final double averageSpeed; // km/jam
  final double congestionLevel; // 0.0 - 1.0 (0% - 100%)
  final Map<String, int> vehicleTypeCounts; // e.g., {'car': 100, 'truck': 20}

  TrafficData({
    required this.cctvId,
    required this.timestamp,
    required this.vehicleCount,
    required this.averageSpeed,
    required this.congestionLevel,
    required this.vehicleTypeCounts,
  });

  // --- FACTORY KHUSUS FIREBASE (Aman dari null/tipe data salah) ---
  factory TrafficData.fromMap(Map<dynamic, dynamic> map) {
    return TrafficData(
      cctvId: map['cctvId']?.toString() ?? '',
      
      // Parsing Tanggal Aman
      timestamp: DateTime.tryParse(map['timestamp']?.toString() ?? '') ?? DateTime.now(),
      
      // Parsing Angka Aman (String/Double -> Int)
      vehicleCount: _parseInt(map['vehicleCount']),
      
      // Parsing Double Aman (String/Int -> Double)
      averageSpeed: _parseDouble(map['averageSpeed']),
      congestionLevel: _parseDouble(map['congestionLevel']),
      
      // Parsing Map Aman
      vehicleTypeCounts: _parseVehicleMap(map['vehicleTypeCounts']),
    );
  }

  // Factory standard (Redirect ke fromMap)
  factory TrafficData.fromJson(Map<String, dynamic> json) => TrafficData.fromMap(json);

  Map<String, dynamic> toJson() {
    return {
      'cctvId': cctvId,
      'timestamp': timestamp.toIso8601String(),
      'vehicleCount': vehicleCount,
      'averageSpeed': averageSpeed,
      'congestionLevel': congestionLevel,
      'vehicleTypeCounts': vehicleTypeCounts,
    };
  }

  // --- HELPER FUNCTIONS ---

  static int _parseInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  static Map<String, int> _parseVehicleMap(dynamic map) {
    if (map == null || map is! Map) return {};
    try {
      // Konversi Map<dynamic, dynamic> ke Map<String, int>
      final Map<String, int> result = {};
      map.forEach((key, value) {
        result[key.toString()] = _parseInt(value);
      });
      return result;
    } catch (e) {
      return {};
    }
  }
}