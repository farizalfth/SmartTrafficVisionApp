// lib/models/cctv.dart

import 'package:youtube_player_flutter/youtube_player_flutter.dart';

class CCTV {
  final String id;
  final String name;
  final String location;
  final double latitude;
  final double longitude;
  final String status; // e.g., 'Online', 'Offline', 'Macet'
  final String rstpUrl; // Link YouTube / RTSP
  final String? lastUpdate;
  final String? thumbnailUrl;
  final String? description;

  CCTV({
    required this.id,
    required this.name,
    required this.location,
    required this.latitude,
    required this.longitude,
    required this.status,
    required this.rstpUrl,
    this.lastUpdate,
    this.thumbnailUrl,
    this.description,
  });

  // --- HELPER: YouTube ID ---
  String? get youtubeVideoId {
    if (rstpUrl.isEmpty) return null;
    try {
      return YoutubePlayer.convertUrlToId(rstpUrl);
    } catch (e) {
      return null;
    }
  }

  // --- STATE MANAGEMENT: CopyWith ---
  CCTV copyWith({
    String? id,
    String? name,
    String? location,
    double? latitude,
    double? longitude,
    String? status,
    String? rstpUrl,
    String? lastUpdate,
    String? thumbnailUrl,
    String? description,
  }) {
    return CCTV(
      id: id ?? this.id,
      name: name ?? this.name,
      location: location ?? this.location,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      status: status ?? this.status,
      rstpUrl: rstpUrl ?? this.rstpUrl,
      lastUpdate: lastUpdate ?? this.lastUpdate,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      description: description ?? this.description,
    );
  }

  // --- FIREBASE / JSON SERIALIZATION ---

  // Factory untuk membaca data dari Firebase (Map<dynamic, dynamic>)
  factory CCTV.fromMap(Map<dynamic, dynamic> map) {
    return CCTV(
      id: map['id']?.toString() ?? '',
      name: map['name']?.toString() ?? 'CCTV Tanpa Nama',
      location: map['location']?.toString() ?? 'Lokasi Tidak Diketahui',
      
      // Helper aman untuk konversi angka (String/Int -> Double)
      latitude: _parseDouble(map['latitude']),
      longitude: _parseDouble(map['longitude']),
      
      status: map['status']?.toString() ?? 'Offline',
      rstpUrl: map['rstpUrl']?.toString() ?? '',
      
      // Handle penamaan variable yang mungkin beda (snake_case vs camelCase)
      lastUpdate: map['lastUpdate']?.toString() ?? map['last_update']?.toString(),
      thumbnailUrl: map['thumbnailUrl']?.toString() ?? map['thumbnail_url']?.toString(),
      description: map['description']?.toString(),
    );
  }

  // Factory standard JSON (Redirect ke fromMap)
  factory CCTV.fromJson(Map<String, dynamic> json) => CCTV.fromMap(json);

  // Konversi ke JSON untuk dikirim ke Firebase
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'location': location,
      'latitude': latitude,
      'longitude': longitude,
      'status': status,
      'rstpUrl': rstpUrl,
      'lastUpdate': lastUpdate,
      'thumbnailUrl': thumbnailUrl,
      'description': description,
    };
  }

  // --- INTERNAL HELPER: Parsing Angka Aman ---
  // Menangani kasus jika Firebase mengirim angka sebagai String ("-6.2") atau Int (-6)
  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }
}