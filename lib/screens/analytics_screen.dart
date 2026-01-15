// lib/screens/analytics_screen.dart

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:intl/intl.dart';
import 'dart:math';

import 'package:smarttrafficapp/data/cctv_data_source.dart';
import 'package:smarttrafficapp/models/cctv.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  // --- KONEKSI FIREBASE ---
  static const String _dbUrl =
      'https://smart-traffic-vision-app-default-rtdb.asia-southeast1.firebasedatabase.app/';
  late final DatabaseReference _trafficRef;

  // State UI
  String? _selectedCCTVId;

  // Data Chart
  List<BarChartGroupData> _chartGroups = [];
  List<String> _dateLabels = [];
  double _maxY = 100;

  // Data Peringkat
  List<Map<String, dynamic>> _rankingList = [];

  // Cache Data Mentah
  dynamic _rawFirebaseData; // Ubah jadi dynamic agar bisa handle List/Map

  @override
  void initState() {
    super.initState();
    final firebaseApp = Firebase.app();
    final rtdb =
        FirebaseDatabase.instanceFor(app: firebaseApp, databaseURL: _dbUrl);
    _trafficRef = rtdb.ref('traffic_stats');

    _listenToFirebase();
  }

  void _listenToFirebase() {
    _trafficRef.onValue.listen((event) {
      if (mounted && event.snapshot.value != null) {
        setState(() {
          _rawFirebaseData = event.snapshot.value;
          _processData();
        });
      }
    });
  }

  // --- LOGIKA UTAMA: MEMBACA 'daily_reports' DENGAN DEBUGGING ---
  void _processData() {
    if (_rawFirebaseData == null) return;

    // Debugging: Cek ID yang dipilih
    print("---------------- ANALISA DATA ----------------");
    print("ID Terpilih di Dropdown: $_selectedCCTVId");

    Map<String, int> dailyTotals = {};
    List<Map<String, dynamic>> rankingTemp = [];
    final cctvProvider = Provider.of<CCTVDataSource>(context, listen: false);

    // Fungsi Helper untuk memproses setiap Node CCTV
    void processCCTVNode(String key, dynamic value) {
      String idFirebase = key.toString();

      // LOGIKA PENCOCOKAN ID (SMART MATCHING)
      // Mencocokkan "3" dengan "3" atau "cctv_03" dengan "3"
      bool isSelected = false;
      if (_selectedCCTVId == null) {
        isSelected = true; // Global mode
      } else {
        String id1 = _selectedCCTVId!
            .replaceAll(RegExp(r'[^0-9]'), ''); // Ambil angkanya saja
        String id2 = idFirebase.replaceAll(RegExp(r'[^0-9]'), '');
        // Cocokkan jika angkanya sama (misal '3' == '03')
        if (int.tryParse(id1) == int.tryParse(id2)) {
          isSelected = true;
        }
      }

      if (value is Map) {
        // --- 1. AMBIL DATA HARIAN (daily_reports) ---
        if (isSelected && value.containsKey('daily_reports')) {
          print(">> Menemukan daily_reports untuk ID: $idFirebase");
          final reports = value['daily_reports'];

          if (reports is Map) {
            reports.forEach((dateKey, reportData) {
              int total = 0;
              if (reportData is Map) {
                total = int.tryParse(
                        reportData['total_hari_ini']?.toString() ?? '0') ??
                    0;
              } else {
                // Kadang struktur bisa langsung angka
                total = int.tryParse(reportData.toString()) ?? 0;
              }

              // Tambahkan ke Map Total
              if (dailyTotals.containsKey(dateKey)) {
                dailyTotals[dateKey] = dailyTotals[dateKey]! + total;
              } else {
                dailyTotals[dateKey] = total;
              }
            });
          }
          // Handle jika Firebase menganggapnya List (jarang untuk tanggal, tapi jaga-jaga)
          else if (reports is List) {
            // Skip list logic for dates usually
          }
        }
        // JIKA TIDAK ADA DAILY REPORTS, DUMMY DARI LIVE (Agar grafik tidak kosong)
        else if (isSelected && value.containsKey('live')) {
          // Ambil total hari ini dari live
          int liveTotal = 0;
          if (value['live'] is Map &&
              value['live']['total_akumulasi_hari_ini'] != null) {
            liveTotal = int.tryParse(
                    value['live']['total_akumulasi_hari_ini'].toString()) ??
                0;
          }

          // Masukkan sebagai data hari ini
          String todayKey = DateFormat('yyyy-MM-dd').format(DateTime.now());
          if (liveTotal > 0) {
            dailyTotals[todayKey] = (dailyTotals[todayKey] ?? 0) + liveTotal;
          }
        }

        // --- 2. AMBIL DATA PERINGKAT (GLOBAL ONLY) ---
        if (_selectedCCTVId == null) {
          int currentTotal = 0;
          if (value.containsKey('live') && value['live'] is Map) {
            // Prioritas total_akumulasi_hari_ini
            if (value['live']['total_akumulasi_hari_ini'] != null) {
              currentTotal = int.tryParse(
                      value['live']['total_akumulasi_hari_ini'].toString()) ??
                  0;
            } else {
              currentTotal =
                  int.tryParse(value['live']['total']?.toString() ?? '0') ?? 0;
            }
          }

          String name = "CCTV $idFirebase";
          try {
            final cctv = cctvProvider.cctvList.firstWhere((c) {
              // Pencocokan nama fleksibel
              String cid = c.id.replaceAll(RegExp(r'[^0-9]'), '');
              String fid = idFirebase.replaceAll(RegExp(r'[^0-9]'), '');
              return int.tryParse(cid) == int.tryParse(fid);
            });
            name = cctv.name;
          } catch (e) {/* ignore */}

          if (currentTotal > 0) {
            rankingTemp.add({'name': name, 'total': currentTotal});
          }
        }
      }
    }

    // Loop data utama (Bisa Map atau List tergantung ID di Firebase)
    if (_rawFirebaseData is Map) {
      _rawFirebaseData
          .forEach((key, value) => processCCTVNode(key.toString(), value));
    } else if (_rawFirebaseData is List) {
      for (int i = 0; i < _rawFirebaseData.length; i++) {
        if (_rawFirebaseData[i] != null) {
          processCCTVNode(i.toString(), _rawFirebaseData[i]);
        }
      }
    }

    print(">> Data Harian Terkumpul: $dailyTotals");

    // --- FINALISASI DATA CHART ---
    var sortedKeys = dailyTotals.keys.toList()..sort();

    // Batasi 7 hari terakhir
    if (sortedKeys.length > 7) {
      sortedKeys = sortedKeys.sublist(sortedKeys.length - 7);
    }

    List<BarChartGroupData> groups = [];
    List<String> labels = [];
    double maxVal = 0;

    for (int i = 0; i < sortedKeys.length; i++) {
      String dateKey = sortedKeys[i];
      double val = dailyTotals[dateKey]!.toDouble();

      if (val > maxVal) maxVal = val;

      try {
        DateTime dt = DateTime.parse(dateKey);
        labels.add(DateFormat('d MMM', 'id_ID').format(dt));
      } catch (e) {
        labels.add(dateKey.substring(5));
      }

      groups.add(
        BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              toY: val,
              gradient: const LinearGradient(
                colors: [Colors.blueAccent, Colors.lightBlueAccent],
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
              ),
              width: 16,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(4)),
              backDrawRodData: BackgroundBarChartRodData(
                  show: true,
                  toY: (maxVal * 1.2 == 0 ? 10 : maxVal * 1.2),
                  color: Colors.white.withOpacity(0.05)),
            ),
          ],
        ),
      );
    }

    rankingTemp
        .sort((a, b) => (b['total'] as int).compareTo(a['total'] as int));

    setState(() {
      _chartGroups = groups;
      _dateLabels = labels;
      _maxY = maxVal > 0 ? maxVal * 1.2 : 10;
      if (_selectedCCTVId == null) {
        _rankingList = rankingTemp.take(5).toList();
      } else {
        _rankingList = [];
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final cctvProvider = Provider.of<CCTVDataSource>(context);
    final List<CCTV> allCCTV = cctvProvider.cctvList;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Statistik & Analitik'),
        centerTitle: true,
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildFilterSection(allCCTV),
            const SizedBox(height: 24),

            _buildHistoryChart(), // CHART HARIAN (DARI DAILY REPORTS)

            const SizedBox(height: 24),

            if (_selectedCCTVId == null) _buildRankingCard(),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // --- WIDGET FILTER ---
  Widget _buildFilterSection(List<CCTV> cctvList) {
    return Card(
      color: Theme.of(context).cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Pilih Sumber Data (Kosong = Global)",
                style: TextStyle(color: Colors.grey, fontSize: 12)),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.only(left: 12, right: 4),
              decoration: BoxDecoration(
                  color: Colors.black26,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white12)),
              child: Row(
                children: [
                  Expanded(
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedCCTVId,
                        isExpanded: true,
                        dropdownColor: const Color(0xFF2C2C2C),
                        icon: const SizedBox.shrink(),
                        hint: const Text("Semua CCTV (Global)",
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold)),
                        items: cctvList.map((cctv) {
                          return DropdownMenuItem(
                            value: cctv.id,
                            child: Text(cctv.name,
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold),
                                overflow: TextOverflow.ellipsis),
                          );
                        }).toList(),
                        onChanged: (val) {
                          setState(() {
                            _selectedCCTVId = val;
                            _processData();
                          });
                        },
                      ),
                    ),
                  ),
                  if (_selectedCCTVId != null)
                    IconButton(
                      icon: const Icon(Icons.close,
                          color: Colors.redAccent, size: 20),
                      onPressed: () {
                        setState(() {
                          _selectedCCTVId = null;
                          _processData();
                        });
                      },
                    )
                  else
                    const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 12.0),
                        child: Icon(Icons.keyboard_arrow_down,
                            color: Colors.blueAccent)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  // --- WIDGET CHART (DATA DARI FIREBASE DAILY_REPORTS) ---
  Widget _buildHistoryChart() {
    return Card(
      color: Theme.of(context).cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Tren Volume Harian',
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white)),
                Icon(Icons.bar_chart, color: Colors.blueAccent),
              ],
            ),
            const SizedBox(height: 10),
            const Text("Data berdasarkan 'daily_reports' Firebase",
                style: TextStyle(color: Colors.grey, fontSize: 10)),
            const SizedBox(height: 30),
            if (_chartGroups.isEmpty)
              const SizedBox(
                height: 200,
                child: Center(
                    child: Text("Belum ada riwayat data",
                        style: TextStyle(color: Colors.grey))),
              )
            else
              AspectRatio(
                aspectRatio: 1.3,
                child: BarChart(
                  BarChartData(
                    // 1. TAMBAH HEADROOM: Beri ruang 20% di atas agar angka tertinggi tidak mentok ke atas
                    maxY: _maxY * 1.2,
                    barGroups: _chartGroups,
                    gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        // Buat interval grid yang konsisten
                        horizontalInterval: _maxY > 0 ? (_maxY / 5) : 1000,
                        getDrawingHorizontalLine: (v) =>
                            FlLine(color: Colors.white10, strokeWidth: 1)),
                    borderData: FlBorderData(show: false),
                    titlesData: FlTitlesData(
                      show: true,
                      rightTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false)),
                      topTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false)),
                      leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 45, // Ukuran kolom angka kiri
                              getTitlesWidget: (val, meta) {
                                // 2. HILANGKAN LOGIKA REAL-TIME: Sekarang hanya menampilkan label Grid
                                if (val == meta.max)
                                  return const SizedBox(); // Jangan gambar di paling atas agar tidak tumpuk

                                String text = '';
                                if (val >= 1000) {
                                  text = '${(val / 1000).toStringAsFixed(0)}k';
                                } else {
                                  text = val.toInt().toString();
                                }

                                return SideTitleWidget(
                                  axisSide: meta.axisSide,
                                  space: 10,
                                  child: Text(
                                    text,
                                    style: const TextStyle(
                                      color: Colors
                                          .grey, // Semua angka sekarang seragam Abu-abu
                                      fontSize: 10,
                                    ),
                                  ),
                                );
                              })),
                      bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 30,
                              getTitlesWidget: (val, meta) {
                                if (val.toInt() >= 0 &&
                                    val.toInt() < _dateLabels.length) {
                                  return SideTitleWidget(
                                    axisSide: meta.axisSide,
                                    space: 8,
                                    child: Text(_dateLabels[val.toInt()],
                                        style: const TextStyle(
                                            color: Colors.white70,
                                            fontSize: 10)),
                                  );
                                }
                                return const SizedBox();
                              })),
                    ),
                    barTouchData: BarTouchData(
                      touchTooltipData: BarTouchTooltipData(
                        getTooltipColor: (_) =>
                            Colors.blueGrey.withOpacity(0.9),
                        getTooltipItem: (group, groupIndex, rod, rodIndex) {
                          String date = _dateLabels[group.x.toInt()];
                          return BarTooltipItem(
                            '$date\n',
                            const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 12),
                            children: <TextSpan>[
                              TextSpan(
                                text: NumberFormat.decimalPattern('id_ID')
                                    .format(rod.toY.toInt()),
                                style: const TextStyle(
                                    color: Colors.blueAccent,
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // --- WIDGET PERINGKAT ---
  Widget _buildRankingCard() {
    return Card(
      color: Theme.of(context).cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- PERBAIKAN HEADER: Menggunakan Expanded agar tidak overflow ---
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Volume CCTV Tertinggi (Hari Ini)',
                    style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white),
                    maxLines: 1,
                    overflow: TextOverflow
                        .ellipsis, // Potong teks jika terlalu panjang
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.emoji_events, color: Colors.amber),
              ],
            ),
            const SizedBox(height: 16),
            if (_rankingList.isEmpty)
              const Center(
                  child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Text("Data belum tersedia",
                    style: TextStyle(color: Colors.grey)),
              ))
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _rankingList.length,
                separatorBuilder: (context, index) =>
                    const Divider(color: Colors.white10),
                itemBuilder: (context, index) {
                  final data = _rankingList[index];
                  int total = data['total'];

                  int maxTotal = _rankingList[0]['total'];
                  double relativeWidth = maxTotal > 0 ? (total / maxTotal) : 0;

                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10.0),
                    child: Row(
                      children: [
                        // Lingkaran Angka Peringkat
                        Container(
                          width: 30,
                          height: 30,
                          decoration: BoxDecoration(
                            color: index == 0
                                ? Colors.amber.withOpacity(0.2)
                                : Colors.transparent,
                            shape: BoxShape.circle,
                            border: Border.all(
                                color: index == 0
                                    ? Colors.amber
                                    : Colors.grey.withOpacity(0.5),
                                width: 2),
                          ),
                          child: Center(
                              child: Text('${index + 1}',
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: index == 0
                                          ? Colors.amber
                                          : Colors.grey))),
                        ),
                        const SizedBox(width: 16),
                        // Bagian Nama dan Progress Bar
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(data['name'],
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                      color: Colors.white),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis),
                              const SizedBox(height: 6),
                              Stack(
                                children: [
                                  Container(
                                      height: 6,
                                      width: double.infinity,
                                      decoration: BoxDecoration(
                                          color: Colors.white10,
                                          borderRadius:
                                              BorderRadius.circular(3))),
                                  FractionallySizedBox(
                                    widthFactor: relativeWidth,
                                    child: Container(
                                        height: 6,
                                        decoration: BoxDecoration(
                                            color: Colors.blueAccent,
                                            borderRadius:
                                                BorderRadius.circular(3))),
                                  )
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        // --- PERBAIKAN ANGKA: Menggunakan FittedBox agar angka besar tidak overflow ---
                        SizedBox(
                          width: 60, // Batasi lebar kolom angka
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerRight,
                            child: Text(
                              '$total',
                              style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}
