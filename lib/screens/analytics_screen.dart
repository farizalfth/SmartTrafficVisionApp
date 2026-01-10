// lib/screens/analytics_screen.dart

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
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
  static const String _dbUrl = 'https://smart-traffic-vision-app-default-rtdb.asia-southeast1.firebasedatabase.app/';
  late final DatabaseReference _trafficRef;

  // State UI
  String _selectedPeriod = 'Harian'; 
  String? _selectedCCTVId; 
  
  // Data Chart
  List<double> _barValues = [0, 0, 0, 0, 0, 0];
  List<String> _barLabels = ['06:00', '09:00', '12:00', '15:00', '18:00', '21:00'];
  
  // Data Pie Chart (Mobil, Motor, Bus/Truk)
  List<double> _pieValues = [0, 0, 0]; 

  // Data Peringkat
  List<Map<String, dynamic>> _rankingList = [];

  // Cache Data Mentah
  Map<dynamic, dynamic>? _rawFirebaseData;

  @override
  void initState() {
    super.initState();
    final firebaseApp = Firebase.app();
    final rtdb = FirebaseDatabase.instanceFor(app: firebaseApp, databaseURL: _dbUrl);
    _trafficRef = rtdb.ref('traffic_stats');

    _listenToFirebase();
  }

  // --- 1. DENGARKAN DATA FIREBASE ---
  void _listenToFirebase() {
    _trafficRef.onValue.listen((event) {
      if (mounted && event.snapshot.value != null) {
        setState(() {
          // Simpan data mentah
          _rawFirebaseData = event.snapshot.value as Map<dynamic, dynamic>;
          // Hitung ulang tampilan
          _recalculateData();
        });
      }
    });
  }

  // --- 2. HITUNG ULANG DATA (GLOBAL / SPESIFIK) ---
  void _recalculateData() {
    if (_rawFirebaseData == null) return;

    int sumMobil = 0;
    int sumMotor = 0;
    int sumBusTruk = 0;
    int sumTotal = 0;

    List<Map<String, dynamic>> tempList = [];
    final cctvProvider = Provider.of<CCTVDataSource>(context, listen: false);

    _rawFirebaseData!.forEach((key, value) {
      String id = key.toString();

      // Filter: Jika mode spesifik aktif, skip ID lain
      if (_selectedCCTVId != null && id != _selectedCCTVId) {
        return; 
      }

      // Parse Data per CCTV
      final stats = _extractStats(value);
      
      // Jika mode Global, kita jumlahkan semua
      // Jika mode Spesifik, loop ini cuma jalan sekali untuk ID yg dipilih
      sumMobil += stats['mobil']!;
      sumMotor += stats['motor']!;
      sumBusTruk += stats['bus_truk']!;
      sumTotal += stats['total']!;

      // Siapkan Data Peringkat (Hanya untuk mode Global atau menampilkan detail)
      String name = "CCTV $id";
      try {
        final cctv = cctvProvider.cctvList.firstWhere((c) => c.id == id);
        name = cctv.name;
      } catch (e) {
        // ignore name error
      }

      // Masukkan ke list peringkat hanya jika datanya valid (>0) atau mode global
      if (_selectedCCTVId == null) {
         tempList.add({'id': id, 'name': name, 'total': stats['total']});
      }
    });

    // Update Chart Values
    double totalPie = (sumMobil + sumMotor + sumBusTruk).toDouble();
    if (totalPie == 0) totalPie = 1;

    _pieValues = [
      (sumMobil / totalPie) * 100,
      (sumMotor / totalPie) * 100,
      (sumBusTruk / totalPie) * 100,
    ];

    // Update Ranking (Hanya update jika mode global, biar listnya kelihatan)
    if (_selectedCCTVId == null) {
      tempList.sort((a, b) => (b['total'] as int).compareTo(a['total'] as int));
      _rankingList = tempList.take(5).toList();
    } else {
      // Jika mode spesifik, ranking list dikosongkan atau tampilkan diri sendiri
      _rankingList = []; 
    }

    // Update Bar Chart (Simulasi Tren)
    _updateBarChartBasedOnTotal(sumTotal);
  }

  // --- 3. PARSING DATA PINTAR (Langsung / Nested Live) ---
  Map<String, int> _extractStats(dynamic value) {
    int mobil = 0;
    int motor = 0;
    int bus = 0;
    int truk = 0;
    int total = 0;

    if (value is Map) {
      Map<dynamic, dynamic>? targetData;

      // Cek apakah ada di folder 'live' (Prioritas 1 - ID 4)
      if (value.containsKey('live') && value['live'] is Map) {
        final live = value['live'];
        total = int.tryParse(live['total']?.toString() ?? '0') ?? 0;
        
        if (live.containsKey('detail')) {
          targetData = live['detail'];
        }
      } 
      // Cek apakah langsung di root (Prioritas 2 - ID 3)
      else {
        total = int.tryParse(value['total']?.toString() ?? '0') ?? 0;
        if (value.containsKey('detail')) {
          targetData = value['detail'];
        }
      }

      // Ambil detail mobil/motor jika ketemu
      if (targetData != null) {
        mobil = int.tryParse(targetData['mobil']?.toString() ?? '0') ?? 0;
        motor = int.tryParse(targetData['motor']?.toString() ?? '0') ?? 0;
        bus = int.tryParse(targetData['bus']?.toString() ?? '0') ?? 0;
        truk = int.tryParse(targetData['truk']?.toString() ?? '0') ?? 0;
      }
    }

    return {
      'mobil': mobil,
      'motor': motor,
      'bus_truk': bus + truk,
      'total': total
    };
  }

  // --- 4. UPDATE GRAFIK BATANG ---
  void _updateBarChartBasedOnTotal(int total) {
    // Trik Visual: Buat grafik terlihat bervariasi meskipun data cuma 1 angka (total)
    // Gunakan 'total' sebagai puncak, dan jam lain sebagai persentase dari total
    double base = total.toDouble();
    if(base == 0) base = 0;

    if (_selectedPeriod == 'Harian') {
      _barLabels = ['06:00', '09:00', '12:00', '15:00', '18:00', '21:00'];
      _barValues = [base * 0.2, base * 0.5, base * 0.8, base * 0.4, base * 1.0, base * 0.6]; 
    } else if (_selectedPeriod == 'Mingguan') {
      _barLabels = ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'];
      _barValues = [base * 0.8, base * 0.9, base * 0.7, base * 0.8, base * 1.0, base * 1.1, base * 0.5];
    } else {
      _barLabels = ['Mgg 1', 'Mgg 2', 'Mgg 3', 'Mgg 4'];
      _barValues = [base * 3, base * 4, base * 3.5, base * 4.5];
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

            _buildDensityChartCard(),
            const SizedBox(height: 24),
            _buildVehicleDistributionCard(),
            const SizedBox(height: 24),
            // Sembunyikan peringkat jika memilih CCTV spesifik
            if(_selectedCCTVId == null) _buildRankingCard(),
            
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

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
                            _recalculateData(); // Trigger hitung ulang
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
                      onTap: () {
                        setState(() {
                          _selectedPeriod = period;
                          _recalculateData();
                        });
                      },
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
    // SKALA DINAMIS: Agar grafik tidak kosong jika angka kecil
    double maxValue = _barValues.reduce(max);
    // Jika max value kecil (misal 5), set batas chart jadi 10 biar kelihatan
    // Jika max value besar (misal 50), set batas chart jadi 60
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
                Text('Tren Kepadatan ($_selectedPeriod)', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                const Icon(Icons.bar_chart, color: Colors.blueAccent),
              ],
            ),
            const SizedBox(height: 30),
            AspectRatio(
              aspectRatio: 1.5,
              child: BarChart(
                BarChartData(
                  maxY: yAxisMax, // Gunakan Skala Dinamis
                  barGroups: List.generate(_barValues.length, (index) {
                    return BarChartGroupData(
                      x: index,
                      barRods: [
                        BarChartRodData(
                          toY: _barValues[index],
                          gradient: const LinearGradient(colors: [Colors.blueAccent, Colors.lightBlueAccent], begin: Alignment.bottomCenter, end: Alignment.topCenter),
                          width: 14,
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
                    leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 30, getTitlesWidget: (val, meta) => Text(val.toInt().toString(), style: const TextStyle(color: Colors.grey, fontSize: 10)))),
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
    // Default value kecil agar pie chart tidak hilang jika data 0
    double mobilVal = _pieValues.isNotEmpty ? _pieValues[0] : 0;
    double motorVal = _pieValues.length > 1 ? _pieValues[1] : 0;
    double busTrukVal = _pieValues.length > 2 ? _pieValues[2] : 0;

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
                child: Text("Data kosong", style: TextStyle(color: Colors.grey)),
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
                  // Simulasi % Kepadatan (Total / 20 * 100) -> 20 mobil dianggap 100% macet
                  int density = ((total / 20.0) * 100).toInt(); 
                  if(density > 100) density = 100;

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
                              Text("Total Kendaraan: $total", style: const TextStyle(color: Colors.grey, fontSize: 11)),
                            ],
                          ),
                        ),
                        Text('$density%', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: density > 80 ? Colors.redAccent : Colors.orangeAccent)),
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