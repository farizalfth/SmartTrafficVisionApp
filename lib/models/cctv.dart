// lib/models/cctv.dart

import 'package:youtube_player_flutter/youtube_player_flutter.dart';

class CCTV {
  final String id;
  final String name;
  final String location;
  final double latitude;
  final double longitude;
  final String status; // e.g., 'Online', 'Offline'
  final String rstpUrl; // Real-Time Streaming Protocol URL
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

  // --- Fitur dari HEAD: Helper untuk YouTube ID ---
  String? get youtubeVideoId {
    if (rstpUrl.startsWith('https://www.youtube.com/') || rstpUrl.startsWith('https://m.youtube.com/')) {
      return YoutubePlayer.convertUrlToId(rstpUrl);
    }
    return null;
  }

  // --- Fitur dari HEAD: CopyWith untuk update state ---
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

  // --- Fitur dari Remote: JSON Serialization untuk API ---
  factory CCTV.fromJson(Map<String, dynamic> json) {
    return CCTV(
      id: json['id'].toString(),
      name: json['name'] ?? '',
      location: json['location'] ?? '',
      // Menangani kemungkinan latitude/longitude dikirim sebagai String atau Number
      latitude: (json['latitude'] is String) 
          ? double.tryParse(json['latitude']) ?? 0.0 
          : (json['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (json['longitude'] is String) 
          ? double.tryParse(json['longitude']) ?? 0.0 
          : (json['longitude'] as num?)?.toDouble() ?? 0.0,
      status: json['status'] ?? 'Offline',
      rstpUrl: json['rstpUrl'] ?? '',
      lastUpdate: json['last_update'] ?? json['lastUpdate'], // Cek snake_case atau camelCase
      thumbnailUrl: json['thumbnail_url'] ?? json['thumbnailUrl'],
      description: json['description'],
    );
  }

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
}