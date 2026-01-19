// lib/screens/analytics_screen.dart

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:intl/intl.dart';

import 'package:smarttrafficapp/data/cctv_data_source.dart';
import 'package:smarttrafficapp/models/cctv.dart';

enum PeriodFilter { hari, minggu, bulan }

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  static const String _dbUrl =
      'https://smart-traffic-vision-app-default-rtdb.asia-southeast1.firebasedatabase.app/';
  late final DatabaseReference _trafficRef;

  String? _selectedCCTVId;
  PeriodFilter _selectedPeriod = PeriodFilter.hari;

  List<BarChartGroupData> _chartGroups = [];
  List<String> _dateLabels = [];
  double _maxY = 100;

  List<Map<String, dynamic>> _rankingList = [];
  Map<String, int> _currentViewData = {}; 
  int _grandTotal = 0; // Variabel baru untuk total keseluruhan
  dynamic _rawFirebaseData;

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
          _rawFirebaseData = event.snapshot.value;
          _processData();
        });
      }
    });
  }

  void _processData() {
    if (_rawFirebaseData == null) return;

    Map<String, int> dailyTotals = {};
    List<Map<String, dynamic>> rankingTemp = [];
    final cctvProvider = Provider.of<CCTVDataSource>(context, listen: false);

    void processCCTVNode(String key, dynamic value) {
      String idFirebase = key.toString();
      bool isSelected = false;

      if (_selectedCCTVId == null) {
        isSelected = true;
      } else {
        String id1 = _selectedCCTVId!.replaceAll(RegExp(r'[^0-9]'), '');
        String id2 = idFirebase.replaceAll(RegExp(r'[^0-9]'), '');
        if (int.tryParse(id1) == int.tryParse(id2)) isSelected = true;
      }

      if (value is Map) {
        int cctvPeriodTotal = 0;
        if (value.containsKey('daily_reports')) {
          final reports = value['daily_reports'];
          if (reports is Map) {
            reports.forEach((dateKey, reportData) {
              int total = 0;
              if (reportData is Map) {
                total = int.tryParse(reportData['total_hari_ini']?.toString() ?? '0') ?? 0;
              } else {
                total = int.tryParse(reportData.toString()) ?? 0;
              }

              if (isSelected) {
                dailyTotals[dateKey] = (dailyTotals[dateKey] ?? 0) + total;
              }

              try {
                DateTime dt = DateTime.parse(dateKey);
                DateTime now = DateTime.now();
                if (_selectedPeriod == PeriodFilter.hari) {
                   if (dateKey == DateFormat('yyyy-MM-dd').format(now)) cctvPeriodTotal += total;
                } else if (_selectedPeriod == PeriodFilter.minggu) {
                   if (dt.month == now.month && dt.year == now.year) cctvPeriodTotal += total;
                } else {
                   if (dt.year == now.year) cctvPeriodTotal += total;
                }
              } catch (_) {}
            });
          }
        }

        if (_selectedCCTVId == null) {
          String name = "CCTV $idFirebase";
          try {
            final cctv = cctvProvider.cctvList.firstWhere((c) =>
                int.tryParse(c.id.replaceAll(RegExp(r'[^0-9]'), '')) ==
                int.tryParse(idFirebase.replaceAll(RegExp(r'[^0-9]'), '')));
            name = cctv.name;
          } catch (_) {}
          if (cctvPeriodTotal > 0) rankingTemp.add({'name': name, 'total': cctvPeriodTotal});
        }
      }
    }

    if (_rawFirebaseData is Map) {
      _rawFirebaseData.forEach((k, v) => processCCTVNode(k.toString(), v));
    } else if (_rawFirebaseData is List) {
      for (int i = 0; i < _rawFirebaseData.length; i++) {
        if (_rawFirebaseData[i] != null) processCCTVNode(i.toString(), _rawFirebaseData[i]);
      }
    }

    _generateChartData(dailyTotals);
    rankingTemp.sort((a, b) => (b['total'] as int).compareTo(a['total'] as int));
    setState(() {
      _rankingList = _selectedCCTVId == null ? rankingTemp.take(5).toList() : [];
    });
  }

  void _generateChartData(Map<String, int> rawData) {
    List<BarChartGroupData> groups = [];
    List<String> labels = [];
    Map<String, int> viewData = {};
    double maxVal = 0;
    int currentGrandTotal = 0;
    DateTime now = DateTime.now();
    String monthName = DateFormat('MMM').format(now);

    if (_selectedPeriod == PeriodFilter.hari) {
      var sortedKeys = rawData.keys.toList()..sort();
      if (sortedKeys.length > 7) sortedKeys = sortedKeys.sublist(sortedKeys.length - 7);

      for (int i = 0; i < sortedKeys.length; i++) {
        double val = rawData[sortedKeys[i]]!.toDouble();
        if (val > maxVal) maxVal = val;
        currentGrandTotal += val.toInt();
        String label = "";
        try {
          DateTime dt = DateTime.parse(sortedKeys[i]);
          label = DateFormat('d MMM').format(dt);
        } catch (_) { label = sortedKeys[i]; }
        labels.add(label);
        viewData[label] = val.toInt();
        groups.add(_createBarGroup(i, val));
      }
    } 
    else if (_selectedPeriod == PeriodFilter.minggu) {
      Map<String, int> weeks = {"1-7 $monthName": 0, "8-14 $monthName": 0, "15-21 $monthName": 0, "22-31 $monthName": 0};
      rawData.forEach((date, total) {
        DateTime dt = DateTime.parse(date);
        if (dt.month == now.month && dt.year == now.year) {
          if (dt.day <= 7) weeks["1-7 $monthName"] = weeks["1-7 $monthName"]! + total;
          else if (dt.day <= 14) weeks["8-14 $monthName"] = weeks["8-14 $monthName"]! + total;
          else if (dt.day <= 21) weeks["15-21 $monthName"] = weeks["15-21 $monthName"]! + total;
          else weeks["22-31 $monthName"] = weeks["22-31 $monthName"]! + total;
          currentGrandTotal += total;
        }
      });
      int i = 0;
      weeks.forEach((label, val) {
        double v = val.toDouble();
        if (v > maxVal) maxVal = v;
        labels.add(label);
        viewData[label] = val;
        groups.add(_createBarGroup(i++, v));
      });
    } 
    else {
      List<String> mFull = ["Januari", "Februari", "Maret", "April", "Mei", "Juni", "Juli", "Agustus", "September", "Oktober", "November", "Desember"];
      Map<int, int> months = Map.fromIterable(List.generate(12, (i) => i + 1), value: (_) => 0);
      rawData.forEach((date, total) {
        DateTime dt = DateTime.parse(date);
        if (dt.year == now.year) {
          months[dt.month] = months[dt.month]! + total;
          currentGrandTotal += total;
        }
      });
      for (int i = 1; i <= 12; i++) {
        double val = months[i]!.toDouble();
        if (val > maxVal) maxVal = val;
        String label = mFull[i - 1];
        labels.add(label.substring(0, 3)); 
        viewData[label] = val.toInt(); 
        groups.add(_createBarGroup(i - 1, val));
      }
    }

    setState(() {
      _chartGroups = groups;
      _dateLabels = labels;
      _currentViewData = viewData;
      _grandTotal = currentGrandTotal;
      _maxY = maxVal > 0 ? maxVal : 100;
    });
  }

  BarChartGroupData _createBarGroup(int x, double y) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: y,
          gradient: const LinearGradient(colors: [Colors.blueAccent, Colors.lightBlueAccent], begin: Alignment.bottomCenter, end: Alignment.topCenter),
          width: _selectedPeriod == PeriodFilter.bulan ? 8 : 16,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
          // backDrawRodData dihapus agar tidak ada garis membayang ke atas
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final cctvProvider = Provider.of<CCTVDataSource>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Statistik & Analitik'),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(icon: const Icon(Icons.menu), onPressed: () => Scaffold.of(context).openDrawer()),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildFilterSection(cctvProvider.cctvList),
            const SizedBox(height: 16),
            _buildHistoryChart(),
            if (_selectedCCTVId != null) ...[
              const SizedBox(height: 16),
              _buildDetailedTextData(),
            ],
            const SizedBox(height: 24),
            if (_selectedCCTVId == null) _buildRankingCard(),
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
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(color: Colors.black26, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.white12)),
              child: Row(
                children: [
                  Expanded(
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedCCTVId,
                        isExpanded: true,
                        dropdownColor: const Color(0xFF2C2C2C),
                        hint: const Text("Semua CCTV (Global)", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        items: cctvList.map((c) => DropdownMenuItem(value: c.id, child: Text(c.name, style: const TextStyle(color: Colors.white), overflow: TextOverflow.ellipsis))).toList(),
                        onChanged: (val) { setState(() { _selectedCCTVId = val; _processData(); }); },
                      ),
                    ),
                  ),
                  if (_selectedCCTVId != null) IconButton(icon: const Icon(Icons.close, color: Colors.redAccent, size: 20), onPressed: () { setState(() { _selectedCCTVId = null; _processData(); }); })
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryChart() {
    String title = _selectedPeriod == PeriodFilter.hari ? 'Harian' : _selectedPeriod == PeriodFilter.minggu ? 'Mingguan' : 'Bulanan';
    return Card(
      color: Theme.of(context).cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Tren Volume $title', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
            const SizedBox(height: 12),
            _buildPeriodToggle(), 
            const SizedBox(height: 24),
            AspectRatio(
              aspectRatio: 1.4,
              child: BarChart(
                BarChartData(
                  maxY: _maxY * 1.2,
                  barGroups: _chartGroups,
                  borderData: FlBorderData(show: false),
                  gridData: FlGridData(show: true, drawVerticalLine: false, horizontalInterval: _maxY / 4, getDrawingHorizontalLine: (v) => FlLine(color: Colors.white10)),
                  titlesData: FlTitlesData(
                    show: true,
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 38, getTitlesWidget: (val, meta) => Text(val >= 1000 ? '${(val / 1000).toStringAsFixed(0)}k' : val.toInt().toString(), style: const TextStyle(color: Colors.grey, fontSize: 10)))),
                    bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, getTitlesWidget: (val, meta) {
                      if (val.toInt() < 0 || val.toInt() >= _dateLabels.length) return const SizedBox();
                      return Padding(padding: const EdgeInsets.only(top: 8.0), child: Text(_dateLabels[val.toInt()], style: const TextStyle(color: Colors.white70, fontSize: 9)));
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

  Widget _buildPeriodToggle() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(color: Colors.black38, borderRadius: BorderRadius.circular(10)),
      child: Row(
        children: [
          _toggleItem("Hari", PeriodFilter.hari),
          _toggleItem("Minggu", PeriodFilter.minggu),
          _toggleItem("Bulan", PeriodFilter.bulan),
        ],
      ),
    );
  }

  Widget _toggleItem(String text, PeriodFilter filter) {
    bool isSelected = _selectedPeriod == filter;
    return Expanded(
      child: GestureDetector(
        onTap: () { setState(() { _selectedPeriod = filter; _processData(); }); },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(color: isSelected ? Colors.cyan : Colors.transparent, borderRadius: BorderRadius.circular(8)),
          alignment: Alignment.center,
          child: Text(text, style: TextStyle(color: isSelected ? Colors.black : Colors.grey, fontSize: 12, fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }

  Widget _buildDetailedTextData() {
    String pStr = _selectedPeriod == PeriodFilter.hari ? "Hari" : _selectedPeriod == PeriodFilter.minggu ? "Minggu" : "Bulan";
    return Card(
      color: Theme.of(context).cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.list_alt, color: Colors.cyan, size: 20),
                    const SizedBox(width: 8),
                    Text('Rincian Data $pStr', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white)),
                  ],
                ),
              ],
            ),
            const Divider(color: Colors.white10, height: 24),
            // Header Total Keseluruhan
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Colors.blueAccent.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Total Kendaraan', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  Text(NumberFormat.decimalPattern('id_ID').format(_grandTotal), style: const TextStyle(color: Colors.cyan, fontWeight: FontWeight.bold, fontSize: 16)),
                ],
              ),
            ),
            const SizedBox(height: 12),
            ..._currentViewData.entries.map((e) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 6.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(e.key, style: const TextStyle(color: Colors.grey, fontSize: 13)),
                  Text(NumberFormat.decimalPattern('id_ID').format(e.value), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                ],
              ),
            )).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildRankingCard() {
    String suffix = _selectedPeriod == PeriodFilter.hari ? "Hari Ini" : _selectedPeriod == PeriodFilter.minggu ? "Bulan Ini" : "Tahun Ini";
    return Card(
      color: Theme.of(context).cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Expanded(child: Text('Volume CCTV Tertinggi', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white))),
                Text(suffix, style: const TextStyle(color: Colors.grey, fontSize: 11)),
                const SizedBox(width: 6),
                const Icon(Icons.emoji_events, color: Colors.amber, size: 18),
              ],
            ),
            const SizedBox(height: 16),
            if (_rankingList.isEmpty) const Center(child: Text("Data belum tersedia", style: TextStyle(color: Colors.grey)))
            else ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _rankingList.length,
              separatorBuilder: (_, __) => const Divider(color: Colors.white10),
              itemBuilder: (context, index) {
                final data = _rankingList[index];
                double progress = data['total'] / _rankingList[0]['total'];
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    children: [
                      CircleAvatar(radius: 12, backgroundColor: index == 0 ? Colors.amber.withOpacity(0.2) : Colors.white12, child: Text('${index + 1}', style: TextStyle(color: index == 0 ? Colors.amber : Colors.grey, fontSize: 10, fontWeight: FontWeight.bold))),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Fix teks tertutup dengan maxLines: 2 dan overflow
                            Text(data['name'], style: const TextStyle(color: Colors.white, fontSize: 13), maxLines: 2, overflow: TextOverflow.visible),
                            const SizedBox(height: 5),
                            LinearProgressIndicator(value: progress, backgroundColor: Colors.white10, color: Colors.blueAccent, minHeight: 4),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text('${data['total']}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
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