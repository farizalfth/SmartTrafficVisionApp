import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:smarttrafficapp/models/cctv.dart';
import 'package:smarttrafficapp/models/traffic_data.dart';
import 'package:smarttrafficapp/models/user.dart';
import 'package:flutter/foundation.dart'; // Untuk debugPrint

// --- Define an abstract base class for ApiService ---
abstract class BaseApiService {
  Future<User?> login(String username, String password);
  Future<List<User>> getUsers();
  Future<List<CCTV>> getCCTVs();
  Future<CCTV> addCCTV(CCTV newCCTV);
  Future<void> updateCCTV(String id, CCTV updatedCCTV);
  Future<void> deleteCCTV(String id);
  Future<List<TrafficData>> getTrafficData(String cctvId, {DateTime? startDate, DateTime? endDate});
}

class ApiService implements BaseApiService {
  final String _baseUrl = 'http://your-backend-api.com/api'; // Ganti dengan URL API backend Anda

  // --- Dummy Data (Untuk pengembangan awal tanpa backend) ---
  final List<CCTV> _dummyCCTVs = [
    CCTV(
      id: 'CCTV001',
      name: 'CCTV Bundaran HI',
      location: 'Bundaran Hotel Indonesia, Jakarta',
      rstpUrl: 'rtsp://dummy.url/cctv001', // URL dummy
      status: 'Online',
      latitude: -6.1944, // Koordinat dummy Jakarta
      longitude: 106.8230,
    ),
    CCTV(
      id: 'CCTV002',
      name: 'CCTV Patung Kuda',
      location: 'Patung Kuda Arjuna Wiwaha, Jakarta',
      rstpUrl: 'rtsp://dummy.url/cctv002',
      status: 'Online',
      latitude: -6.1770,
      longitude: 106.8260,
    ),
    CCTV(
      id: 'CCTV003',
      name: 'CCTV Semanggi',
      location: 'Simpang Susun Semanggi, Jakarta',
      rstpUrl: 'rtsp://dummy.url/cctv003',
      status: 'Offline',
      latitude: -6.2163,
      longitude: 106.8140,
    ),
    CCTV(
      id: 'CCTV004',
      name: 'CCTV Kuningan',
      location: 'Jl. Rasuna Said - Kuningan, Jakarta',
      rstpUrl: 'rtsp://dummy.url/cctv004',
      status: 'Online',
      latitude: -6.2230,
      longitude: 106.8280,
    ),
    CCTV(
      id: 'CCTV005',
      name: 'CCTV Monas',
      location: 'Monumen Nasional, Jakarta',
      rstpUrl: 'rtsp://dummy.url/cctv005',
      status: 'Online',
      latitude: -6.1754,
      longitude: 106.8272,
    ),
  ];

  // --- Auth & User Management ---
  @override // Menambahkan override karena mengimplementasikan BaseApiService
  Future<User?> login(String username, String password) async {
    // Implementasi login
    // Ini adalah dummy, di dunia nyata akan panggil API
    if (username == 'admin@example.com' && password == 'password') {
      return User(id: '1', username: 'admin', email: 'admin@example.com', role: UserRole.admin);
    }
    return null;
  }

  @override // Menambahkan override
  Future<List<User>> getUsers() async {
    // Implementasi getUsers
    return [
      User(id: '1', username: 'admin', email: 'admin@example.com', role: UserRole.admin),
      User(id: '2', username: 'operator', email: 'operator@example.com', role: UserRole.operator),
    ];
  }

  // --- CCTV Management ---
  @override // Menambahkan override
  Future<List<CCTV>> getCCTVs() async {
    // Untuk demo, kita langsung kembalikan dummy data
    await Future.delayed(const Duration(seconds: 1)); // Simulasi delay jaringan
    return _dummyCCTVs;

    // Untuk integrasi API nyata, gunakan kode ini:
    /*
    final response = await http.get(Uri.parse('$_baseUrl/cctvs'));
    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((json) => CCTV.fromJson(json)).toList();
    } else {
      debugPrint('Failed to load CCTV data: ${response.body}');
      throw Exception('Failed to load CCTV data');
    }
    */
  }

  @override // Menambahkan override
  Future<CCTV> addCCTV(CCTV newCCTV) async {
    await Future.delayed(const Duration(milliseconds: 500));
    _dummyCCTVs.add(newCCTV); // Tambahkan ke dummy list
    return newCCTV;
    // ... (kode API nyata) ...
  }

  @override // Menambahkan override
  Future<void> updateCCTV(String id, CCTV updatedCCTV) async {
    await Future.delayed(const Duration(milliseconds: 500));
    final index = _dummyCCTVs.indexWhere((c) => c.id == id);
    if (index != -1) {
      _dummyCCTVs[index] = updatedCCTV; // Update di dummy list
    }
    // ... (kode API nyata) ...
  }

  @override // Menambahkan override
  Future<void> deleteCCTV(String id) async {
    await Future.delayed(const Duration(milliseconds: 500));
    _dummyCCTVs.removeWhere((c) => c.id == id); // Hapus dari dummy list
    // ... (kode API nyata) ...
  }

  // --- Traffic Data ---
  @override // Menambahkan override
  Future<List<TrafficData>> getTrafficData(String cctvId, {DateTime? startDate, DateTime? endDate}) async {
    // Ini juga dummy data
    await Future.delayed(const Duration(seconds: 1));
    return [
      TrafficData(
        cctvId: cctvId,
        timestamp: DateTime.now().subtract(const Duration(hours: 1)),
        vehicleCount: 150,
        averageSpeed: 40.5,
        congestionLevel: 0.6,
        vehicleTypeCounts: {'car': 100, 'motorcycle': 30, 'truck': 20},
      ),
      TrafficData(
        cctvId: cctvId,
        timestamp: DateTime.now(),
        vehicleCount: 180,
        averageSpeed: 35.0,
        congestionLevel: 0.75,
        vehicleTypeCounts: {'car': 120, 'motorcycle': 40, 'truck': 20},
      ),
    ];
    // ... (kode API nyata) ...
  }
}