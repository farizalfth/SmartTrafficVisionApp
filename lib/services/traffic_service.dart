// lib/services/traffic_service.dart

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';

class TrafficService {
  // 1. URL Database Spesifik (Asia Southeast 1)
  static const String _dbUrl = 'https://smart-traffic-vision-app-default-rtdb.asia-southeast1.firebasedatabase.app/';

  late final DatabaseReference _trafficRef;

  TrafficService() {
    // 2. Inisialisasi Database
    final firebaseApp = Firebase.app();
    final rtdb = FirebaseDatabase.instanceFor(
      app: firebaseApp, 
      databaseURL: _dbUrl
    );
    
    // 3. Arahkan ke folder 'traffic_stats'
    // Agar bisa membaca semua key (3, 4, 5, dll) secara dinamis
    _trafficRef = rtdb.ref('traffic_stats');
  }

  // 4. Stream untuk mendengarkan data terus menerus
  Stream<DatabaseEvent> get trafficStream {
    return _trafficRef.onValue;
  }
}