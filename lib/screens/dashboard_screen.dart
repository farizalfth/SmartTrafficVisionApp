// lib/screens/dashboard_screen.dart

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

// Import Data & Models
import 'package:smarttrafficapp/data/cctv_data_source.dart';
import 'package:smarttrafficapp/models/cctv.dart';

// Import Screens & Widgets
import 'package:smarttrafficapp/screens/chat_screen.dart';
import 'package:smarttrafficapp/screens/notification_screen.dart';
import 'package:smarttrafficapp/widgets/summary_card.dart';
import 'package:smarttrafficapp/widgets/cctv_feed_thumbnail.dart';
import 'package:smarttrafficapp/screens/live_cctv_screen.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

// Import kIsWeb untuk cek apakah aplikasi jalan di Browser
import 'package:flutter/foundation.dart' show kIsWeb; 

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final MapController _mapController = MapController();
  
  // State Rute & Data
  List<Polyline> _routeLines = [];
  List<Marker> _routeMarkers = [];
  Map<String, Map<String, double>> _cctvCongestionData = {};

  final List<String> _earlyWarningMessages = [
    'PERINGATAN DINI: Kepadatan Ekstrem di Jl. Gatot Subroto, Semarang.',
  ];

  // Koordinat Default (Jawa Tengah)
  static const LatLng _initialCenter = LatLng(-7.150975, 110.140259); 
  static const double _initialZoom = 8;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _generateChartData();
    });
  }

  void _generateChartData() {
    final cctvProvider = Provider.of<CCTVDataSource>(context, listen: false);
    final random = Random();
    
    if (_cctvCongestionData.length != cctvProvider.cctvList.length) {
      setState(() {
        _cctvCongestionData = {
          for (var cctv in cctvProvider.cctvList) cctv.id: {
            'Hari Ini': random.nextDouble() * 0.5 + 0.3,
            'Minggu Ini': random.nextDouble() * 0.5 + 0.3,
            'Bulan Ini': random.nextDouble() * 0.5 + 0.3,
          }
        };
      });
    }
  }

  // ================= FUNGSI LOKASI & PETA =================

  // 1. Geocoding (Nama Tempat -> Koordinat)
  Future<LatLng?> getCoordinatesFromNominatim(String query) async {
    final String searchQuery = "$query, Indonesia";
    final String url = 'https://nominatim.openstreetmap.org/search?q=${Uri.encodeComponent(searchQuery)}&format=json&limit=1';

    try {
      final response = await http.get(Uri.parse(url), headers: {'User-Agent': 'SmartTrafficApp/1.0'});
      if (response.statusCode == 200) {
        final List data = json.decode(response.body);
        if (data.isNotEmpty) {
          return LatLng(double.parse(data[0]['lat']), double.parse(data[0]['lon']));
        }
      }
    } catch (e) {
      debugPrint("Error Geocoding: $e");
    }
    return null;
  }

  // 2. Reverse Geocoding (Koordinat -> Nama Jalan)
  Future<String?> getAddressFromCoordinates(double lat, double lon) async {
    final String url = 'https://nominatim.openstreetmap.org/reverse?lat=$lat&lon=$lon&format=json';
    try {
      final response = await http.get(Uri.parse(url), headers: {'User-Agent': 'SmartTrafficApp/1.0'});
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['display_name'] ?? "Lokasi Terpilih";
      }
    } catch (e) {
      debugPrint("Error Reverse Geocoding: $e");
    }
    return null;
  }

  // 3. Routing (Cari Jalur)
  Future<List<LatLng>> getRoutePoints(LatLng start, LatLng end) async {
    final String url = 'https://router.project-osrm.org/route/v1/driving/${start.longitude},${start.latitude};${end.longitude},${end.latitude}?geometries=geojson&overview=full';
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> coordinates = data['routes'][0]['geometry']['coordinates'];
        return coordinates.map((coord) => LatLng(coord[1].toDouble(), coord[0].toDouble())).toList();
      }
    } catch (e) {
      debugPrint('Error request rute: $e');
    }
    return [start, end];
  }

  // 4. Get Current Location (GPS) - UPDATE PENTING UNTUK WEB
  Future<Position?> _determinePosition(BuildContext context) async {
    bool serviceEnabled;
    LocationPermission permission;

    // Cek GPS Aktif
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('GPS tidak aktif. Silakan aktifkan.')));
      }
      return null;
    }

    // Cek Izin
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Izin lokasi ditolak.')));
        }
        return null;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      if (context.mounted) {
        // Pesan khusus jika diblokir browser (supaya user tahu cara resetnya)
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Izin lokasi diblokir Browser. Klik ikon "i" atau gembok di sebelah URL (localhost) untuk mengizinkan.'),
          duration: Duration(seconds: 5),
        ));
      }
      return null;
    }

    // Ambil Posisi (Disesuaikan Web vs HP)
    try {
      return await Geolocator.getCurrentPosition(
        // JIKA WEB: Pakai Medium (Biar Browser tidak menolak karena tidak ada chip GPS)
        // JIKA HP: Pakai High (Biar akurat)
        desiredAccuracy: kIsWeb ? LocationAccuracy.medium : LocationAccuracy.high, 
        timeLimit: const Duration(seconds: 10), 
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Gagal mendapatkan lokasi. Pastikan Wi-Fi aktif.')));
      }
      return null;
    }
  }

  // ================= UI BUILD =================

  @override
  Widget build(BuildContext context) {
    final cctvProvider = Provider.of<CCTVDataSource>(context);
    final List<CCTV> cctvList = cctvProvider.cctvList;

    // Hitung Data Ringkasan (Simulasi)
    int calculatedTotalVehicles = cctvList.length * 2540;
    
    double totalCongestionVal = 0;
    int dataCount = 0;
    _cctvCongestionData.forEach((key, val) {
      totalCongestionVal += (val['Hari Ini'] ?? 0);
      dataCount++;
    });
    int avgCongestion = dataCount > 0 ? ((totalCongestionVal / dataCount) * 100).toInt() : 65;

    int offlineCctvCount = cctvList.where((c) => c.status.toLowerCase() == 'offline').length;
    int totalWarnings = _earlyWarningMessages.length + offlineCctvCount;

    final numberFormat = NumberFormat("#,##0", "id_ID");

    // Generate Marker CCTV
    final List<Marker> cctvMarkers = cctvList.map((cctv) {
      bool isOnline = cctv.status.toLowerCase() == 'online' || cctv.status.toLowerCase() == 'aktif';
      return Marker(
        point: LatLng(cctv.latitude, cctv.longitude),
        width: 60,
        height: 60,
        child: GestureDetector(
          onTap: () {
            Navigator.push(context, MaterialPageRoute(builder: (context) => LiveCCTVScreen(initialCCTVId: cctv.id)));
          },
          child: Column(
            children: [
              Icon(Icons.location_on, size: 40, color: isOnline ? Colors.green : Colors.red),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(4)),
                child: Text(
                  cctv.name, 
                  style: const TextStyle(color: Colors.white, fontSize: 8), 
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
            ],
          ),
        ),
      );
    }).toList();

    final allMarkers = [...cctvMarkers, ..._routeMarkers];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.chat_bubble_outline),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ChatScreen())),
          ),
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_none),
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => NotificationScreen(initialNotifications: _earlyWarningMessages))),
              ),
              if (totalWarnings > 0)
                Positioned(
                  right: 11, top: 11,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(6)),
                    constraints: const BoxConstraints(minWidth: 12, minHeight: 12),
                    child: Text('$totalWarnings', style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                  ),
                )
            ],
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Ringkasan Data
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                SummaryCard(title: 'Total Kendaraan', value: numberFormat.format(calculatedTotalVehicles), valueColor: Colors.green, icon: Icons.directions_car),
                SummaryCard(title: 'Kepadatan Rata2', value: '$avgCongestion%', valueColor: Colors.orange, icon: Icons.traffic),
                SummaryCard(title: 'Peringatan', value: '$totalWarnings', valueColor: Colors.red, icon: Icons.warning),
              ],
            ),
            const SizedBox(height: 24),
            
            // 2. Peta Interaktif
            _buildMapSection(context, allMarkers),
            const SizedBox(height: 24),
            
            // 3. Live Feed CCTV
            _buildLiveFeedList(context, cctvList),
            const SizedBox(height: 24),
            
            // 4. Grafik Kepadatan
            _buildCongestionTrendChartsPerCCTV(context, cctvList),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Peta Lalu Lintas Interaktif', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                const Icon(Icons.map, color: Colors.blueAccent),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              height: 300,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white12),
              ),
              clipBehavior: Clip.antiAlias,
              child: FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: _initialCenter,
                  initialZoom: _initialZoom,
                  minZoom: 4,
                  maxZoom: 18,
                ),
                children: [
                  TileLayer(
                    urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.smarttraffic.app',
                  ),
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
                label: const Text('Rute & Hindari Macet', style: TextStyle(fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                  elevation: 5,
                  shape: const StadiumBorder(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLiveFeedList(BuildContext context, List<CCTV> cctvList) {
    return Card(
      color: Theme.of(context).cardColor,
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Live Feed CCTV Utama', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                const Icon(Icons.videocam_outlined, color: Colors.redAccent),
              ],
            ),
            const SizedBox(height: 12),
            cctvList.isEmpty
                ? const Padding(padding: EdgeInsets.all(20), child: Center(child: Text("Belum ada kamera di Manajemen Kamera")))
                : SizedBox(
                    height: 140,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: cctvList.length,
                      itemBuilder: (context, index) {
                        final cctv = cctvList[index];
                        String? videoId = YoutubePlayer.convertUrlToId(cctv.rstpUrl);
                        String thumbnailUrl = videoId != null
                            ? 'https://img.youtube.com/vi/$videoId/mqdefault.jpg'
                            : 'https://via.placeholder.com/150/000000/FFFFFF?text=${Uri.encodeComponent(cctv.name)}';

                        return Container(
                          width: 180,
                          margin: const EdgeInsets.only(right: 12),
                          child: CCTVCFeedThumbnail(
                            cctvId: cctv.id,
                            location: cctv.location,
                            imageUrl: thumbnailUrl,
                            congestionLevel: cctv.status.toLowerCase() == 'online' ? 'Aktif' : 'Offline',
                            onTap: () {
                              Navigator.push(context, MaterialPageRoute(builder: (context) => LiveCCTVScreen(initialCCTVId: cctv.id)));
                            },
                          ),
                        );
                      },
                    ),
                  ),
          ],
        ),
      ),
    );
  }

  Widget _buildCongestionTrendChartsPerCCTV(BuildContext context, List<CCTV> cctvList) {
    return Card(
      color: Theme.of(context).cardColor,
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Tren Kepadatan per CCTV', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                const Icon(Icons.bar_chart, color: Colors.orangeAccent),
              ],
            ),
            const SizedBox(height: 12),
            cctvList.isEmpty
                ? const SizedBox(height: 50, child: Center(child: Text("-")))
                : SizedBox(
                    height: 220,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: cctvList.length,
                      itemBuilder: (context, index) {
                        final cctv = cctvList[index];
                        final congestionData = _cctvCongestionData[cctv.id] ?? {
                          'Hari Ini': 0.5, 'Minggu Ini': 0.6, 'Bulan Ini': 0.55
                        };
                        
                        return Container(
                          width: 280,
                          margin: const EdgeInsets.only(right: 16.0),
                          padding: const EdgeInsets.all(12.0),
                          decoration: BoxDecoration(
                            color: Theme.of(context).scaffoldBackgroundColor,
                            borderRadius: BorderRadius.circular(12.0),
                            border: Border.all(color: Colors.white10),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(cctv.name, style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
                              Text(cctv.location, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.white54)),
                              const SizedBox(height: 12),
                              Expanded(
                                child: BarChart(
                                  BarChartData(
                                    barGroups: createBarGroups(congestionData),
                                    titlesData: buildAxesTitles(),
                                    borderData: FlBorderData(show: false),
                                    gridData: FlGridData(show: true, drawVerticalLine: false, horizontalInterval: 0.25, getDrawingHorizontalLine: (v) => FlLine(color: Colors.white10, strokeWidth: 1)),
                                    alignment: BarChartAlignment.spaceAround,
                                    maxY: 1.0,
                                    barTouchData: BarTouchData(
                                      touchTooltipData: BarTouchTooltipData(
                                        getTooltipColor: (_) => Colors.blueGrey,
                                        getTooltipItem: (group, groupIndex, rod, rodIndex) => BarTooltipItem('${(rod.toY * 100).toInt()}%', const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
          ],
        ),
      ),
    );
  }

  // --- POPUP ROUTE PLANNER (DENGAN GPS FIX) ---
  Future<void> _showRoutePlanningDialog(BuildContext context) async {
    TextEditingController startController = TextEditingController();
    TextEditingController destinationController = TextEditingController();
    bool isLoadingLocation = false;
    LatLng? cachedGpsLocation; 

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: const Row(children: [Icon(Icons.directions, color: Colors.blueAccent), SizedBox(width: 10), Text('Rencanakan Rute')]),
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
                            ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                            : const Icon(Icons.gps_fixed, color: Colors.blueAccent),
                        tooltip: "Gunakan Lokasi Saat Ini",
                        onPressed: isLoadingLocation ? null : () async {
                          setStateDialog(() => isLoadingLocation = true);
                          
                          // PANGGIL FUNGSI GPS YANG SUDAH DIPERBAIKI
                          Position? pos = await _determinePosition(context);
                          
                          if (pos != null) {
                            cachedGpsLocation = LatLng(pos.latitude, pos.longitude);
                            String? address = await getAddressFromCoordinates(pos.latitude, pos.longitude);
                            if (address != null) {
                              startController.text = address; 
                            } else {
                              startController.text = "${pos.latitude}, ${pos.longitude}";
                            }
                          }
                          
                          setStateDialog(() => isLoadingLocation = false);
                        },
                      ),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: destinationController,
                    decoration: InputDecoration(
                      labelText: 'Lokasi Tujuan', 
                      hintText: 'Cari lokasi tujuan...', 
                      prefixIcon: const Icon(Icons.location_on, color: Colors.redAccent),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal', style: TextStyle(color: Colors.grey))),
                ElevatedButton(
                  onPressed: () async {
                    String startName = startController.text;
                    String destName = destinationController.text;
                    Navigator.pop(context);

                    if (startName.isEmpty || destName.isEmpty) return;

                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Mencari rute...')));

                    LatLng? startCoord;
                    startCoord = await getCoordinatesFromNominatim(startName);

                    if (startCoord == null && cachedGpsLocation != null) {
                      debugPrint("Teks tidak ditemukan, menggunakan fallback GPS");
                      startCoord = cachedGpsLocation;
                    }

                    LatLng? destCoord = await getCoordinatesFromNominatim(destName);

                    if (startCoord != null && destCoord != null) {
                      List<LatLng> routePoints = await getRoutePoints(startCoord, destCoord);
                      setState(() {
                        _routeLines = [Polyline(points: routePoints, strokeWidth: 5.0, color: Colors.blueAccent)];
                        _routeMarkers = [
                           Marker(point: startCoord!, width: 80, height: 80, child: const Icon(Icons.trip_origin, color: Colors.blue, size: 40)),
                           Marker(point: destCoord, width: 80, height: 80, child: const Icon(Icons.flag, color: Colors.red, size: 40)),
                        ];
                      });
                      double centerLat = (startCoord.latitude + destCoord.latitude) / 2;
                      double centerLon = (startCoord.longitude + destCoord.longitude) / 2;
                      _mapController.move(LatLng(centerLat, centerLon), 9.0);
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Lokasi tidak ditemukan.'), backgroundColor: Colors.red));
                    }
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent),
                  child: const Text('Cari Rute', style: TextStyle(color: Colors.white)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // --- CHART HELPERS ---
  List<BarChartGroupData> createBarGroups(Map<String, double> data) {
    const barWidth = 18.0;
    final Map<String, int> xValues = {'Hari Ini': 0, 'Minggu Ini': 1, 'Bulan Ini': 2};
    final List<Color> barColors = [Colors.lightBlueAccent, Colors.orangeAccent, Colors.redAccent];

    return data.entries.map((entry) {
      final x = xValues[entry.key] ?? 0;
      return BarChartGroupData(
        x: x,
        barRods: [BarChartRodData(toY: entry.value, color: barColors[x % barColors.length], width: barWidth, borderRadius: const BorderRadius.vertical(top: Radius.circular(6)), backDrawRodData: BackgroundBarChartRodData(show: true, toY: 1, color: Colors.white.withOpacity(0.05)))],
      );
    }).toList();
  }

  FlTitlesData buildAxesTitles() {
    return FlTitlesData(
      show: true,
      bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, getTitlesWidget: (v, m) {
        return SideTitleWidget(axisSide: m.axisSide, space: 6, child: Text(v == 0 ? 'Hari Ini' : v == 1 ? 'Minggu Ini' : 'Bulan Ini', style: const TextStyle(fontSize: 10, color: Colors.white70)));
      })),
      leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 30, getTitlesWidget: (v, m) => Text('${(v * 100).toInt()}%', style: const TextStyle(fontSize: 10, color: Colors.white54)))),
      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
    );
  }
}