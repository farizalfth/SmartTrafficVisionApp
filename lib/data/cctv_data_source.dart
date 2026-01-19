// lib/data/cctv_data_source.dart

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:smarttrafficapp/models/cctv.dart';

class CCTVDataSource extends ChangeNotifier {
  // URL Database Firebase
  static const String _dbUrl = 'https://smart-traffic-vision-app-default-rtdb.asia-southeast1.firebasedatabase.app/';
  
  late final DatabaseReference _trafficRef;

  // List Internal (Diupdate sesuai data Web Service: ID 1-5, Nama, Lokasi, URL, Koordinat)
  final List<CCTV> _cctvList = [
    CCTV(
      id: '1', 
      name: 'CCTV Pontianak (Simpang Garuda)',
      location: 'Pontianak, Kalimantan Barat',
      latitude: -0.023851, 
      longitude: 109.333423,
      status: 'Online',
      rstpUrl: 'https://www.youtube.com/watch?v=_xzKYnk6zSE',
    ),
    CCTV(
      id: '2',
      name: 'CCTV Pontianak (Tugu Khatulistiwa)',
      location: 'Pontianak, Kalimantan Barat',
      latitude: 0.000000,
      longitude: 109.321100,
      status: 'Online',
      rstpUrl: 'https://www.youtube.com/watch?v=BEw38LHC5x4',
    ),
    CCTV(
      id: '3',
      name: 'CCTV Demak (Alun-Alun)',
      location: 'Demak, Jawa Tengah',
      latitude: -6.894621, 
      longitude: 110.636922,
      status: 'Online',
      rstpUrl: 'https://www.youtube.com/watch?v=aboCZ7gkclk',
    ),
    CCTV(
      id: '4',
      name: 'CCTV Demak (Pasar Bintoro)',
      location: 'Demak, Jawa Tengah',
      latitude: -6.8850, 
      longitude: 110.6400,
      status: 'Online',
      rstpUrl: 'https://www.youtube.com/watch?v=7c4CsGkmBu8',
    ),
    CCTV(
      id: '5',
      name: 'CCTV Demak (Pertigaan Trengguli)',
      location: 'Demak, Jawa Tengah',
      latitude: -6.8700, 
      longitude: 110.6500,
      status: 'Online',
      rstpUrl: 'https://www.youtube.com/watch?v=5nw3G2jtWaU',
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
      // Mengarah ke traffic_stats untuk mendapatkan status jika ada
      _trafficRef = rtdb.ref('traffic_stats');

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
      if (data is Map) {
        bool hasChange = false;

        data.forEach((key, value) {
          final String remoteId = key.toString();
          String kepadatan = 'Normal';

          // Cek status di dalam struktur traffic_stats
          if (value is Map && value.containsKey('live') && value['live'] is Map) {
             final live = value['live'];
             if (live['status'] != null) {
               kepadatan = live['status'];
             }
          }

          // Cari CCTV di list lokal yang ID-nya sama
          // Menggunakan smart matching (hapus karakter non-angka)
          final index = _cctvList.indexWhere((c) {
             String cleanLocal = c.id.replaceAll(RegExp(r'[^0-9]'), '');
             String cleanRemote = remoteId.replaceAll(RegExp(r'[^0-9]'), '');
             return cleanLocal == cleanRemote;
          });

          if (index != -1) {
            String newStatus = (kepadatan.contains('Macet')) ? 'Macet' : 'Online';
            
            if (_cctvList[index].status != newStatus) {
              _cctvList[index] = CCTV(
                id: _cctvList[index].id,
                name: _cctvList[index].name,
                location: _cctvList[index].location,
                latitude: _cctvList[index].latitude,
                longitude: _cctvList[index].longitude,
                rstpUrl: _cctvList[index].rstpUrl,
                thumbnailUrl: _cctvList[index].thumbnailUrl,
                lastUpdate: DateTime.now().toString(),
                status: newStatus, 
              );
              hasChange = true;
            }
          }
        });

        if (hasChange) notifyListeners();
      }
    } catch (e) {
      debugPrint("Error Parsing: $e");
    }
  }

  // --- CRUD METHODS ---
  
  void addCCTV(CCTV cctv) {
    _cctvList.add(cctv);
    notifyListeners();
  }

  void updateCCTV(String id, CCTV newCCTV) {
    final index = _cctvList.indexWhere((c) => c.id == id);
    if (index != -1) {
      _cctvList[index] = newCCTV;
      notifyListeners();
    }
  }

  void deleteCCTV(String id) {
    _cctvList.removeWhere((c) => c.id == id);
    notifyListeners();
  }
}