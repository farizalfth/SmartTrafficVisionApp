import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';

class TrafficService {
  // URL INI WAJIB SAMA PERSIS DENGAN SCREENSHOT ANDA
  static const String _dbUrl = 'https://smart-traffic-vision-app-default-rtdb.asia-southeast1.firebasedatabase.app/';

  late final DatabaseReference _trafficRef;

  TrafficService() {
    final firebaseApp = Firebase.app();
    // Menghubungkan ke server Asia Southeast 1
    final rtdb = FirebaseDatabase.instanceFor(
      app: firebaseApp, 
      databaseURL: _dbUrl
    );
    
    // Mengarah ke folder utama 'traffic_stats'
    _trafficRef = rtdb.ref('traffic_stats');
  }

  Stream<DatabaseEvent> get trafficStream {
    return _trafficRef.onValue;
  }
}