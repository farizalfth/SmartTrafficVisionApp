import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:smarttrafficapp/models/cctv.dart';
import 'package:smarttrafficapp/models/traffic_data.dart';
import 'package:smarttrafficapp/models/user.dart';

class ApiService {
  final String _baseUrl = 'http://your-backend-api.com/api'; // Ganti dengan URL API backend Anda

  // --- Auth & User Management ---
  Future<User?> login(String username, String password) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'username': username, 'password': password}),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      // Simpan token untuk permintaan selanjutnya
      // _authToken = data['token'];
      return User.fromJson(data['user']);
    } else {
      // Lebih baik gunakan logging framework di production
      // debugPrint('Login failed: ${response.body}');
      print('Login failed: ${response.body}');
      return null;
    }
  }

  Future<List<User>> getUsers() async {
    final response = await http.get(Uri.parse('$_baseUrl/users'));

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((json) => User.fromJson(json)).toList();
    } else {
      print('Failed to load users: ${response.body}');
      throw Exception('Failed to load users');
    }
  }

  // --- CCTV Management ---
  Future<List<CCTV>> getCCTVs() async {
    final response = await http.get(Uri.parse('$_baseUrl/cctvs'));

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((json) => CCTV.fromJson(json)).toList();
    } else {
      print('Failed to load CCTV data: ${response.body}');
      throw Exception('Failed to load CCTV data');
    }
  }

  Future<CCTV> addCCTV(CCTV newCCTV) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/cctvs'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(newCCTV.toJson()),
    );

    if (response.statusCode == 201) {
      return CCTV.fromJson(json.decode(response.body));
    } else {
      print('Failed to add CCTV: ${response.body}');
      throw Exception('Failed to add CCTV');
    }
  }

  Future<void> updateCCTV(String id, CCTV updatedCCTV) async {
    final response = await http.put(
      Uri.parse('$_baseUrl/cctvs/$id'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(updatedCCTV.toJson()),
    );

    if (response.statusCode != 200) {
      print('Failed to update CCTV: ${response.body}');
      throw Exception('Failed to update CCTV');
    }
  }

  Future<void> deleteCCTV(String id) async {
    final response = await http.delete(Uri.parse('$_baseUrl/cctvs/$id'));

    if (response.statusCode != 204) { // 204 No Content for successful deletion
      print('Failed to delete CCTV: ${response.body}');
      throw Exception('Failed to delete CCTV');
    }
  }

  // --- Traffic Data ---
  Future<List<TrafficData>> getTrafficData(String cctvId, {DateTime? startDate, DateTime? endDate}) async {
    String query = '';
    if (startDate != null) query += 'startDate=${startDate.toIso8601String()}&';
    if (endDate != null) query += 'endDate=${endDate.toIso8601String()}&';

    final response = await http.get(Uri.parse('$_baseUrl/traffic-data/$cctvId?$query'));

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((json) => TrafficData.fromJson(json)).toList();
    } else {
      print('Failed to load traffic data for $cctvId: ${response.body}');
      throw Exception('Failed to load traffic data');
    }
  }
}