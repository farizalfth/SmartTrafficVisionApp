// lib/screens/analytics_screen.dart

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import 'dart:math';

import 'package:smarttrafficapp/data/cctv_data_source.dart';
import 'package:smarttrafficapp/models/cctv.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  // State Filter
  String _selectedPeriod = 'Harian'; // Harian, Mingguan, Bulanan
  
  // Nullable agar bisa menampilkan Hint di awal & bisa di-reset
  String? _selectedCCTVId; 

  // Data Grafik Batang (Tren Kepadatan)
  List<double> _barValues = [];
  List<String> _barLabels = [];
  final double _maxY = 100;

  // Data Grafik Lingkaran (Komposisi Kendaraan)
  List<double> _pieValues = [0, 0, 0]; 

  @override
  void initState() {
    super.initState();
  }

  // --- LOGIKA GENERATE DATA DUMMY ---
  void _generateDummyData() {
    if (_selectedCCTVId == null) return;

    final random = Random();
    
    // 1. Logika Grafik Batang (Tren)
    if (_selectedPeriod == 'Harian') {
      _barLabels = ['06:00', '09:00', '12:00', '15:00', '18:00', '21:00'];
      _barValues = List.generate(6, (_) => 20.0 + random.nextInt(60)); 
    } else if (_selectedPeriod == 'Mingguan') {
      _barLabels = ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'];
      _barValues = List.generate(7, (_) => 30.0 + random.nextInt(50)); 
    } else { // Bulanan
      _barLabels = ['Mgg 1', 'Mgg 2', 'Mgg 3', 'Mgg 4'];
      _barValues = List.generate(4, (_) => 40.0 + random.nextInt(40));
    }

    // 2. Logika Grafik Pie (Komposisi) - Dinamis
    double mobil = 30.0 + random.nextInt(40);
    double motor = 20.0 + random.nextInt(30);
    double sisa = 100.0 - (mobil + motor);
    if (sisa < 0) sisa = 5; 
    
    _pieValues = [mobil, motor, sisa];

    setState(() {});
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
            // 1. FILTER KONTROL (CCTV & WAKTU)
            _buildFilterSection(allCCTV),
            
            const SizedBox(height: 24),

            // LOGIKA TAMPILAN:
            if (_selectedCCTVId == null)
              Center(
                child: Container(
                  margin: const EdgeInsets.only(top: 50),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white10,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white24),
                  ),
                  child: const Column(
                    children: [
                      Icon(Icons.analytics_outlined, size: 48, color: Colors.grey),
                      SizedBox(height: 10),
                      Text(
                        "Silakan pilih CCTV pada dropdown di atas\nuntuk melihat data analisis.",
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              )
            else ...[
              // 2. GRAFIK KEPADATAN PER CCTV
              _buildDensityChartCard(),

              const SizedBox(height: 24),

              // 3. PIE CHART DISTRIBUSI KENDARAAN
              _buildVehicleDistributionCard(),

              const SizedBox(height: 24),

              // 4. PERINGKAT TITIK TERPADAT
              _buildRankingCard(allCCTV),
            ],
            
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // --- WIDGET BAGIAN FILTER (DIPERBAIKI) ---
  Widget _buildFilterSection(List<CCTV> cctvList) {
    return Card(
      color: Theme.of(context).cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Pilih Sumber Data", style: TextStyle(color: Colors.grey, fontSize: 12)),
            const SizedBox(height: 12),
            
            // DROPDOWN DENGAN TOMBOL CLEAR
            Container(
              padding: const EdgeInsets.only(left: 12, right: 4), // Padding kanan dikurangi utk tombol X
              decoration: BoxDecoration(
                color: Colors.black26,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white12),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedCCTVId,
                        isExpanded: true,
                        dropdownColor: const Color(0xFF2C2C2C),
                        // Icon default kita sembunyikan, kita pakai icon di Row
                        icon: const SizedBox.shrink(), 
                        hint: const Text("Pilih CCTV...", style: TextStyle(color: Colors.white54, fontStyle: FontStyle.italic)),
                        items: cctvList.map((cctv) {
                          return DropdownMenuItem(
                            value: cctv.id,
                            child: Text(
                              cctv.name,
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                              overflow: TextOverflow.ellipsis,
                            ),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setState(() {
                              _selectedCCTVId = val;
                              _generateDummyData();
                            });
                          }
                        },
                      ),
                    ),
                  ),
                  
                  // LOGIKA TOMBOL CLOSE / ARROW
                  if (_selectedCCTVId != null)
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.redAccent, size: 20),
                      tooltip: "Hapus Pilihan",
                      onPressed: () {
                        setState(() {
                          _selectedCCTVId = null; // Reset ke null
                        });
                      },
                    )
                  else
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 12.0),
                      child: Icon(Icons.keyboard_arrow_down, color: Colors.blueAccent),
                    ),
                ],
              ),
            ),
            
            const SizedBox(height: 16),
            
            // TOMBOL FILTER WAKTU
            Opacity(
              opacity: _selectedCCTVId == null ? 0.5 : 1.0,
              child: IgnorePointer(
                ignoring: _selectedCCTVId == null,
                child: Container(
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.black26,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: ['Harian', 'Mingguan', 'Bulanan'].map((period) {
                      final isSelected = _selectedPeriod == period;
                      return Expanded(
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedPeriod = period;
                              _generateDummyData();
                            });
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              color: isSelected ? Colors.blueAccent : Colors.transparent,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              period,
                              style: TextStyle(
                                color: isSelected ? Colors.white : Colors.grey,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- WIDGET BAR CHART ---
  Widget _buildDensityChartCard() {
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
                Text('Tren Kepadatan ($_selectedPeriod)', 
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                const Icon(Icons.bar_chart, color: Colors.blueAccent),
              ],
            ),
            const SizedBox(height: 30),
            AspectRatio(
              aspectRatio: 1.5,
              child: BarChart(
                BarChartData(
                  maxY: _maxY,
                  barGroups: List.generate(_barValues.length, (index) {
                    return BarChartGroupData(
                      x: index,
                      barRods: [
                        BarChartRodData(
                          toY: _barValues[index],
                          gradient: const LinearGradient(
                            colors: [Colors.blueAccent, Colors.lightBlueAccent],
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                          ),
                          width: 14,
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                          backDrawRodData: BackgroundBarChartRodData(
                            show: true,
                            toY: _maxY,
                            color: Colors.white.withOpacity(0.05),
                          ),
                        ),
                      ],
                    );
                  }),
                  gridData: FlGridData(
                    show: true, 
                    drawVerticalLine: false,
                    horizontalInterval: 20,
                    getDrawingHorizontalLine: (value) => FlLine(color: Colors.white10, strokeWidth: 1),
                  ),
                  borderData: FlBorderData(show: false),
                  titlesData: FlTitlesData(
                    show: true,
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 30,
                        getTitlesWidget: (val, meta) => Text(val.toInt().toString(), style: const TextStyle(color: Colors.grey, fontSize: 10)),
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 30,
                        getTitlesWidget: (val, meta) {
                          if (val.toInt() < _barLabels.length) {
                            return Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Text(_barLabels[val.toInt()], style: const TextStyle(color: Colors.white70, fontSize: 10)),
                            );
                          }
                          return const Text('');
                        },
                      ),
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

  // --- WIDGET PIE CHART ---
  Widget _buildVehicleDistributionCard() {
    double mobilVal = _pieValues[0];
    double motorVal = _pieValues[1];
    double trukVal = _pieValues[2];

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
                Text('Komposisi Kendaraan ($_selectedPeriod)', 
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white)),
                const Icon(Icons.pie_chart, color: Colors.orangeAccent),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                SizedBox(
                  height: 140,
                  width: 140,
                  child: PieChart(
                    PieChartData(
                      sectionsSpace: 2,
                      centerSpaceRadius: 30,
                      sections: [
                        PieChartSectionData(
                          color: Colors.blueAccent, 
                          value: mobilVal, 
                          title: '${mobilVal.toInt()}%', 
                          radius: 40, 
                          titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white)
                        ),
                        PieChartSectionData(
                          color: Colors.orangeAccent, 
                          value: motorVal, 
                          title: '${motorVal.toInt()}%', 
                          radius: 35, 
                          titleStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white)
                        ),
                        PieChartSectionData(
                          color: Colors.redAccent, 
                          value: trukVal, 
                          title: '${trukVal.toInt()}%', 
                          radius: 30, 
                          titleStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white)
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 24),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildLegendItem(Colors.blueAccent, 'Mobil Pribadi (${mobilVal.toInt()}%)'),
                      const SizedBox(height: 8),
                      _buildLegendItem(Colors.orangeAccent, 'Motor (${motorVal.toInt()}%)'),
                      const SizedBox(height: 8),
                      _buildLegendItem(Colors.redAccent, 'Bus / Truk (${trukVal.toInt()}%)'),
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
    return Row(
      children: [
        Container(width: 12, height: 12, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 8),
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
      ],
    );
  }

  // --- WIDGET PERINGKAT ---
  Widget _buildRankingCard(List<CCTV> allCCTV) {
    List<CCTV> sortedCCTV = List.from(allCCTV)..shuffle();
    if (sortedCCTV.length > 3) sortedCCTV = sortedCCTV.sublist(0, 3);

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
                Text('Peringkat Kepadatan ($_selectedPeriod)', 
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                const Icon(Icons.emoji_events, color: Colors.amber),
              ],
            ),
            const SizedBox(height: 16),
            
            if (sortedCCTV.isEmpty)
              const Center(child: Text("Data tidak tersedia", style: TextStyle(color: Colors.grey)))
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: sortedCCTV.length,
                separatorBuilder: (context, index) => const Divider(color: Colors.white10),
                itemBuilder: (context, index) {
                  final cctv = sortedCCTV[index];
                  final int density = 95 - (index * 12); 
                  
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Row(
                      children: [
                        Container(
                          width: 32, height: 32,
                          decoration: BoxDecoration(
                            color: index == 0 ? Colors.red.withOpacity(0.2) : Colors.transparent,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: index == 0 ? Colors.redAccent : (index == 1 ? Colors.orange : Colors.grey),
                              width: 2
                            ),
                          ),
                          child: Center(
                            child: Text(
                              '${index + 1}',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: index == 0 ? Colors.redAccent : (index == 1 ? Colors.orange : Colors.grey),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(cctv.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white), maxLines: 1, overflow: TextOverflow.ellipsis),
                              Text(cctv.location, style: const TextStyle(color: Colors.grey, fontSize: 11)),
                            ],
                          ),
                        ),
                        Text(
                          '$density%',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: density > 80 ? Colors.redAccent : Colors.orangeAccent,
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