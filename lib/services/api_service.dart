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
  // Ganti dengan URL API backend Anda jika sudah ada, atau biarkan kosong untuk dummy
  final String _baseUrl = 'http://your-backend-api.com/api'; 

  // --- Dummy Data (Untuk pengembangan awal tanpa backend) ---
  final List<CCTV> _dummyCCTVs = [
    CCTV(
      id: 'CCTVSMG001',
      name: 'CCTV Simpang Lima',
      location: 'Simpang Lima, Semarang',
      // Menggunakan RTSP stream test yang valid untuk CCTVSMG001
      rstpUrl: 'rtsp://wowzaec2demo.streamlock.net/vod/mp4:BigBuckBunny_115k.mp4',
      status: 'Online',
      latitude: -6.9918, // Koordinat Semarang
      longitude: 110.4203,
    ),
    CCTV(
      id: 'CCTVSMG002',
      name: 'CCTV Tugu Muda',
      location: 'Tugu Muda, Semarang',
      rstpUrl: 'rtsp://dummy.url/cctvsmg002', // Ini masih dummy
      status: 'Online',
      latitude: -6.9836,
      longitude: 110.4079,
    ),
    CCTV(
      id: 'CCTVSLO001',
      name: 'CCTV Gladag',
      location: 'Gladag, Surakarta (Solo)',
      rstpUrl: 'rtsp://dummy.url/cctvslo001',
      status: 'Offline', // Offline CCTV tidak akan memuat stream
      latitude: -7.5684, // Koordinat Solo
      longitude: 110.8290,
    ),
    CCTV(
      id: 'CCTVSLO002',
      name: 'CCTV Palur',
      location: 'Palur, Karanganyar (dekat Solo)',
      rstpUrl: 'rtsp://dummy.url/cctvslo002',
      status: 'Online',
      latitude: -7.5750,
      longitude: 110.8870,
    ),
    CCTV(
      id: 'CCTVTGL001',
      name: 'CCTV Alun-alun Tegal',
      location: 'Alun-alun Kota Tegal',
      rstpUrl: 'rtsp://dummy.url/cctvtgl001',
      status: 'Online',
      latitude: -6.8687, // Koordinat Tegal
      longitude: 109.1350,
    ),
    CCTV(
      id: 'CCTVPKL001',
      name: 'CCTV Alun-alun Pekalongan',
      location: 'Alun-alun Kota Pekalongan',
      rstpUrl: 'rtsp://dummy.url/cctvpkl001',
      status: 'Online',
      latitude: -6.8856, // Koordinat Pekalongan
      longitude: 109.6740,
    ),
    CCTV(
      id: 'CCTVKNDL001',
      name: 'CCTV Alun-alun Kendal',
      location: 'Alun-alun Kota Kendal',
      rstpUrl: 'rtsp://dummy.url/cctvkndl001',
      status: 'Offline',
      latitude: -7.0004, // Koordinat Kendal
      longitude: 110.2003,
    ),
  ];

  // --- Auth & User Management ---
  @override
  Future<User?> login(String username, String password) async {
    if (username == 'admin@example.com' && password == 'password') {
      return User(id: '1', username: 'admin', email: 'admin@example.com', role: UserRole.admin);
    }
    return null;
  }

  @override
  Future<List<User>> getUsers() async {
    return [
      User(id: '1', username: 'admin', email: 'admin@example.com', role: UserRole.admin),
      User(id: '2', username: 'operator', email: 'operator@example.com', role: UserRole.operator),
    ];
  }

  // --- CCTV Management ---
  @override
  Future<List<CCTV>> getCCTVs() async {
    await Future.delayed(const Duration(seconds: 1));
    return _dummyCCTVs;
  }

  @override
  Future<CCTV> addCCTV(CCTV newCCTV) async {
    await Future.delayed(const Duration(milliseconds: 500));
    _dummyCCTVs.add(newCCTV);
    return newCCTV;
  }

  @override
  Future<void> updateCCTV(String id, CCTV updatedCCTV) async {
    await Future.delayed(const Duration(milliseconds: 500));
    final index = _dummyCCTVs.indexWhere((c) => c.id == id);
    if (index != -1) {
      _dummyCCTVs[index] = updatedCCTV;
    }
  }

  @override
  Future<void> deleteCCTV(String id) async {
    await Future.delayed(const Duration(milliseconds: 500));
    _dummyCCTVs.removeWhere((c) => c.id == id);
  }

  // --- Traffic Data ---
  @override
  Future<List<TrafficData>> getTrafficData(String cctvId, {DateTime? startDate, DateTime? endDate}) async {
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
  }
}