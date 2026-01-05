// lib/screens/report_screen.dart

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import 'dart:math';

import 'package:smarttrafficapp/data/cctv_data_source.dart';
import 'package:smarttrafficapp/models/cctv.dart';

class ReportScreen extends StatefulWidget {
  const ReportScreen({super.key});

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  // State Filter
  String _selectedPeriod = 'Harian';
  DateTime _selectedDate = DateTime.now();
  String? _selectedCCTVId; // Variable untuk menyimpan CCTV yang dipilih

  // Data Dummy untuk Preview (Akan di-random saat CCTV berubah)
  int _totalKendaraan = 0;
  String _puncakKepadatan = "--:--";
  int _pelanggaran = 0;
  List<double> _chartValues = [0, 0, 0, 0, 0, 0];

  @override
  Widget build(BuildContext context) {
    // Ambil data CCTV dari Provider
    final cctvProvider = Provider.of<CCTVDataSource>(context);
    final List<CCTV> cctvList = cctvProvider.cctvList;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Laporan Otomatis'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. KARTU FILTER (CCTV, Periode, Tanggal)
            _buildFilterCard(context, cctvList),

            const SizedBox(height: 24),

            // 2. LOGIKA TAMPILAN PREVIEW
            if (_selectedCCTVId == null)
              _buildEmptyState()
            else
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Preview Data $_selectedPeriod',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  const SizedBox(height: 12),
                  _buildPreviewCard(context),
                  
                  const SizedBox(height: 24),
                  
                  // TOMBOL GENERATE
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Laporan $_selectedPeriod untuk CCTV terpilih sedang diunduh...'),
                            backgroundColor: Colors.blueAccent,
                          ),
                        );
                      },
                      icon: const Icon(Icons.download_rounded, color: Colors.white),
                      label: const Text('Generate & Unduh Laporan', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueAccent,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ],
              ),

            const SizedBox(height: 30),

            // 3. RIWAYAT LAPORAN
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Riwayat Laporan', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                TextButton(
                  onPressed: () {}, 
                  child: const Text('Lihat Semua', style: TextStyle(color: Colors.blueAccent)),
                ),
              ],
            ),
            const SizedBox(height: 10),
            _buildHistoryItem('Laporan Harian', '14-12-2025 • PDF File'),
            _buildHistoryItem('Laporan Mingguan', '07-12-2025 s/d 13-12-2025 • PDF File'),
          ],
        ),
      ),
    );
  }

  // --- WIDGET FILTER ---
  Widget _buildFilterCard(BuildContext context, List<CCTV> cctvList) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF2C2C2C),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // A. PILIH CCTV
          const Text('Pilih Sumber CCTV', style: TextStyle(color: Colors.grey, fontSize: 12)),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.only(left: 12, right: 4),
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
                      dropdownColor: const Color(0xFF1E1E1E),
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
                            _generateRandomData(); // Update data preview saat CCTV ganti
                          });
                        }
                      },
                    ),
                  ),
                ),
                if (_selectedCCTVId != null)
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.redAccent, size: 20),
                    onPressed: () => setState(() => _selectedCCTVId = null),
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

          // B. PILIH PERIODE
          const Text('Pilih Periode Laporan', style: TextStyle(color: Colors.grey, fontSize: 12)),
          const SizedBox(height: 8),
          Container(
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
                        _generateRandomData();
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

          const SizedBox(height: 16),

          // C. PILIH TANGGAL
          const Text('Pilih Tanggal', style: TextStyle(color: Colors.grey, fontSize: 12)),
          const SizedBox(height: 8),
          InkWell(
            onTap: () async {
              final DateTime? picked = await showDatePicker(
                context: context,
                initialDate: _selectedDate,
                firstDate: DateTime(2020),
                lastDate: DateTime(2030),
                builder: (context, child) {
                  return Theme(
                    data: ThemeData.dark().copyWith(
                      colorScheme: const ColorScheme.dark(
                        primary: Colors.blueAccent,
                        onPrimary: Colors.white,
                        surface: Color(0xFF2C2C2C),
                        onSurface: Colors.white,
                      ),
                      dialogBackgroundColor: const Color(0xFF2C2C2C),
                    ),
                    child: child!,
                  );
                },
              );
              if (picked != null && picked != _selectedDate) {
                setState(() {
                  _selectedDate = picked;
                  _generateRandomData();
                });
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.black26,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.calendar_today, color: Colors.blueAccent, size: 20),
                  const SizedBox(width: 12),
                  Text(
                    "${_selectedDate.day.toString().padLeft(2, '0')}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.year}",
                    style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500),
                  ),
                  const Spacer(),
                  const Icon(Icons.arrow_drop_down, color: Colors.grey),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- WIDGET PREVIEW ---
  Widget _buildPreviewCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF2C2C2C),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          // Kolom Statistik Kiri
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildStatItem('Total Kendaraan', '$_totalKendaraan Unit'),
                const SizedBox(height: 16),
                _buildStatItem('Puncak Kepadatan', '$_puncakKepadatan WIB'),
                const SizedBox(height: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Pelanggaran', style: TextStyle(color: Colors.grey, fontSize: 11)),
                    const SizedBox(height: 4),
                    Text('$_pelanggaran Kasus', style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 16)),
                  ],
                ),
              ],
            ),
          ),
          
          // Divider Vertical
          Container(width: 1, height: 100, color: Colors.white12, margin: const EdgeInsets.symmetric(horizontal: 16)),

          // Grafik Mini Kanan
          Expanded(
            flex: 3,
            child: SizedBox(
              height: 120,
              child: BarChart(
                BarChartData(
                  titlesData: FlTitlesData(
                    leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (val, meta) {
                          const titles = ['06:00', '09:00', '12:00', '15:00', '18:00', '21:00'];
                          if (val.toInt() >= 0 && val.toInt() < titles.length) {
                            return Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Text(titles[val.toInt()], style: const TextStyle(color: Colors.grey, fontSize: 9)),
                            );
                          }
                          return const Text('');
                        },
                      ),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  gridData: const FlGridData(show: false),
                  barGroups: _chartValues.asMap().entries.map((e) {
                    return BarChartGroupData(
                      x: e.key,
                      barRods: [
                        BarChartRodData(
                          toY: e.value,
                          color: Colors.blueAccent,
                          width: 8,
                          borderRadius: BorderRadius.circular(4),
                          backDrawRodData: BackgroundBarChartRodData(show: true, toY: 100, color: Colors.white10),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 11)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
      ],
    );
  }

  // --- EMPTY STATE (PERBAIKAN: ICON & CONST) ---
  Widget _buildEmptyState() {
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 20),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white10,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white24),
        ),
        // Hapus 'const' di sini jika menyebabkan error, tapi dengan Icons.search aman.
        child: const Column(
          children: [
            // PERBAIKAN: Menggunakan icon standar yang pasti ada
            Icon(Icons.search, size: 48, color: Colors.grey),
            SizedBox(height: 10),
            Text(
              "Silakan pilih CCTV terlebih dahulu\nuntuk melihat preview data.",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  // --- LIST ITEM RIWAYAT ---
  Widget _buildHistoryItem(String title, String subtitle) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF2C2C2C),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: Colors.redAccent.withOpacity(0.2), borderRadius: BorderRadius.circular(8)),
            child: const Icon(Icons.picture_as_pdf, color: Colors.redAccent),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                Text(subtitle, style: const TextStyle(color: Colors.grey, fontSize: 12)),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.share, color: Colors.grey, size: 20),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.visibility, color: Colors.blueAccent, size: 20),
            onPressed: () {},
          ),
        ],
      ),
    );
  }

  // --- LOGIKA DATA DUMMY ---
  void _generateRandomData() {
    final random = Random();
    setState(() {
      _totalKendaraan = 1500 + random.nextInt(3000); // 1500 - 4500
      _pelanggaran = 5 + random.nextInt(50); // 5 - 55
      
      // Random Jam Puncak
      int hour = 7 + random.nextInt(12); // 07:00 - 19:00
      _puncakKepadatan = "${hour.toString().padLeft(2, '0')}:00";

      // Random Chart Data (0 - 100 range)
      _chartValues = List.generate(6, (_) => 20.0 + random.nextInt(80));
    });
  }
}