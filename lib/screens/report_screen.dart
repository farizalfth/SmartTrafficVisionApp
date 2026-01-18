import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';

class ReportScreen extends StatefulWidget {
  const ReportScreen({super.key});

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  static const String _dbUrl =
      'https://smart-traffic-vision-app-default-rtdb.asia-southeast1.firebasedatabase.app/';
  late final DatabaseReference _trafficRef;

  final List<Map<String, String>> _cctvList = [
    {'id': '1', 'name': 'CCTV Pontianak (Simpang Garuda)'},
    {'id': '2', 'name': 'CCTV Pontianak (Tugu Khatulistiwa)'},
    {'id': '3', 'name': 'CCTV Demak (Alun-Alun)'},
    {'id': '4', 'name': 'CCTV Demak (Pasar Bintoro)'},
    {'id': '5', 'name': 'CCTV Demak (Pertigaan Trengguli)'},
  ];

  String? _selectedId;
  DateTime _selectedDate = DateTime.now();

  Map<String, double> _chartData = {
    'bus': 0,
    'mobil': 0,
    'motor': 0,
    'truk': 0,
  };

  @override
  void initState() {
    super.initState();
    final firebaseApp = Firebase.app();
    final rtdb =
        FirebaseDatabase.instanceFor(app: firebaseApp, databaseURL: _dbUrl);
    _trafficRef = rtdb.ref('traffic_stats');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        title: const Text('Laporan Otomatis',
            style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () => Scaffold.of(context).openDrawer(),
        ),
      ),
      body: StreamBuilder(
        stream: _trafficRef.onValue,
        builder: (context, AsyncSnapshot<DatabaseEvent> snapshot) {
          if (snapshot.hasData && snapshot.data!.snapshot.value != null) {
            _processData(snapshot.data!.snapshot.value);
            return _buildMainUI();
          }
          return const Center(
              child: CircularProgressIndicator(color: Colors.blueAccent));
        },
      ),
    );
  }

  void _processData(dynamic rawData) {
    if (_selectedId == null) return;
    final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);
    dynamic cctvData;

    try {
      if (rawData is List) {
        int idx = int.parse(_selectedId!);
        if (idx < rawData.length) cctvData = rawData[idx];
      } else if (rawData is Map) {
        cctvData = rawData[_selectedId];
      }

      if (cctvData != null && cctvData['daily_reports'] != null) {
        final report = cctvData['daily_reports'][dateStr];
        if (report != null && report['detail'] != null) {
          final d = report['detail'];
          setState(() {
            _chartData = {
              'bus': double.tryParse(d['bus'].toString()) ?? 0,
              'mobil': double.tryParse(d['mobil'].toString()) ?? 0,
              'motor': double.tryParse(d['motor'].toString()) ?? 0,
              'truk': double.tryParse(d['truk'].toString()) ?? 0,
            };
          });
          return;
        }
      }
      setState(
          () => _chartData = {'bus': 0, 'mobil': 0, 'motor': 0, 'truk': 0});
    } catch (e) {
      debugPrint("Error: $e");
    }
  }

  Widget _buildMainUI() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSelectorCard(),
          if (_selectedId == null) ...[
            const SizedBox(height: 100),
            const Center(
              child: Column(
                children: [
                  Icon(Icons.touch_app_outlined,
                      size: 80, color: Colors.white12),
                  SizedBox(height: 16),
                  Text("Silakan pilih sumber CCTV terlebih dahulu",
                      style: TextStyle(color: Colors.white38)),
                ],
              ),
            )
          ] else ...[
            const SizedBox(height: 25),
            _buildStatisticsCard(),
            const SizedBox(height: 25),
            const Text("Visualisasi Data Kendaraan",
                style: TextStyle(
                    color: Colors.white70,
                    fontSize: 16,
                    fontWeight: FontWeight.w600)),
            const SizedBox(height: 15),
            _buildChartContainer(),
            const SizedBox(height: 25),
            const Text("Rincian Data",
                style: TextStyle(
                    color: Colors.white70,
                    fontSize: 16,
                    fontWeight: FontWeight.w600)),
            const SizedBox(height: 15),
            _buildDetailedList(),
          ],
        ],
      ),
    );
  }

  Widget _buildSelectorCard() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedId,
                    hint: const Text("Pilih Sumber CCTV",
                        style: TextStyle(color: Colors.white38, fontSize: 14)),
                    isExpanded: true,
                    dropdownColor: const Color(0xFF2C2C2C),
                    icon: const Icon(Icons.keyboard_arrow_down,
                        color: Colors.blueAccent),
                    items: _cctvList
                        .map((c) => DropdownMenuItem(
                              value: c['id'],
                              child: Text(c['name']!,
                                  style: const TextStyle(
                                      color: Colors.white, fontSize: 14)),
                            ))
                        .toList(),
                    onChanged: (v) => setState(() => _selectedId = v),
                  ),
                ),
              ),
              if (_selectedId != null)
                IconButton(
                  icon: const Icon(Icons.close,
                      color: Colors.redAccent, size: 20),
                  onPressed: () => setState(() {
                    _selectedId = null;
                    _chartData = {'bus': 0, 'mobil': 0, 'motor': 0, 'truk': 0};
                  }),
                )
            ],
          ),
          const Divider(color: Colors.white10, height: 10),
          InkWell(
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: _selectedDate,
                firstDate: DateTime(2024),
                lastDate: DateTime.now(),
              );
              if (picked != null) setState(() => _selectedDate = picked);
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Row(
                children: [
                  const Icon(Icons.calendar_today,
                      size: 18, color: Colors.blueAccent),
                  const SizedBox(width: 12),
                  Text(
                      DateFormat('EEEE, d MMMM yyyy', 'id_ID')
                          .format(_selectedDate),
                      style: const TextStyle(
                          color: Colors.white, fontWeight: FontWeight.w500)),
                  const Spacer(),
                  const Icon(Icons.edit, size: 16, color: Colors.grey),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatisticsCard() {
    double total = _chartData.values.reduce((a, b) => a + b);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
            colors: [Color(0xFF0D47A1), Color(0xFF1976D2)]),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: Colors.blue.withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(0, 5))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Total Kendaraan Hari Ini",
              style: TextStyle(color: Colors.white70, fontSize: 14)),
          const SizedBox(height: 5),
          Text(NumberFormat.decimalPattern('id_ID').format(total.toInt()),
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildChartContainer() {
    return Container(
      height: 350,
      // PERBAIKAN: Tambah padding bawah agar label tidak mepet
      padding: const EdgeInsets.fromLTRB(5, 30, 20, 20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(20),
      ),
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: _getMaxY(),
          barTouchData: BarTouchData(
            touchTooltipData: BarTouchTooltipData(
              getTooltipColor: (_) => Colors.blueGrey.withOpacity(0.9),
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                return BarTooltipItem(
                    rod.toY.toInt().toString(),
                    const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold));
              },
            ),
          ),
          titlesData: FlTitlesData(
            show: true,
            bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 40,
                    getTitlesWidget:
                        _bottomTitles)), // Memanggil fungsi di bawah
            leftTitles: AxisTitles(
                sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 45,
                    getTitlesWidget: (value, meta) {
                      String text = '';
                      if (value == 0) {
                        text = '0';
                      } else if (value >= 1000) {
                        text = '${(value / 1000).toStringAsFixed(1)}K';
                      } else {
                        text = value.toInt().toString();
                      }

                      return SideTitleWidget(
                        meta: meta, // PERBAIKAN: Gunakan meta, hapus axisSide
                        space: 8,
                        child: Text(text,
                            style: const TextStyle(
                                color: Colors.grey, fontSize: 10)),
                      );
                    })),
            topTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          gridData: FlGridData(
              show: true,
              drawVerticalLine: false,
              getDrawingHorizontalLine: (_) =>
                  const FlLine(color: Colors.white10, strokeWidth: 1)),
          borderData: FlBorderData(show: false),
          barGroups: [
            _makeGroup(0, _chartData['bus']!, Colors.orange),
            _makeGroup(1, _chartData['mobil']!, Colors.blue),
            _makeGroup(2, _chartData['motor']!, Colors.green),
            _makeGroup(3, _chartData['truk']!, Colors.red),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailedList() {
    return Column(
      children: [
        _detailItem(
            "Bus", _chartData['bus']!, Colors.orange, Icons.directions_bus),
        _detailItem(
            "Mobil", _chartData['mobil']!, Colors.blue, Icons.directions_car),
        _detailItem(
            "Motor", _chartData['motor']!, Colors.green, Icons.two_wheeler),
        _detailItem(
            "Truk", _chartData['truk']!, Colors.red, Icons.local_shipping),
      ],
    );
  }

  Widget _detailItem(String label, double value, Color color, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 16),
          Text(label,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w500)),
          const Spacer(),
          Text(NumberFormat.decimalPattern('id_ID').format(value.toInt()),
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _bottomTitles(double value, TitleMeta meta) {
    const style = TextStyle(
      color: Colors.grey,
      fontWeight: FontWeight.bold,
      fontSize: 12,
    );

    Widget text;
    switch (value.toInt()) {
      case 0:
        text = const Text('Bus', style: style);
        break;
      case 1:
        text = const Text('Mobil', style: style);
        break;
      case 2:
        text = const Text('Motor', style: style);
        break;
      case 3:
        text = const Text('Truk', style: style);
        break;
      default:
        text = const Text('', style: style);
        break;
    }

    return SideTitleWidget(
      meta: meta, // PERBAIKAN: Gunakan meta, hapus axisSide
      space: 10,
      child: text,
    );
  }

  BarChartGroupData _makeGroup(int x, double y, Color color) {
    return BarChartGroupData(x: x, barRods: [
      BarChartRodData(
        toY: y,
        color: color,
        width: 22,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
        backDrawRodData: BackgroundBarChartRodData(
            show: true, toY: _getMaxY(), color: Colors.white.withOpacity(0.05)),
      ),
    ]);
  }

  double _getMaxY() {
    double max = 0;
    for (var v in _chartData.values) {
      v > max ? max = v : null;
    }
    return max == 0 ? 100 : max + (max * 0.15);
  }
}
