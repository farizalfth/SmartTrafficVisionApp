// lib/screens/report_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:intl/intl.dart';

import 'package:smarttrafficapp/data/cctv_data_source.dart';
import 'package:smarttrafficapp/models/cctv.dart';

class ReportScreen extends StatefulWidget {
  const ReportScreen({super.key});

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  // --- KONEKSI FIREBASE ---
  static const String _dbUrl = 'https://smart-traffic-vision-app-default-rtdb.asia-southeast1.firebasedatabase.app/';
  late final DatabaseReference _trafficRef;

  // State UI
  String? _selectedCCTVId;
  DateTime _selectedDate = DateTime.now();
  
  // Data Laporan
  Map<dynamic, dynamic>? _cctvDailyReports; // Menyimpan semua daily_reports dari CCTV terpilih
  Map<String, dynamic>? _currentPreviewData; // Data untuk tanggal yang dipilih

  @override
  void initState() {
    super.initState();
    final firebaseApp = Firebase.app();
    final rtdb = FirebaseDatabase.instanceFor(app: firebaseApp, databaseURL: _dbUrl);
    _trafficRef = rtdb.ref('traffic_stats');
  }

  // --- 1. AMBIL DATA SAAT CCTV DIPILIH ---
  void _fetchCCTVReports(String cctvId) {
    // Listener hanya untuk path CCTV yang dipilih
    _trafficRef.child(cctvId).child('daily_reports').onValue.listen((event) {
      if (mounted) {
        setState(() {
          // Simpan seluruh data daily_reports (key = tanggal, value = detail)
          _cctvDailyReports = event.snapshot.value as Map<dynamic, dynamic>?;
          
          // Update preview berdasarkan tanggal yang sedang dipilih
          _updatePreviewData();
        });
      }
    });
  }

  // --- 2. UPDATE PREVIEW BERDASARKAN TANGGAL ---
  void _updatePreviewData() {
    if (_cctvDailyReports == null) {
      _currentPreviewData = null;
      return;
    }

    // Format tanggal picker (DateTime) ke string Firebase (yyyy-MM-dd)
    String dateKey = DateFormat('yyyy-MM-dd').format(_selectedDate);

    if (_cctvDailyReports!.containsKey(dateKey)) {
      final report = _cctvDailyReports![dateKey];
      
      // Ambil data detail & total
      Map<String, dynamic> parsedData = {};
      
      // Ambil Total
      parsedData['total'] = report['total_hari_ini'] ?? 0;

      // Ambil Detail
      if (report['detail'] != null && report['detail'] is Map) {
        final detail = report['detail'];
        parsedData['status'] = detail['status_terakhir'] ?? '-';
        parsedData['duration'] = detail['duration_active'] ?? '-';
        parsedData['density'] = detail['kepadatan_terakhir_persen'] ?? 0;
        parsedData['last_update'] = detail['last_update'] ?? '-';
      }

      setState(() {
        _currentPreviewData = parsedData;
      });
    } else {
      setState(() {
        _currentPreviewData = null; // Tidak ada data untuk tanggal ini
      });
    }
  }

  // --- FUNGSI FORMAT TANGGAL ---
  String _formatDateDisplay(String dateString) {
    try {
      DateTime dt = DateTime.parse(dateString);
      return DateFormat('d MMMM yyyy', 'id_ID').format(dt);
    } catch (e) {
      return dateString;
    }
  }

  @override
  Widget build(BuildContext context) {
    final cctvProvider = Provider.of<CCTVDataSource>(context);
    final List<CCTV> cctvList = cctvProvider.cctvList;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Laporan Otomatis'),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- BAGIAN FILTER ---
            _buildFilterCard(cctvList),
            
            const SizedBox(height: 24),

            // --- BAGIAN PREVIEW (DATA FIREBASE) ---
            _buildPreviewSection(),

            const SizedBox(height: 24),

            // --- BAGIAN RIWAYAT (LIST DARI FIREBASE) ---
            _buildHistorySection(),
          ],
        ),
      ),
    );
  }

  // WIDGET: FILTER INPUT
  Widget _buildFilterCard(List<CCTV> cctvList) {
    return Card(
      color: Theme.of(context).cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Pilih Sumber CCTV", style: TextStyle(color: Colors.grey, fontSize: 12)),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.black26, 
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white12)
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedCCTVId,
                  hint: const Text("Pilih CCTV...", style: TextStyle(color: Colors.white54)),
                  isExpanded: true,
                  dropdownColor: const Color(0xFF2C2C2C),
                  items: cctvList.map((cctv) {
                    return DropdownMenuItem(
                      value: cctv.id,
                      child: Text(cctv.name, style: const TextStyle(color: Colors.white), overflow: TextOverflow.ellipsis),
                    );
                  }).toList(),
                  onChanged: (val) {
                    setState(() {
                      _selectedCCTVId = val;
                      _cctvDailyReports = null; // Reset data lama
                      _currentPreviewData = null;
                    });
                    if (val != null) {
                      _fetchCCTVReports(val);
                    }
                  },
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            const Text("Pilih Tanggal Laporan", style: TextStyle(color: Colors.grey, fontSize: 12)),
            const SizedBox(height: 8),
            InkWell(
              onTap: () async {
                final DateTime? picked = await showDatePicker(
                  context: context,
                  initialDate: _selectedDate,
                  firstDate: DateTime(2024),
                  lastDate: DateTime(2030),
                  builder: (context, child) {
                    return Theme(
                      data: Theme.of(context).copyWith(
                        colorScheme: const ColorScheme.dark(
                          primary: Colors.blueAccent,
                          onPrimary: Colors.white,
                          surface: Color(0xFF2C2C2C),
                          onSurface: Colors.white,
                        ),
                      ),
                      child: child!,
                    );
                  },
                );
                if (picked != null && picked != _selectedDate) {
                  setState(() {
                    _selectedDate = picked;
                    _updatePreviewData(); // Cek data tanggal baru
                  });
                }
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                decoration: BoxDecoration(
                  color: Colors.black26, 
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white12)
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.calendar_today, color: Colors.blueAccent, size: 20),
                        const SizedBox(width: 10),
                        Text(DateFormat('dd-MM-yyyy').format(_selectedDate), style: const TextStyle(color: Colors.white)),
                      ],
                    ),
                    const Icon(Icons.arrow_drop_down, color: Colors.white54),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // WIDGET: PREVIEW DATA TENGAH
  Widget _buildPreviewSection() {
    if (_selectedCCTVId == null) {
      return _buildEmptyState("Silakan pilih CCTV terlebih dahulu");
    }

    if (_currentPreviewData == null) {
      return _buildEmptyState("Data belum tersedia untuk tanggal ini");
    }

    // Ambil data dari Map
    final total = _currentPreviewData!['total'];
    final status = _currentPreviewData!['status'];
    final duration = _currentPreviewData!['duration'];
    final density = _currentPreviewData!['density'];
    final lastUpdate = _currentPreviewData!['last_update'];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF2C2C2C),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        children: [
          const Icon(Icons.description, size: 48, color: Colors.white24),
          const SizedBox(height: 16),
          Text("Laporan Harian (${DateFormat('dd MMM').format(_selectedDate)})", 
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 20),
          
          // Grid Detail
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildInfoColumn("Total", "$total Kendaraan", Colors.blueAccent),
              _buildInfoColumn("Status", "$status", status == 'Macet' ? Colors.red : Colors.green),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildInfoColumn("Durasi Aktif", "$duration", Colors.orange),
              _buildInfoColumn("Kepadatan", "$density%", Colors.white),
            ],
          ),
          const SizedBox(height: 20),
          Text("Terakhir update: $lastUpdate", style: const TextStyle(color: Colors.grey, fontSize: 10)),
          
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Fitur Download PDF (Simulasi) Berhasil")));
              },
              icon: const Icon(Icons.download),
              label: const Text("Unduh Laporan"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Container(
      height: 200,
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFF2C2C2C).withOpacity(0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.search, size: 48, color: Colors.white24),
          const SizedBox(height: 12),
          Text(
            message,
            style: const TextStyle(color: Colors.grey),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoColumn(String label, String value, Color color) {
    return Column(
      children: [
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 16)),
      ],
    );
  }

  // WIDGET: RIWAYAT LAPORAN (LIST BAWAH)
  Widget _buildHistorySection() {
    List<String> availableDates = [];
    if (_cctvDailyReports != null) {
      // Urutkan tanggal dari terbaru ke terlama
      availableDates = _cctvDailyReports!.keys.cast<String>().toList();
      availableDates.sort((a, b) => b.compareTo(a)); // Descending
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text("Riwayat Laporan Tersedia", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
            if (availableDates.isNotEmpty)
              Text("${availableDates.length} File", style: const TextStyle(color: Colors.blueAccent, fontSize: 12)),
          ],
        ),
        const SizedBox(height: 12),
        
        if (_selectedCCTVId == null)
          const Text("Pilih CCTV untuk melihat riwayat.", style: TextStyle(color: Colors.grey))
        else if (availableDates.isEmpty)
          const Text("Belum ada data riwayat di database.", style: TextStyle(color: Colors.grey))
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: availableDates.length,
            itemBuilder: (context, index) {
              String dateKey = availableDates[index];
              final data = _cctvDailyReports![dateKey];
              int total = data['total_hari_ini'] ?? 0;
              
              // Cek status
              String status = "Normal";
              if (data['detail'] != null && data['detail']['status_terakhir'] != null) {
                status = data['detail']['status_terakhir'];
              }

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF2C2C2C),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white10),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.picture_as_pdf, color: Colors.redAccent),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Laporan ${_formatDateDisplay(dateKey)}", 
                            style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                          const SizedBox(height: 4),
                          Text("Total: $total • Status: $status", 
                            style: const TextStyle(color: Colors.grey, fontSize: 12)),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.visibility, color: Colors.blueAccent),
                      onPressed: () {
                        // Set tanggal ke tanggal yang diklik agar preview update
                        setState(() {
                          _selectedDate = DateTime.parse(dateKey);
                          _updatePreviewData();
                        });
                      },
                    )
                  ],
                ),
              );
            },
          ),
      ],
    );
  }
}