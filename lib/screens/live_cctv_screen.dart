// lib/screens/live_cctv_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:fl_chart/fl_chart.dart';

import 'package:smarttrafficapp/models/cctv.dart';
import 'package:smarttrafficapp/data/cctv_data_source.dart';

class LiveCCTVScreen extends StatefulWidget {
  final String? initialCCTVId;
  const LiveCCTVScreen({super.key, this.initialCCTVId});

  @override
  State<LiveCCTVScreen> createState() => _LiveCCTVScreenState();
}

// Tambahkan TickerProviderStateMixin untuk animasi
class _LiveCCTVScreenState extends State<LiveCCTVScreen>
    with TickerProviderStateMixin {
  YoutubePlayerController? _controller;
  CCTV? _selectedCCTV;
  bool _isInit = true;

  // Controller untuk animasi rotasi diagram
  late AnimationController _rotationController;

  static const String _dbUrl =
      'https://smart-traffic-vision-app-default-rtdb.asia-southeast1.firebasedatabase.app/';
  late final DatabaseReference _trafficStatsRef;

  @override
  void initState() {
    super.initState();
    final firebaseApp = Firebase.app();
    final rtdb =
        FirebaseDatabase.instanceFor(app: firebaseApp, databaseURL: _dbUrl);
    _trafficStatsRef = rtdb.ref('traffic_stats');

    // Inisialisasi animasi rotasi (berputar penuh setiap 15 detik)
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 15),
    )..repeat(); // Membuatnya berputar terus menerus
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_isInit) {
      final dataProvider = Provider.of<CCTVDataSource>(context, listen: false);
      if (widget.initialCCTVId != null) {
        try {
          final foundCCTV = dataProvider.cctvList
              .firstWhere((c) => c.id == widget.initialCCTVId);
          _initializePlayer(foundCCTV);
        } catch (e) {
          debugPrint("ID CCTV tidak ditemukan");
        }
      }
      _isInit = false;
    }
  }

  // FIX: Logika pindah video agar tidak tertukar
  void _initializePlayer(CCTV cctv) {
    final videoId = YoutubePlayer.convertUrlToId(cctv.rstpUrl);

    if (videoId != null) {
      // WAJIB: Hapus controller lama agar memori bersih dan video benar-benar ganti
      if (_controller != null) {
        _controller!.pause();
        _controller!.dispose();
        _controller = null;
      }

      setState(() {
        _selectedCCTV = cctv;
        _controller = YoutubePlayerController(
          initialVideoId: videoId,
          flags: const YoutubePlayerFlags(
            autoPlay: true,
            mute: false,
            isLive: true,
            forceHD: false,
          ),
        );
      });
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    _rotationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Live CCTV Streaming'),
        backgroundColor: Colors.transparent,
        elevation: 0,

        // --- TAMBAHKAN BAGIAN INI (TOMBOL MENU) ---
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () {
            // Membuka Sidebar/Drawer
            Scaffold.of(context).openDrawer();
          },
        ),
      ),
      body: Consumer<CCTVDataSource>(
        builder: (context, dataSource, child) {
          final allCCTVs = dataSource.cctvList;
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Pilih Lokasi Pemantauan:",
                    style:
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 10),
                _buildDropdownSelector(allCCTVs),
                const SizedBox(height: 24),
                if (_selectedCCTV != null && _controller != null)
                  _buildMainPlayerArea(context, _selectedCCTV!)
                else
                  _buildEmptyState(),
              ],
            ),
          );
        },
      ),
    );
  }

  // FIX: Dropdown agar teks panjang otomatis turun baris (Wrap)
  Widget _buildDropdownSelector(List<CCTV> list) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white24),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<CCTV>(
          isExpanded: true,
          hint: const Text("Sentuh untuk memilih lokasi..."),
          value: _selectedCCTV,
          icon: const Icon(Icons.arrow_drop_down_circle,
              color: Colors.blueAccent),
          // Menggunakan selectedItemBuilder agar teks di baris utama dropdown bisa dibungkus
          selectedItemBuilder: (BuildContext context) {
            return list.map<Widget>((item) {
              return Container(
                alignment: Alignment.centerLeft,
                child: Text(
                  item.name,
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.bold),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              );
            }).toList();
          },
          items: list.map((item) {
            return DropdownMenuItem<CCTV>(
              value: item,
              child: Text(item.name,
                  softWrap: true, style: const TextStyle(fontSize: 14)),
            );
          }).toList(),
          onChanged: (newValue) =>
              newValue != null ? _initializePlayer(newValue) : null,
        ),
      ),
    );
  }

  Widget _buildMainPlayerArea(BuildContext context, CCTV cctv) {
    return Column(
      children: [
        // FIX: Container dengan Unique Key agar video benar-benar di-refresh sistem
        Container(
          key: ValueKey("vid_player_${cctv.id}"),
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(12)),
          clipBehavior: Clip.antiAlias,
          child: AspectRatio(
            aspectRatio: 16 / 9,
            child: YoutubePlayer(
              controller: _controller!,
              showVideoProgressIndicator: true,
              progressIndicatorColor: Colors.redAccent,
            ),
          ),
        ),
        const SizedBox(height: 16),

        StreamBuilder(
          stream: _trafficStatsRef.child(cctv.id).onValue,
          builder: (context, AsyncSnapshot<DatabaseEvent> snapshot) {
            String status = "Lancar";
            String total = "0";
            Map detail = {"mobil": 0, "motor": 0, "bus": 0, "truk": 0};

            if (snapshot.hasData && snapshot.data!.snapshot.value != null) {
              final data = snapshot.data!.snapshot.value as Map;
              final live = data['live'] as Map?;
              if (live != null) {
                status = live['status']?.toString() ?? "Lancar";
                total = live['total_akumulasi_hari_ini']?.toString() ?? "0";
                final d = live['detail'] as Map?;
                if (d != null) detail = d;
              }
            }

            return Column(
              children: [
                _buildStatusCard(cctv, status, total),
                const SizedBox(height: 16),
                _buildDistributionCard(detail),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildStatusCard(CCTV cctv, String status, String total) {
    return Card(
      color: Theme.of(context).cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(cctv.name,
                style:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            Row(children: [
              const Icon(Icons.location_pin, color: Colors.redAccent, size: 16),
              const SizedBox(width: 4),
              Text(cctv.location,
                  style: const TextStyle(color: Colors.white70)),
            ]),
            const Divider(height: 30, color: Colors.white12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildInfoItem("Kondisi Lalu Lintas", status, isStatus: true),
                _buildInfoItem("Total Kendaraan", total),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // FIX: DIAGRAM LINGKARAN DENGAN ANIMASI ROTASI TERUS MENERUS
  Widget _buildDistributionCard(Map data) {
    double vMobil = (data['mobil'] ?? 0).toDouble();
    double vMotor = (data['motor'] ?? 0).toDouble();
    double vBus = (data['bus'] ?? 0).toDouble();
    double vTruk = (data['truk'] ?? 0).toDouble();
    double totalCount = vMobil + vMotor + vBus + vTruk;
    bool hasData = totalCount > 0;

    return Card(
      color: Theme.of(context).cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Distribusi Kendaraan",
                    style: TextStyle(
                        color: Colors.cyanAccent,
                        fontWeight: FontWeight.bold,
                        fontSize: 16)),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                      color: Colors.cyan,
                      borderRadius: BorderRadius.circular(8)),
                  child: const Text("REAL TIME",
                      style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Colors.white)),
                )
              ],
            ),
            const SizedBox(height: 30),

            // Animasi Rotasi Diagram
            SizedBox(
              height: 200,
              child: AnimatedBuilder(
                  animation: _rotationController,
                  builder: (context, child) {
                    return PieChart(
                      PieChartData(
                        // Ini yang membuat diagram berputar terus
                        startDegreeOffset: _rotationController.value * 360,
                        sectionsSpace: 2,
                        centerSpaceRadius: 70,
                        sections: hasData
                            ? [
                                PieChartSectionData(
                                    value: vMobil,
                                    color: Colors.cyanAccent,
                                    radius: 25,
                                    showTitle: false),
                                PieChartSectionData(
                                    value: vMotor,
                                    color: Colors.amber,
                                    radius: 25,
                                    showTitle: false),
                                PieChartSectionData(
                                    value: vBus,
                                    color: Colors.greenAccent,
                                    radius: 25,
                                    showTitle: false),
                                PieChartSectionData(
                                    value: vTruk,
                                    color: Colors.redAccent,
                                    radius: 25,
                                    showTitle: false),
                              ]
                            : [
                                PieChartSectionData(
                                    value: 1,
                                    color: Colors.white10,
                                    radius: 25,
                                    showTitle: false),
                              ],
                      ),
                    );
                  }),
            ),

            const SizedBox(height: 30),
            _buildLegendItem("Mobil", hasData ? (vMobil / totalCount) * 100 : 0,
                Colors.cyanAccent),
            _buildLegendItem("Motor", hasData ? (vMotor / totalCount) * 100 : 0,
                Colors.amber),
            _buildLegendItem("Bus", hasData ? (vBus / totalCount) * 100 : 0,
                Colors.greenAccent),
            _buildLegendItem("Truk", hasData ? (vTruk / totalCount) * 100 : 0,
                Colors.redAccent),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendItem(String label, double percent, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 12),
          Text(label,
              style: const TextStyle(color: Colors.white, fontSize: 14)),
          const Spacer(),
          Text("${percent.toStringAsFixed(1)}%",
              style: const TextStyle(
                  color: Colors.cyanAccent, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildInfoItem(String title, String value, {bool isStatus = false}) {
    Color valColor = Colors.white;
    if (isStatus) {
      if (value.contains("Macet"))
        valColor = Colors.redAccent;
      else if (value.contains("Padat"))
        valColor = Colors.orangeAccent;
      else
        valColor = Colors.greenAccent;
    }
    return Column(
      crossAxisAlignment:
          isStatus ? CrossAxisAlignment.start : CrossAxisAlignment.end,
      children: [
        Text(title, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        Text(value,
            style: TextStyle(
                color: valColor, fontWeight: FontWeight.bold, fontSize: 16)),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Container(
      height: 250,
      width: double.infinity,
      decoration: BoxDecoration(
          color: Colors.black26, borderRadius: BorderRadius.circular(15)),
      child: const Center(
          child: Text("Silakan pilih lokasi CCTV",
              style: TextStyle(color: Colors.white54))),
    );
  }
}
