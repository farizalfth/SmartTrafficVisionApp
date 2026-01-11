// lib/screens/analytics_screen.dart

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:intl/intl.dart'; // WAJIB: Tambahkan intl di pubspec.yaml jika belum
import 'dart:math';

import 'package:smarttrafficapp/data/cctv_data_source.dart';
import 'package:smarttrafficapp/models/cctv.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  static const String _dbUrl = 'https://smart-traffic-vision-app-default-rtdb.asia-southeast1.firebasedatabase.app/';
  late final DatabaseReference _trafficRef;

  String _selectedPeriod = 'Harian'; 
  String? _selectedCCTVId; 
  
  List<double> _barValues = [];
  List<String> _barLabels = [];
  
  List<double> _pieValues = [0, 0, 0]; 
  List<Map<String, dynamic>> _rankingList = [];
  Map<dynamic, dynamic>? _rawFirebaseData;

  @override
  void initState() {
    super.initState();
    final firebaseApp = Firebase.app();
    final rtdb = FirebaseDatabase.instanceFor(app: firebaseApp, databaseURL: _dbUrl);
    _trafficRef = rtdb.ref('traffic_stats');
    _listenToFirebase();
  }

  void _listenToFirebase() {
    _trafficRef.onValue.listen((event) {
      if (mounted && event.snapshot.value != null) {
        setState(() {
          _rawFirebaseData = event.snapshot.value as Map<dynamic, dynamic>;
          _recalculateData(); 
        });
      }
    });
  }

  // --- LOGIKA UTAMA ---
  void _recalculateData() {
    if (_rawFirebaseData == null) return;

    int sumMobil = 0;
    int sumMotor = 0;
    int sumBusTruk = 0;
    int sumTotalAkumulasi = 0;

    // Peta untuk menyimpan data Harian (Tanggal -> Total)
    Map<String, int> dailyHistoryMap = {}; 

    List<Map<String, dynamic>> tempList = [];
    final cctvProvider = Provider.of<CCTVDataSource>(context, listen: false);

    _rawFirebaseData!.forEach((key, value) {
      String id = key.toString();
      if (_selectedCCTVId != null && id != _selectedCCTVId) return;

      // 1. Ambil Data Realtime/Akumulasi (Untuk Pie Chart & Ranking)
      int currentTotal = 0;
      if (value is Map) {
        if (value.containsKey('live') && value['live'] is Map) {
          final live = value['live'];
          currentTotal = int.tryParse(live['total_akumulasi']?.toString() ?? '0') ?? 
                         int.tryParse(live['total']?.toString() ?? '0') ?? 0;

          if (live.containsKey('detail')) {
            final detail = live['detail'];
            sumMobil += int.tryParse(detail['mobil']?.toString() ?? '0') ?? 0;
            sumMotor += int.tryParse(detail['motor']?.toString() ?? '0') ?? 0;
            sumBusTruk += (int.tryParse(detail['bus']?.toString() ?? '0') ?? 0) + 
                          (int.tryParse(detail['truk']?.toString() ?? '0') ?? 0);
          }
        }
        
        // 2. AMBIL DATA HISTORY (Untuk Grafik Mingguan/Bulanan)
        // Struktur: ID -> daily_reports -> "2026-01-10": {...}
        if (value.containsKey('daily_reports') && value['daily_reports'] is Map) {
          final reports = value['daily_reports'] as Map;
          reports.forEach((dateKey, dateValue) {
            int dailyTotal = 0;
            if (dateValue is Map) {
              dailyTotal = int.tryParse(dateValue['total']?.toString() ?? '0') ?? 0;
            } else {
              dailyTotal = int.tryParse(dateValue.toString()) ?? 0;
            }

            // Gabungkan jika mode Global (banyak CCTV), atau set jika Spesifik
            if (dailyHistoryMap.containsKey(dateKey)) {
              dailyHistoryMap[dateKey] = dailyHistoryMap[dateKey]! + dailyTotal;
            } else {
              dailyHistoryMap[dateKey] = dailyTotal;
            }
          });
        }
      }
      
      sumTotalAkumulasi += currentTotal;

      // Ranking Data
      String name = "CCTV $id";
      try {
        final cctv = cctvProvider.cctvList.firstWhere((c) => c.id == id || c.id.endsWith(id));
        name = cctv.name;
      } catch (e) { /* ignore */ }

      if (_selectedCCTVId == null) {
         tempList.add({'id': id, 'name': name, 'total': currentTotal});
      }
    });

    // --- UPDATE UI ---
    setState(() {
      // 1. Pie Chart
      double totalPie = (sumMobil + sumMotor + sumBusTruk).toDouble();
      if (totalPie == 0 && sumTotalAkumulasi > 0) totalPie = sumTotalAkumulasi.toDouble(); // Fallback
      if (totalPie == 0) totalPie = 1;

      _pieValues = [
        (sumMobil / totalPie) * 100,
        (sumMotor / totalPie) * 100,
        (sumBusTruk / totalPie) * 100,
      ];

      // 2. Ranking
      if (_selectedCCTVId == null) {
        tempList.sort((a, b) => (b['total'] as int).compareTo(a['total'] as int));
        _rankingList = tempList.take(3).toList();
      } else {
        _rankingList = [];
      }

      // 3. UPDATE GRAFIK (LOGIKA REAL HISTORY)
      _generateChartData(sumTotalAkumulasi, dailyHistoryMap);
    });
  }

  void _generateChartData(int currentTotal, Map<String, int> historyMap) {
    DateTime now = DateTime.now();
    DateFormat formatter = DateFormat('yyyy-MM-dd'); // Format Key Firebase

    if (_selectedPeriod == 'Harian') {
      // Tampilkan Jam (Simulasi Pola dari Total Hari Ini)
      // Karena firebase Anda belum simpan data per-jam
      _barLabels = ['06:00', '09:00', '12:00', '15:00', '18:00', '21:00'];
      double scale = currentTotal > 0 ? currentTotal.toDouble() : 10;
      _barValues = [scale*0.1, scale*0.4, scale*0.8, scale*0.5, scale*0.9, scale*0.6];
    } 
    
    // --- LOGIKA MINGGUAN (DATA REAL 7 HARI) ---
    else if (_selectedPeriod == 'Mingguan') {
      List<String> labels = [];
      List<double> values = [];

      // Loop 7 hari ke belakang (H-6 sampai Hari Ini)
      for (int i = 6; i >= 0; i--) {
        DateTime d = now.subtract(Duration(days: i));
        String dateKey = formatter.format(d); // "2026-01-11"
        
        // Label Sumbu X (Sen, Sel, Rab...)
        labels.add(DateFormat('E', 'id_ID').format(d)); 

        // Ambil Data dari Map History
        // Jika hari ini, ambil nilai akumulasi terbaru (lebih akurat)
        if (i == 0) {
           values.add(currentTotal.toDouble());
        } else {
           // Ambil dari historyMap, jika tidak ada = 0
           values.add((historyMap[dateKey] ?? 0).toDouble());
        }
      }
      _barLabels = labels;
      _barValues = values;
    } 
    
    // --- LOGIKA BULANAN ---
    else {
       // Simulasi Bulanan (Karena butuh data 30 hari)
       // Menggunakan data minggu ini sebagai patokan
       _barLabels = ['Mgg 1', 'Mgg 2', 'Mgg 3', 'Mgg 4'];
       double val = currentTotal.toDouble();
       _barValues = [val * 3, val * 3.5, val * 4, val * 4.2];
    }
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
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildFilterSection(allCCTV),
            const SizedBox(height: 24),
            
            // Grafik Tren
            _buildDensityChartCard(),
            const SizedBox(height: 24),

            // Distribusi
            _buildVehicleDistributionCard(),
            const SizedBox(height: 24),
            
            // Peringkat (Global Only)
            if (_selectedCCTVId == null) _buildRankingCard(),
            
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // --- WIDGET HELPER SAMA SEPERTI SEBELUMNYA ---
  
  Widget _buildFilterSection(List<CCTV> cctvList) {
    return Card(
      color: Theme.of(context).cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Pilih Sumber Data (Kosong = Global)", style: TextStyle(color: Colors.grey, fontSize: 12)),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.only(left: 12, right: 4), 
              decoration: BoxDecoration(color: Colors.black26, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.white12)),
              child: Row(
                children: [
                  Expanded(
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedCCTVId,
                        isExpanded: true,
                        dropdownColor: const Color(0xFF2C2C2C),
                        icon: const SizedBox.shrink(), 
                        hint: const Text("Semua CCTV (Global)", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        items: cctvList.map((cctv) {
                          return DropdownMenuItem(
                            value: cctv.id,
                            child: Text(cctv.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
                          );
                        }).toList(),
                        onChanged: (val) {
                          setState(() {
                            _selectedCCTVId = val;
                            _recalculateData(); 
                          });
                        },
                      ),
                    ),
                  ),
                  if (_selectedCCTVId != null)
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.redAccent, size: 20),
                      onPressed: () {
                        setState(() {
                          _selectedCCTVId = null;
                          _recalculateData();
                        });
                      },
                    )
                  else
                    const Padding(padding: EdgeInsets.symmetric(horizontal: 12.0), child: Icon(Icons.keyboard_arrow_down, color: Colors.blueAccent)),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Container(
              height: 40,
              decoration: BoxDecoration(color: Colors.black26, borderRadius: BorderRadius.circular(10)),
              child: Row(
                children: ['Harian', 'Mingguan', 'Bulanan'].map((period) {
                  final isSelected = _selectedPeriod == period;
                  return Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() {
                          _selectedPeriod = period;
                          if(_rawFirebaseData != null) _recalculateData(); 
                        }),
                      child: Container(
                        decoration: BoxDecoration(color: isSelected ? Colors.blueAccent : Colors.transparent, borderRadius: BorderRadius.circular(10)),
                        alignment: Alignment.center,
                        child: Text(period, style: TextStyle(color: isSelected ? Colors.white : Colors.grey, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal, fontSize: 12)),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDensityChartCard() {
    double maxValue = _barValues.isEmpty ? 10 : _barValues.reduce(max);
    double yAxisMax = (maxValue < 10) ? 10 : maxValue * 1.2;

    return Card(
      color: Theme.of(context).cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Tren Akumulasi ($_selectedPeriod)', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                const Icon(Icons.bar_chart, color: Colors.blueAccent),
              ],
            ),
            const SizedBox(height: 30),
            AspectRatio(
              aspectRatio: 1.5,
              child: BarChart(
                BarChartData(
                  maxY: yAxisMax,
                  barGroups: List.generate(_barValues.length, (index) {
                    return BarChartGroupData(
                      x: index,
                      barRods: [
                        BarChartRodData(
                          toY: _barValues[index],
                          gradient: const LinearGradient(colors: [Colors.blueAccent, Colors.lightBlueAccent], begin: Alignment.bottomCenter, end: Alignment.topCenter),
                          width: _selectedPeriod == 'Mingguan' ? 16 : 22,
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                          backDrawRodData: BackgroundBarChartRodData(show: true, toY: yAxisMax, color: Colors.white.withOpacity(0.05)),
                        ),
                      ],
                    );
                  }),
                  gridData: FlGridData(show: true, drawVerticalLine: false, horizontalInterval: yAxisMax / 5, getDrawingHorizontalLine: (v) => FlLine(color: Colors.white10, strokeWidth: 1)),
                  borderData: FlBorderData(show: false),
                  titlesData: FlTitlesData(
                    show: true,
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 40, getTitlesWidget: (val, meta) => Text(val.toInt().toString(), style: const TextStyle(color: Colors.grey, fontSize: 10)))),
                    bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 30, getTitlesWidget: (val, meta) {
                      if (val.toInt() < _barLabels.length) {
                        return Padding(padding: const EdgeInsets.only(top: 8.0), child: Text(_barLabels[val.toInt()], style: const TextStyle(color: Colors.white70, fontSize: 10)));
                      }
                      return const Text('');
                    })),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVehicleDistributionCard() {
    double mobilVal = _pieValues.isNotEmpty ? _pieValues[0] : 0;
    double motorVal = _pieValues.length > 1 ? _pieValues[1] : 0;
    double busTrukVal = _pieValues.length > 2 ? _pieValues[2] : 0;

    if (mobilVal == 0 && motorVal == 0 && busTrukVal == 0) {
      return Card(
         color: Theme.of(context).cardColor,
         child: const Padding(
           padding: EdgeInsets.all(20),
           child: Center(child: Text("Data komposisi belum tersedia", style: TextStyle(color: Colors.grey))),
         ),
      );
    }

    return Card(
      color: Theme.of(context).cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Komposisi Kendaraan', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white)),
                const Icon(Icons.pie_chart, color: Colors.orangeAccent),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                SizedBox(
                  height: 140, width: 140,
                  child: PieChart(
                    PieChartData(
                      sectionsSpace: 2, centerSpaceRadius: 30,
                      sections: [
                        PieChartSectionData(color: Colors.blueAccent, value: mobilVal, title: '${mobilVal.toInt()}%', radius: 40, titleStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white)),
                        PieChartSectionData(color: Colors.orangeAccent, value: motorVal, title: '${motorVal.toInt()}%', radius: 35, titleStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white)),
                        PieChartSectionData(color: Colors.redAccent, value: busTrukVal, title: '${busTrukVal.toInt()}%', radius: 30, titleStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 24),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildLegendItem(Colors.blueAccent, 'Mobil (${mobilVal.toInt()}%)'),
                      const SizedBox(height: 8),
                      _buildLegendItem(Colors.orangeAccent, 'Motor (${motorVal.toInt()}%)'),
                      const SizedBox(height: 8),
                      _buildLegendItem(Colors.redAccent, 'Bus/Truk (${busTrukVal.toInt()}%)'),
                    ],
                  ),
                )
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendItem(Color color, String label) {
    return Row(children: [Container(width: 12, height: 12, decoration: BoxDecoration(color: color, shape: BoxShape.circle)), const SizedBox(width: 8), Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12))]);
  }

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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Peringkat Kepadatan (Top 3)', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                const Icon(Icons.emoji_events, color: Colors.amber),
              ],
            ),
            const SizedBox(height: 16),
            
            if (_rankingList.isEmpty)
              const Center(child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Text("Menunggu data...", style: TextStyle(color: Colors.grey)),
              ))
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _rankingList.length,
                separatorBuilder: (context, index) => const Divider(color: Colors.white10),
                itemBuilder: (context, index) {
                  final data = _rankingList[index];
                  int total = data['total'];
                  int maxTotal = _rankingList[0]['total'];
                  int percent = maxTotal > 0 ? ((total / maxTotal) * 100).toInt() : 0;

                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Row(
                      children: [
                        Container(
                          width: 32, height: 32,
                          decoration: BoxDecoration(
                            color: index == 0 ? Colors.red.withOpacity(0.2) : Colors.transparent,
                            shape: BoxShape.circle,
                            border: Border.all(color: index == 0 ? Colors.redAccent : (index == 1 ? Colors.orange : Colors.grey), width: 2),
                          ),
                          child: Center(child: Text('${index + 1}', style: TextStyle(fontWeight: FontWeight.bold, color: index == 0 ? Colors.redAccent : (index == 1 ? Colors.orange : Colors.grey)))),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(data['name'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white), maxLines: 1, overflow: TextOverflow.ellipsis),
                              Text("Akumulasi: $total", style: const TextStyle(color: Colors.grey, fontSize: 11)),
                            ],
                          ),
                        ),
                        Text('$percent%', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: percent > 80 ? Colors.redAccent : Colors.orangeAccent)),
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