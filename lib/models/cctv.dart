// lib/models/cctv.dart
class CCTV {
  final String id;
  final String name;
  final String location;
  final String rstpUrl; // Real-Time Streaming Protocol URL
  final String status; // e.g., 'Online', 'Offline'
  final String? description;
  final double latitude; // Tambahkan ini
  final double longitude; // Tambahkan ini

  CCTV({
    required this.id,
    required this.name,
    required this.location,
    required this.rstpUrl,
    required this.status,
    this.description,
    required this.latitude, // Tambahkan ini
    required this.longitude, // Tambahkan ini
  });

  factory CCTV.fromJson(Map<String, dynamic> json) {
    return CCTV(
      id: json['id'],
      name: json['name'],
      location: json['location'],
      rstpUrl: json['rstpUrl'],
      status: json['status'],
      description: json['description'],
      latitude: json['latitude'].toDouble(), // Pastikan double
      longitude: json['longitude'].toDouble(), // Pastikan double
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'location': location,
      'rstpUrl': rstpUrl,
      'status': status,
      'description': description,
      'latitude': latitude,
      'longitude': longitude,
    };
  }
}