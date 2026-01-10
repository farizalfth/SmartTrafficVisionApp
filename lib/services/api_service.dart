// lib/services/api_service.dart

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth; // Alias biar gak bentrok
import 'package:firebase_database/firebase_database.dart';

import 'package:smarttrafficapp/models/cctv.dart';
import 'package:smarttrafficapp/models/traffic_data.dart';
import 'package:smarttrafficapp/models/user.dart'; // Pastikan model User Anda sesuai

// --- Abstract Base Class ---
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
  // 1. URL Database Spesifik
  static const String _dbUrl = 'https://smart-traffic-vision-app-default-rtdb.asia-southeast1.firebasedatabase.app/';
  
  final fb_auth.FirebaseAuth _auth = fb_auth.FirebaseAuth.instance;
  late final DatabaseReference _dbRef;

  ApiService() {
    // Inisialisasi Database dengan URL khusus
    final firebaseApp = Firebase.app();
    final rtdb = FirebaseDatabase.instanceFor(app: firebaseApp, databaseURL: _dbUrl);
    _dbRef = rtdb.ref();
  }

  // --- Auth & User Management ---
  
  @override
  Future<User?> login(String email, String password) async {
    try {
      // Login ke Firebase Auth
      final credential = await _auth.signInWithEmailAndPassword(
        email: email, 
        password: password
      );
      
      if (credential.user != null) {
        // Ambil detail user dari database (opsional, jika ada node 'users')
        // Disini kita return User model lokal berdasarkan data Auth
        return User(
          id: credential.user!.uid,
          username: credential.user!.displayName ?? email.split('@')[0],
          email: email,
          role: UserRole.user, // Default role, atau ambil dari DB jika ada
          profilePictureUrl: credential.user!.photoURL ?? 'assets/images/profile.jpg',
        );
      }
    } catch (e) {
      debugPrint("Login Error: $e");
    }
    return null;
  }

  @override
  Future<List<User>> getUsers() async {
    // Mengambil daftar user dari node 'users' di Firebase (Jika fitur admin user management aktif)
    try {
      final snapshot = await _dbRef.child('users').get();
      if (snapshot.exists) {
        final data = snapshot.value as Map<dynamic, dynamic>;
        return data.entries.map((e) {
          final userData = Map<String, dynamic>.from(e.value);
          // Mapping manual atau pakai fromJson jika model User support
          return User(
            id: e.key,
            username: userData['username'] ?? 'User',
            email: userData['email'] ?? '',
            role: _parseUserRole(userData['role'] ?? 'user'), profilePictureUrl: '',
          );
        }).toList();
      }
    } catch (e) {
      debugPrint("Get Users Error: $e");
    }
    return [];
  }

  // --- CCTV Management (CRUD ke Firebase 'cctvs') ---

  @override
  Future<List<CCTV>> getCCTVs() async {
    List<CCTV> cctvs = [];
    try {
      // Baca dari node 'cctvs' (Metadata kamera)
      final snapshot = await _dbRef.child('cctvs').get();
      
      if (snapshot.exists) {
        final data = snapshot.value as Map<dynamic, dynamic>;
        data.forEach((key, value) {
          try {
            // Gabungkan ID dari Key dengan data Value
            final mapData = Map<String, dynamic>.from(value as Map);
            mapData['id'] = key; // Set ID dari Key Firebase
            
            cctvs.add(CCTV.fromMap(mapData));
          } catch (e) {
            debugPrint("Error parsing CCTV $key: $e");
          }
        });
      } else {
        // Jika Database Kosong, Anda bisa memanggil fungsi seeder di sini sekali saja
        // _seedDummyData(); 
      }
    } catch (e) {
      debugPrint("Get CCTVs Error: $e");
    }
    return cctvs;
  }

  @override
  Future<CCTV> addCCTV(CCTV newCCTV) async {
    try {
      // Push data baru ke node 'cctvs'
      // Menggunakan push() agar ID digenerate otomatis oleh Firebase
      final newRef = _dbRef.child('cctvs').push();
      
      // Update ID di objek lokal dengan ID dari Firebase
      final cctvWithId = newCCTV.copyWith(id: newRef.key!);
      
      await newRef.set(cctvWithId.toJson());
      return cctvWithId;
    } catch (e) {
      debugPrint("Add CCTV Error: $e");
      rethrow;
    }
  }

  @override
  Future<void> updateCCTV(String id, CCTV updatedCCTV) async {
    try {
      await _dbRef.child('cctvs/$id').update(updatedCCTV.toJson());
    } catch (e) {
      debugPrint("Update CCTV Error: $e");
      rethrow;
    }
  }

  @override
  Future<void> deleteCCTV(String id) async {
    try {
      await _dbRef.child('cctvs/$id').remove();
    } catch (e) {
      debugPrint("Delete CCTV Error: $e");
      rethrow;
    }
  }

  // --- Traffic Data (History) ---

  // Helper method to parse string to UserRole enum
  UserRole _parseUserRole(String roleString) {
    try {
      return UserRole.values.firstWhere((role) => role.toString().split('.').last == roleString.toLowerCase());
    } catch (e) {
      return UserRole.user; // Default fallback
    }
  }

  @override
  Future<List<TrafficData>> getTrafficData(String cctvId, {DateTime? startDate, DateTime? endDate}) async {
    List<TrafficData> trafficList = [];
    try {
      // Mengambil history dari node 'traffic_history/ID_CCTV'
      // Query order by timestamp (asumsi timestamp disimpan sebagai key atau child)
      Query query = _dbRef.child('traffic_history/$cctvId').orderByKey().limitToLast(50); 
      
      final snapshot = await query.get();

      if (snapshot.exists) {
        final data = snapshot.value as Map<dynamic, dynamic>;
        data.forEach((key, value) {
          try {
            final mapData = Map<dynamic, dynamic>.from(value as Map);
            // Pastikan timestamp ada
            if(mapData['timestamp'] == null) mapData['timestamp'] = DateTime.now().toIso8601String();
            
            trafficList.add(TrafficData.fromMap(mapData));
          } catch (e) {
            // Skip data rusak
          }
        });
        
        // Sorting berdasarkan waktu (Terbaru di akhir)
        trafficList.sort((a, b) => a.timestamp.compareTo(b.timestamp));
      }
    } catch (e) {
      debugPrint("Get Traffic Data Error: $e");
    }
    return trafficList;
  }
}