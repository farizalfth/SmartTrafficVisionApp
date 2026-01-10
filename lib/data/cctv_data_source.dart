// lib/data/cctv_data_source.dart

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:smarttrafficapp/models/cctv.dart';

class CCTVDataSource extends ChangeNotifier {
  // URL Database Firebase
  static const String _dbUrl = 'https://smart-traffic-vision-app-default-rtdb.asia-southeast1.firebasedatabase.app/';
  
  late final DatabaseReference _trafficRef;

  // List Internal (Metadata Nama & URL disimpan di HP sementara)
  // Agar bisa di-Edit/Delete lewat Menu Manajemen Kamera
  final List<CCTV> _cctvList = [
    CCTV(
      id: 'cctv_01', // ID HARUS SAMA DENGAN DI PYTHON/FIREBASE
      name: 'CCTV Pontianak (Simpang Garuda)',
      location: 'Simpang Garuda, Pontianak',
      latitude: -0.0223, 
      longitude: 109.3322,
      status: 'Online',
      rstpUrl: 'https://www.youtube.com/watch?v=9_C8fP2_C68',
    ),
    CCTV(
      id: 'cctv_02',
      name: 'CCTV Pontianak (Tugu Khatulistiwa)',
      location: 'Tugu Khatulistiwa, Pontianak',
      latitude: 0.0000,
      longitude: 109.3217,
      status: 'Online',
      rstpUrl: 'https://www.youtube.com/watch?v=DUMMY_LINK',
    ),
    CCTV(
      id: 'cctv_03',
      name: 'CCTV Demak (Alun-Alun)',
      location: 'Alun-Alun, Demak',
      latitude: -6.8944, 
      longitude: 110.6386,
      status: 'Online',
      rstpUrl: 'https://www.youtube.com/watch?v=DUMMY_LINK',
    ),
    CCTV(
      id: 'cctv_04',
      name: 'CCTV Demak (Pasar Bintoro)',
      location: 'Pasar Bintoro, Demak',
      latitude: -6.8925, 
      longitude: 110.6401,
      status: 'Online',
      rstpUrl: 'https://www.youtube.com/watch?v=DUMMY_LINK',
    ),
    CCTV(
      id: 'cctv_05',
      name: 'CCTV Demak (Pertigaan Trengguli)',
      location: 'Pertigaan Trengguli, Demak',
      latitude: -6.8372, 
      longitude: 110.6975,
      status: 'Online',
      rstpUrl: 'https://www.youtube.com/watch?v=DUMMY_LINK',
    ),
  ];

  static final CCTVDataSource _instance = CCTVDataSource._internal();
  factory CCTVDataSource() => _instance;

  CCTVDataSource._internal() {
    _initFirebaseConnection();
  }

  List<CCTV> get cctvList => List.unmodifiable(_cctvList);

  // --- KONEKSI FIREBASE (Untuk Update Status Otomatis) ---
  void _initFirebaseConnection() {
    try {
      final firebaseApp = Firebase.app();
      final rtdb = FirebaseDatabase.instanceFor(app: firebaseApp, databaseURL: _dbUrl);
      _trafficRef = rtdb.ref('traffic_data');

      // Dengarkan data real-time
      _trafficRef.onValue.listen((event) {
        if (event.snapshot.value != null) {
          _updateStatusFromFirebase(event.snapshot.value);
        }
      });
    } catch (e) {
      debugPrint("Error Init Firebase di DataSource: $e");
    }
  }

  // --- LOGIKA UPDATE STATUS DARI FIREBASE ---
  void _updateStatusFromFirebase(dynamic data) {
    try {
      final Map<dynamic, dynamic> values = data as Map<dynamic, dynamic>;
      bool hasChange = false;

      // Loop data dari firebase (misal: cctv_01: {kepadatan: Macet})
      values.forEach((key, value) {
        final String remoteId = key.toString();
        // Hapus variabel mobil/motor yang tidak terpakai agar warning hilang
        // final int mobil = value['mobil'] ?? 0;  <-- HAPUS INI
        // final int motor = value['motor'] ?? 0;  <-- HAPUS INI
        final String kepadatan = value['kepadatan'] ?? 'Normal';

        // Cari CCTV di list lokal yang ID-nya sama
        final index = _cctvList.indexWhere((c) => c.id == remoteId);
        if (index != -1) {
          // Update statusnya saja, nama/lokasi tetap dari inputan user
          String newStatus = (kepadatan == 'Macet') ? 'Macet' : 'Online';
          
          if (_cctvList[index].status != newStatus) {
            // Kita gunakan copyWith (pastikan model CCTV punya method copyWith)
            // Atau buat object baru manual
            _cctvList[index] = CCTV(
              id: _cctvList[index].id,
              name: _cctvList[index].name,
              location: _cctvList[index].location,
              latitude: _cctvList[index].latitude,
              longitude: _cctvList[index].longitude,
              rstpUrl: _cctvList[index].rstpUrl,
              thumbnailUrl: _cctvList[index].thumbnailUrl,
              lastUpdate: DateTime.now().toString(),
              status: newStatus, // <-- Ini yang diupdate dari Firebase
            );
            hasChange = true;
          }
        }
      });

      if (hasChange) notifyListeners();
    } catch (e) {
      debugPrint("Error Parsing: $e");
    }
  }

  // --- CRUD METHODS (PERBAIKAN ERROR "Undefined Method") ---
  
  // 1. Tambah CCTV
  void addCCTV(CCTV cctv) {
    _cctvList.add(cctv);
    notifyListeners();
  }

  // 2. Update CCTV (Edit Nama/Url/Lokasi)
  // Parameter pertama 'id' untuk mencari target, parameter kedua 'newCCTV' data barunya
  void updateCCTV(String id, CCTV newCCTV) {
    final index = _cctvList.indexWhere((c) => c.id == id);
    if (index != -1) {
      _cctvList[index] = newCCTV;
      notifyListeners();
    }
  }

  // 3. Hapus CCTV
  void deleteCCTV(String id) {
    _cctvList.removeWhere((c) => c.id == id);
    notifyListeners();
  }
}