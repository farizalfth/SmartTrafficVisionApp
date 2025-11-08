// lib/models/cctv.dart
class CCTV {
  final String id;
  final String name;
  final String location;
  final String rstpUrl; // Real-Time Streaming Protocol URL
  final String status; // e.g., 'Online', 'Offline'
  final String? description;

  CCTV({
    required this.id,
    required this.name,
    required this.location,
    required this.rstpUrl,
    required this.status,
    this.description,
  });

  // Metode untuk mengonversi dari JSON (jika data diambil dari API)
  factory CCTV.fromJson(Map<String, dynamic> json) {
    return CCTV(
      id: json['id'],
      name: json['name'],
      location: json['location'],
      rstpUrl: json['rstpUrl'],
      status: json['status'],
      description: json['description'],
    );
  }

  // Metode untuk mengonversi ke JSON (jika akan dikirim ke API)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'location': location,
      'rstpUrl': rstpUrl,
      'status': status,
      'description': description,
    };
  }
}