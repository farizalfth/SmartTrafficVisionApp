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

  factory TrafficData.fromJson(Map<String, dynamic> json) {
    return TrafficData(
      cctvId: json['cctvId'],
      timestamp: DateTime.parse(json['timestamp']),
      vehicleCount: json['vehicleCount'],
      averageSpeed: json['averageSpeed'].toDouble(),
      congestionLevel: json['congestionLevel'].toDouble(),
      vehicleTypeCounts: Map<String, int>.from(json['vehicleTypeCounts']),
    );
  }

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
}