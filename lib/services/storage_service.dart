// lib/services/storage_service.dart
// Install package: shared_preferences: ^2.2.0

import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  static SharedPreferences? _preferences;

  static Future<void> init() async {
    _preferences = await SharedPreferences.getInstance();
  }

  // Metode untuk menyimpan dan mengambil data
  Future<void> saveString(String key, String value) async {
    await _preferences?.setString(key, value);
  }

  String? getString(String key) {
    return _preferences?.getString(key);
  }

  Future<void> remove(String key) async {
    await _preferences?.remove(key);
  }

  // Contoh: Menyimpan token autentikasi
  Future<void> saveAuthToken(String token) async {
    await saveString('authToken', token);
  }

  String? getAuthToken() {
    return getString('authToken');
  }
}