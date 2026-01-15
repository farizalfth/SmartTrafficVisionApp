// lib/screens/dashboard_screen.dart

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import 'dart:math';
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

import 'package:smarttrafficapp/services/traffic_service.dart';
import 'package:smarttrafficapp/data/cctv_data_source.dart';
import 'package:smarttrafficapp/models/cctv.dart';
import 'package:smarttrafficapp/screens/chat_screen.dart';
import 'package:smarttrafficapp/screens/notification_screen.dart';
import 'package:smarttrafficapp/widgets/summary_card.dart';
import 'package:smarttrafficapp/widgets/cctv_feed_thumbnail.dart';
import 'package:smarttrafficapp/screens/live_cctv_screen.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  // --- VARIABEL LAMA (TETAP ADA) ---
  final MapController _mapController = MapController();
  final TrafficService _trafficService = TrafficService();

  List<Polyline> _routeLines = [];
  List<Marker> _routeMarkers = [];
  Map<String, Map<String, double>> _cctvCongestionData = {};
  List<String> _activeWarnings = [];

  static const LatLng _initialCenter = LatLng(-7.150975, 110.140259);
  static const double _initialZoom = 8;

  // --- VARIABEL BARU (UNTUK INPUT LAPORAN WARGA) ---
  late TextEditingController _nameController;
  late TextEditingController _commentController;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();

    // Inisialisasi Controller
    _nameController = TextEditingController();
    _commentController = TextEditingController();

    // Logic Lama
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _generateChartData();
    });
  }

  @override
  void dispose() {
    // Hapus controller saat layar ditutup agar hemat memori
    _nameController.dispose();
    _commentController.dispose();
    super.dispose();
  }

  // --- FUNGSI LAMA (TETAP ADA) ---
  void _generateChartData() {
    final cctvProvider = Provider.of<CCTVDataSource>(context, listen: false);
    final random = Random();

    if (_cctvCongestionData.length != cctvProvider.cctvList.length) {
      setState(() {
        _cctvCongestionData = {
          for (var cctv in cctvProvider.cctvList)
            cctv.id: {
              'Hari Ini': random.nextDouble() * 0.5 + 0.3,
              'Minggu Ini': random.nextDouble() * 0.5 + 0.3,
              'Bulan Ini': random.nextDouble() * 0.5 + 0.3,
            }
        };
      });
    }
  }

  // --- FUNGSI BARU (KIRIM LAPORAN KE FIREBASE) ---
  Future<void> _submitReport() async {
    if (_nameController.text.isEmpty || _commentController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Nama dan Komentar harus diisi!")));
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      // TAMBAHKAN URL DATABASE SECARA EKSPLISIT DI SINI
      final String databaseUrl =
          "https://smart-traffic-vision-app-default-rtdb.asia-southeast1.firebasedatabase.app";
      final dbRef = FirebaseDatabase.instanceFor(
              app: Firebase.app(), databaseURL: databaseUrl)
          .ref('user_comments');

      DateTime now = DateTime.now();
      String dateStr = DateFormat('yyyy-MM-dd').format(now);
      String timeStr = DateFormat('HH:mm:ss').format(now);
      String dayStr = DateFormat('EEEE', 'id_ID').format(now);

      await dbRef.push().set({
        'nama': _nameController.text,
        'komentar': _commentController.text,
        'tanggal': dateStr,
        'jam': timeStr,
        'hari': dayStr,
        'timestamp': ServerValue.timestamp,
        'sentimen': 'Netral',
      });

      _nameController.clear();
      _commentController.clear();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Laporan berhasil dikirim!")));
      }
    } catch (e) {
      if (mounted) {
        // Menampilkan pesan error yang lebih bersih
        debugPrint("Firebase Error: $e");
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text("Gagal mengirim laporan. Pastikan koneksi stabil.")));
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  // ================= FUNGSI LOKASI & PETA =================

  Future<LatLng?> getCoordinatesFromNominatim(String query) async {
    final String url =
        'https://nominatim.openstreetmap.org/search?q=${Uri.encodeComponent("$query, Indonesia")}&format=json&limit=1';
    try {
      final response = await http
          .get(Uri.parse(url), headers: {'User-Agent': 'SmartTrafficApp/1.0'});
      if (response.statusCode == 200) {
        final List data = json.decode(response.body);
        if (data.isNotEmpty) {
          return LatLng(
              double.parse(data[0]['lat']), double.parse(data[0]['lon']));
        }
      }
    } catch (e) {
      debugPrint("Error Geocoding: $e");
    }
    return null;
  }

  Future<String?> getAddressFromCoordinates(double lat, double lon) async {
    final String url =
        'https://nominatim.openstreetmap.org/reverse?lat=$lat&lon=$lon&format=json';
    try {
      final response = await http
          .get(Uri.parse(url), headers: {'User-Agent': 'SmartTrafficApp/1.0'});
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['display_name'] ?? "Lokasi Terpilih";
      }
    } catch (e) {
      debugPrint("Error Reverse Geocoding: $e");
    }
    return null;
  }

  Future<List<LatLng>> getRoutePoints(LatLng start, LatLng end) async {
    final String url =
        'https://router.project-osrm.org/route/v1/driving/${start.longitude},${start.latitude};${end.longitude},${end.latitude}?geometries=geojson&overview=full';
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> coordinates =
            data['routes'][0]['geometry']['coordinates'];
        return coordinates
            .map((coord) => LatLng(coord[1].toDouble(), coord[0].toDouble()))
            .toList();
      }
    } catch (e) {
      debugPrint('Error request rute: $e');
    }
    return [start, end];
  }

  Future<Position?> _determinePosition(BuildContext context) async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('GPS tidak aktif. Silakan aktifkan.')));
      }
      return null;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Izin lokasi ditolak.')));
        }
        return null;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text(
              'Izin lokasi diblokir Browser. Klik ikon "i" di sebelah URL untuk reset.'),
          duration: Duration(seconds: 4),
        ));
      }
      return null;
    }

    try {
      return await Geolocator.getCurrentPosition(
        desiredAccuracy:
            kIsWeb ? LocationAccuracy.medium : LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Gagal mendapatkan lokasi.')));
      }
      return null;
    }
  }

  // ================= UI BUILD =================

  @override
  Widget build(BuildContext context) {
    final cctvProvider = Provider.of<CCTVDataSource>(context);
    final List<CCTV> cctvList = cctvProvider.cctvList;
    final numberFormat = NumberFormat("#,##0", "id_ID");

    return StreamBuilder(
        stream: _trafficService.trafficStream,
        builder: (context, AsyncSnapshot<DatabaseEvent> snapshot) {
          int grandTotalHariIni = 0;
          String generalStatus = "Lancar";
          _activeWarnings = [];

          // Map baru untuk menampung statistik detail per CCTV untuk Grafik
          Map<String, Map<String, dynamic>> cctvStatsMap = {};

          if (snapshot.hasData && snapshot.data!.snapshot.value != null) {
            try {
              final rawData = snapshot.data!.snapshot.value;

              void processItem(String key, dynamic value) {
                if (value is Map) {
                  int cctvTotal = 0;
                  String status = "Lancar";
                  int density = 0;
                  String duration = "-";
                  String cctvName = "CCTV $key";

                  try {
                    final cctv = cctvList.firstWhere((c) => c.id == key);
                    cctvName = cctv.name;
                  } catch (e) {}

                  if (value.containsKey('live') && value['live'] is Map) {
                    final liveData = value['live'] as Map;

                    // 1. Ambil Total Akumulasi (Data Hari Ini)
                    cctvTotal = int.tryParse(
                            liveData['total_akumulasi_hari_ini']?.toString() ??
                                '0') ??
                        0;

                    // 2. Ambil Status (Real-time)
                    status = liveData['status']?.toString() ?? 'Lancar';

                    // 3. Ambil Kepadatan (Sesuaikan Key: kepadatan_persen)
                    density = int.tryParse(
                            liveData['kepadatan_persen']?.toString() ?? '0') ??
                        0;

                    // 4. Ambil Durasi (Sesuaikan Key: session_duration)
                    duration =
                        liveData['session_duration']?.toString() ?? "Aktif";
                  }

                  grandTotalHariIni += cctvTotal;

                  // Masukkan ke Map untuk Grafik (Jangan dihapus)
                  cctvStatsMap[key] = {
                    'density': density,
                    'duration': duration,
                    'status': status,
                  };

                  // --- LOGIKA NOTIFIKASI & STATUS UMUM ---
                  if (status.toLowerCase().contains('macet')) {
                    generalStatus = "Macet";

                    // Ambil waktu saat ini secara real-time
                    DateTime now = DateTime.now();
                    String dayStr =
                        DateFormat('EEEE', 'id_ID').format(now); // Contoh: Rabu
                    String dateStr = DateFormat('dd MMMM yyyy', 'id_ID')
                        .format(now); // Contoh: 15 Januari 2026
                    String timeStr =
                        DateFormat('HH:mm:ss').format(now); // Contoh: 07:15:30

                    // Masukkan informasi lengkap ke list peringatan
                    _activeWarnings.add(
                        "Kepadatan Tinggi di $cctvName\n$dayStr, $dateStr | Pukul $timeStr WIB");
                  }
                  // Tambahkan ini agar Summary Card "Kepadatan" di atas tetap berfungsi
                  else if (status.toLowerCase().contains('padat')) {
                    if (generalStatus != "Macet") generalStatus = "Padat";
                  }
                }
              }

              if (rawData is Map) {
                rawData.forEach(
                    (key, value) => processItem(key.toString(), value));
              } else if (rawData is List) {
                for (int i = 0; i < rawData.length; i++) {
                  if (rawData[i] != null) processItem(i.toString(), rawData[i]);
                }
              }
            } catch (e) {
              debugPrint("Error parsing dashboard data: $e");
            }
          }

          int totalWarnings = _activeWarnings.length;

          // --- UPDATE TAMPILAN (CUSTOM HEADER DENGAN MENU) ---
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // HEADER CUSTOM (DIRAPIKAN AGAR TENGAH)
                Row(
                  children: [
                    // 1. KIRI: Tombol Menu
                    IconButton(
                      icon:
                          const Icon(Icons.menu, size: 24, color: Colors.white),
                      onPressed: () => Scaffold.of(context).openDrawer(),
                    ),

                    // 2. TENGAH: Judul Dashboard (Menggunakan Expanded agar rata tengah)
                    Expanded(
                      child: Text(
                        'Dashboard',
                        textAlign: TextAlign.center, // Rata Tengah
                        style: const TextStyle(
                            fontSize:
                                22, // Ukuran disamakan dengan AppBar standar (20-22)
                            fontWeight:
                                FontWeight.w500, // Ketebalan standar AppBar
                            color: Colors.white),
                      ),
                    ),

                    // 3. KANAN: Chat & Notifikasi
                    // Kita bungkus Row ini agar ukurannya pas dan judul tetap di tengah
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.chat_bubble_outline),
                          onPressed: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => const ChatScreen())),
                        ),
                        Stack(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.notifications_none),
                              onPressed: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) => NotificationScreen(
                                          initialNotifications:
                                              _activeWarnings))),
                            ),
                            if (totalWarnings > 0)
                              Positioned(
                                right: 11,
                                top: 11,
                                child: Container(
                                  padding: const EdgeInsets.all(2),
                                  decoration: BoxDecoration(
                                      color: Colors.red,
                                      borderRadius: BorderRadius.circular(6)),
                                  constraints: const BoxConstraints(
                                      minWidth: 12, minHeight: 12),
                                  child: Text('$totalWarnings',
                                      style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 8,
                                          fontWeight: FontWeight.bold),
                                      textAlign: TextAlign.center),
                                ),
                              )
                          ],
                        ),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // 2. RINGKASAN DATA
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    SummaryCard(
                        title: 'Total Kendaraan',
                        value: numberFormat.format(grandTotalHariIni),
                        valueColor: Colors.green,
                        icon: Icons.directions_car),
                    SummaryCard(
                        title: 'Kepadatan',
                        value: generalStatus,
                        valueColor: generalStatus == "Macet"
                            ? Colors.red
                            : Colors.orange,
                        icon: Icons.traffic),
                    SummaryCard(
                        title: 'Peringatan',
                        value: '$totalWarnings',
                        valueColor:
                            totalWarnings > 0 ? Colors.red : Colors.green,
                        icon: totalWarnings > 0
                            ? Icons.warning
                            : Icons.check_circle),
                  ],
                ),
                const SizedBox(height: 24),

                // 3. PETA
                _buildMapSection(context, [
                  // Tambahkan parameter cctvStatsMap[c.id] agar fungsi tahu status trafik tiap CCTV
                  ...cctvList
                      .map((c) =>
                          _buildCCTVMarker(context, c, cctvStatsMap[c.id]))
                      .toList(),
                  ..._routeMarkers
                ]),
                const SizedBox(height: 24),

                // 4. GRAFIK KENDARAAN (LIVE METRICS)
                _buildCongestionTrendChartsPerCCTV(
                  context,
                  cctvList,
                  cctvStatsMap, // Gunakan Map ini agar Real-time mengikuti Firebase
                ),
                const SizedBox(height: 24),

                // 5. INPUT LAPORAN WARGA (POSISI DI BAWAH)
                _buildCitizenReportInput(),
              ],
            ),
          );
        });
  }

  // ================= WIDGET COMPONENTS =================

  Widget _buildMapSection(BuildContext context, List<Marker> markers) {
    return Card(
      color: Theme.of(context).cardColor,
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text('Peta Lalu Lintas Interaktif',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold)),
              const Icon(Icons.map, color: Colors.blueAccent),
            ]),
            const SizedBox(height: 12),
            Container(
              height: 300,
              width: double.infinity,
              decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white12)),
              clipBehavior: Clip.antiAlias,
              child: FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                    initialCenter: _initialCenter,
                    initialZoom: _initialZoom,
                    minZoom: 4,
                    maxZoom: 18),
                children: [
                  TileLayer(
                      urlTemplate:
                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.smarttraffic.app'),
                  PolylineLayer(polylines: _routeLines),
                  MarkerLayer(markers: markers),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Center(
              child: ElevatedButton.icon(
                onPressed: () => _showRoutePlanningDialog(context),
                icon: const Icon(Icons.alt_route_rounded, size: 20),
                label: const Text('Rute & Hindari Macet',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    foregroundColor: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Marker _buildCCTVMarker(
      BuildContext context, CCTV cctv, Map<String, dynamic>? trafficData) {
    // Ambil status dari data real-time, default ke 'lancar' jika data belum ada
    String status =
        trafficData?['status']?.toString().toLowerCase() ?? 'lancar';
    bool isOnline = cctv.status.toLowerCase() == 'online';

    // Logika Warna:
    Color markerColor = Colors.green; // Default: Lancar / Hijau

    if (!isOnline) {
      markerColor = Colors.grey; // Abu-abu jika CCTV mati
    } else if (status.contains('macet')) {
      markerColor = Colors.red; // Merah jika Macet
    } else if (status.contains('padat')) {
      markerColor = Colors.orange; // Oranye jika Padat
    }

    return Marker(
      point: LatLng(cctv.latitude, cctv.longitude),
      width: 60,
      height: 60,
      child: GestureDetector(
        onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => LiveCCTVScreen(initialCCTVId: cctv.id))),
        child: Column(children: [
          // Icon marker menggunakan warna dinamis
          Icon(Icons.location_on, size: 40, color: markerColor),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            decoration: BoxDecoration(
                color: Colors.black54, borderRadius: BorderRadius.circular(4)),
            child: Text(cctv.name,
                style: const TextStyle(color: Colors.white, fontSize: 8),
                overflow: TextOverflow.ellipsis,
                maxLines: 1),
          ),
        ]),
      ),
    );
  }

  // --- WIDGET INPUT LAPORAN WARGA ---
  Widget _buildCitizenReportInput() {
    return Card(
      color: Theme.of(context).cardColor,
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Laporan Warga',
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white)),
                Icon(Icons.report, color: Colors.redAccent),
              ],
            ),
            const SizedBox(height: 8),
            const Text("Laporkan kondisi lalu lintas terkini di sekitar Anda.",
                style: TextStyle(color: Colors.grey, fontSize: 12)),
            const SizedBox(height: 20),
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'Nama Pelapor',
                prefixIcon: const Icon(Icons.person, color: Colors.blueAccent),
                filled: true,
                fillColor: const Color(0xFF1E1E1E),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _commentController,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: 'Kondisi Lalu Lintas (Komentar)',
                alignLabelWithHint: true,
                prefixIcon: const Padding(
                    padding: EdgeInsets.only(bottom: 40),
                    child: Icon(Icons.comment, color: Colors.orangeAccent)),
                filled: true,
                fillColor: const Color(0xFF1E1E1E),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isSubmitting ? null : _submitReport,
                icon: _isSubmitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.send),
                label: Text(_isSubmitting ? "Mengirim..." : "Kirim Laporan"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- GRAFIK KENDARAAN (DATA REAL DARI FIREBASE) ---
  Widget _buildCongestionTrendChartsPerCCTV(BuildContext context,
      List<CCTV> cctvList, Map<String, Map<String, dynamic>> stats) {
    return Card(
      color: Theme.of(context).cardColor,
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Status Kepadatan Terkini',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white)),
              Icon(Icons.bar_chart, color: Colors.orangeAccent),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 230, // Sedikit ditambah tingginya agar angka tidak mepet
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: cctvList.length,
              itemBuilder: (context, index) {
                final cctv = cctvList[index];
                final data = stats[cctv.id] ??
                    {'density': 0, 'duration': '-', 'status': 'Offline'};

                int density = int.tryParse(data['density'].toString()) ?? 0;
                String duration = data['duration']?.toString() ?? '-';
                String status = data['status']?.toString() ?? 'Lancar';

                Color barColor = Colors.green;
                if (density > 70)
                  barColor = Colors.red;
                else if (density > 40) barColor = Colors.orange;

                return Container(
                  width: 180,
                  margin: const EdgeInsets.only(right: 12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                      color: const Color(0xFF1E1E1E),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white10)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(cctv.name,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 11),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 8),

                      _buildSmallInfoRow("Durasi:", duration, Colors.white),
                      _buildSmallInfoRow("Status:", status, barColor),

                      const SizedBox(height: 12),

                      // --- TAMBAHKAN ANGKA PERSENTASE DI SINI ---
                      Center(
                        child: Text(
                          "$density%",
                          style: TextStyle(
                              color: barColor,
                              fontSize: 16,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(height: 4),

                      // Grafik Batang Kepadatan
                      Expanded(
                        child: BarChart(BarChartData(
                          maxY: 100,
                          barGroups: [
                            BarChartGroupData(x: 0, barRods: [
                              BarChartRodData(
                                  toY: density.toDouble(),
                                  color: barColor,
                                  width: 35,
                                  borderRadius: const BorderRadius.vertical(
                                      top: Radius.circular(6)),
                                  backDrawRodData: BackgroundBarChartRodData(
                                      show: true,
                                      toY: 100,
                                      color: Colors.white10))
                            ]),
                          ],
                          gridData: const FlGridData(show: false),
                          borderData: FlBorderData(show: false),
                          titlesData: FlTitlesData(
                            bottomTitles: AxisTitles(
                                sideTitles: SideTitles(
                                    showTitles: true,
                                    getTitlesWidget: (v, m) => const Text(
                                        '% Kepadatan',
                                        style: TextStyle(
                                            fontSize: 10,
                                            color: Colors.grey)))),
                            leftTitles: const AxisTitles(
                                sideTitles: SideTitles(showTitles: false)),
                            topTitles: const AxisTitles(
                                sideTitles: SideTitles(showTitles: false)),
                            rightTitles: const AxisTitles(
                                sideTitles: SideTitles(showTitles: false)),
                          ),
                        )),
                      ),
                    ],
                  ),
                );
              },
            ),
          )
        ]),
      ),
    );
  }

// Widget pembantu untuk merapikan teks (Diletakkan di dalam class _DashboardScreenState)
  Widget _buildSmallInfoRow(String label, String value, Color valueColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 10)),
          Text(value,
              style: TextStyle(
                  color: valueColor,
                  fontSize: 10,
                  fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Future<void> _showRoutePlanningDialog(BuildContext context) async {
    TextEditingController startController = TextEditingController();
    TextEditingController destinationController = TextEditingController();
    bool isLoadingLocation = false;
    LatLng? cachedGpsLocation;

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(children: [
            Icon(Icons.directions, color: Colors.blueAccent),
            SizedBox(width: 10),
            Text('Rencanakan Rute')
          ]),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: startController,
                decoration: InputDecoration(
                  labelText: 'Lokasi Awal',
                  hintText: 'Cari lokasi awal...',
                  prefixIcon: const Icon(Icons.my_location),
                  suffixIcon: IconButton(
                    icon: isLoadingLocation
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.gps_fixed, color: Colors.blueAccent),
                    onPressed: isLoadingLocation
                        ? null
                        : () async {
                            setStateDialog(() => isLoadingLocation = true);
                            Position? pos = await _determinePosition(context);
                            if (pos != null) {
                              cachedGpsLocation =
                                  LatLng(pos.latitude, pos.longitude);
                              String? addr = await getAddressFromCoordinates(
                                  pos.latitude, pos.longitude);
                              startController.text =
                                  addr ?? "${pos.latitude}, ${pos.longitude}";
                            }
                            setStateDialog(() => isLoadingLocation = false);
                          },
                  ),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: destinationController,
                decoration: InputDecoration(
                  labelText: 'Lokasi Tujuan',
                  hintText: 'Cari lokasi tujuan...',
                  prefixIcon:
                      const Icon(Icons.location_on, color: Colors.redAccent),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child:
                    const Text('Batal', style: TextStyle(color: Colors.grey))),
            ElevatedButton(
              onPressed: () async {
                String startName = startController.text;
                String destName = destinationController.text;
                Navigator.pop(context);
                if (startName.isEmpty || destName.isEmpty) return;

                LatLng? startCoord =
                    await getCoordinatesFromNominatim(startName);
                if (startCoord == null && cachedGpsLocation != null)
                  startCoord = cachedGpsLocation;
                LatLng? destCoord = await getCoordinatesFromNominatim(destName);

                if (startCoord != null && destCoord != null) {
                  List<LatLng> points =
                      await getRoutePoints(startCoord, destCoord);
                  setState(() {
                    _routeLines = [
                      Polyline(
                          points: points,
                          strokeWidth: 5.0,
                          color: Colors.blueAccent)
                    ];
                    _routeMarkers = [
                      Marker(
                          point: startCoord!,
                          width: 80,
                          height: 80,
                          child: const Icon(Icons.trip_origin,
                              color: Colors.blue, size: 40)),
                      Marker(
                          point: destCoord,
                          width: 80,
                          height: 80,
                          child: const Icon(Icons.flag,
                              color: Colors.red, size: 40)),
                    ];
                  });
                  double centerLat =
                      (startCoord.latitude + destCoord.latitude) / 2;
                  double centerLon =
                      (startCoord.longitude + destCoord.longitude) / 2;
                  _mapController.move(LatLng(centerLat, centerLon), 9.0);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                      content: Text('Lokasi tidak ditemukan.'),
                      backgroundColor: Colors.red));
                }
              },
              style:
                  ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent),
              child: const Text('Cari Rute',
                  style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  List<BarChartGroupData> createBarGroups(Map<String, double> data) {
    const barWidth = 18.0;
    final Map<String, int> xValues = {
      'Hari Ini': 0,
      'Minggu Ini': 1,
      'Bulan Ini': 2
    };
    final List<Color> barColors = [
      Colors.lightBlueAccent,
      Colors.orangeAccent,
      Colors.redAccent
    ];
    return data.entries.map((entry) {
      final x = xValues[entry.key] ?? 0;
      return BarChartGroupData(
        x: x,
        barRods: [
          BarChartRodData(
              toY: entry.value,
              color: barColors[x % barColors.length],
              width: barWidth,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(6)),
              backDrawRodData: BackgroundBarChartRodData(
                  show: true, toY: 1, color: Colors.white.withOpacity(0.05)))
        ],
      );
    }).toList();
  }

  FlTitlesData buildAxesTitles() {
    return FlTitlesData(
      show: true,
      bottomTitles: AxisTitles(
          sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (v, m) => Text(
                  v == 0
                      ? 'Hari Ini'
                      : v == 1
                          ? 'Minggu Ini'
                          : 'Bulan Ini',
                  style:
                      const TextStyle(fontSize: 10, color: Colors.white70)))),
      leftTitles: AxisTitles(
          sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              getTitlesWidget: (v, m) => Text('${(v * 100).toInt()}%',
                  style:
                      const TextStyle(fontSize: 10, color: Colors.white54)))),
      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
    );
  }
}
