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
  static const String _dbUrl =
      'https://smart-traffic-vision-app-default-rtdb.asia-southeast1.firebasedatabase.app/';
  late final DatabaseReference _trafficRef;

  // State UI
  String? _selectedCCTVId;
  DateTime _selectedDate = DateTime.now();
  String? _displayedDateKey;

  // Data Mentah dari Firebase (Semua Node)
  Map<dynamic, dynamic>? _allTrafficData;

  // Data Laporan Terpilih
  Map<dynamic, dynamic>? _cctvDailyReports;
  Map<String, dynamic>? _currentPreviewData;

  @override
  void initState() {
    super.initState();
    final firebaseApp = Firebase.app();
    final rtdb =
        FirebaseDatabase.instanceFor(app: firebaseApp, databaseURL: _dbUrl);
    _trafficRef = rtdb.ref('traffic_stats');

    _listenToAllData();
  }

  void _listenToAllData() {
    _trafficRef.onValue.listen((event) {
      if (mounted) {
        setState(() {
          _allTrafficData = event.snapshot.value as Map<dynamic, dynamic>?;
          // Jika sudah ada CCTV yang dipilih, update datanya secara real-time
          if (_selectedCCTVId != null) {
            _findAndProcessCCTVData(_selectedCCTVId!);
          }
        });
      }
    });
  }

  // --- FUNGSI PENCARIAN CERDAS (SMART ID MATCHING) ---
  void _findAndProcessCCTVData(String uiId) {
    if (_allTrafficData == null) return;

    Map<dynamic, dynamic>? targetData;

    // Bersihkan ID dari huruf, ambil angkanya saja. Contoh: "cctv_03" -> "3"
    String cleanUiId = uiId.replaceAll(RegExp(r'[^0-9]'), '');
    if (cleanUiId.startsWith('0')) cleanUiId = cleanUiId.substring(1);

    // Loop semua key di Firebase
    _allTrafficData!.forEach((key, value) {
      String keyStr = key.toString();
      String cleanKey = keyStr.replaceAll(RegExp(r'[^0-9]'), '');

      if (cleanKey == cleanUiId) {
        targetData = value;
      }
    });

    if (targetData != null && targetData!.containsKey('daily_reports')) {
      setState(() {
        _cctvDailyReports = targetData!['daily_reports'];

        // Auto-select tanggal terbaru jika data baru dimuat dan belum ada preview
        if (_currentPreviewData == null && _cctvDailyReports != null) {
          List<String> sortedDates =
              _cctvDailyReports!.keys.cast<String>().toList();
          sortedDates.sort(); // Urutkan tanggal
          if (sortedDates.isNotEmpty) {
            _selectedDate = DateTime.parse(sortedDates.last);
          }
        }

        _updatePreviewData();
      });
    } else {
      setState(() {
        _cctvDailyReports = null;
        _currentPreviewData = null;
      });
    }
  }

  // --- PARSING DATA (HYBRID DATA LAMA & BARU) ---
  void _updatePreviewData() {
    if (_cctvDailyReports == null) {
      _currentPreviewData = null;
      return;
    }

    String dateKey = DateFormat('yyyy-MM-dd').format(_selectedDate);
    _displayedDateKey = dateKey;

    if (_cctvDailyReports!.containsKey(dateKey)) {
      final report = _cctvDailyReports![dateKey];
      Map<String, dynamic> parsedData = {};

      // 1. AMBIL TOTAL (Konsisten di semua data)
      int total = 0;
      if (report is Map && report.containsKey('total_hari_ini')) {
        total = int.tryParse(report['total_hari_ini'].toString()) ?? 0;
      }

      // 2. AMBIL DETAIL (Cek apakah Format Baru atau Lama)
      String status = "Info Terbatas"; // Default untuk data lama
      String duration = "-";
      int density = 0;
      String lastUpdate = "-";

      if (report is Map &&
          report['detail'] != null &&
          report['detail'] is Map) {
        final detail = report['detail'];

        lastUpdate = detail['last_update'] ?? '-';

        // CEK FORMAT BARU (Ada 'status_terakhir')
        if (detail.containsKey('status_terakhir')) {
          status = detail['status_terakhir'];
          duration = detail['duration_active'] ?? '-';
          density = int.tryParse(
                  detail['kepadatan_terakhir_persen']?.toString() ?? '0') ??
              0;
        }
        // FORMAT LAMA (Tidak ada status, kita set default)
        else {
          if (total > 0) status = "Data Tersimpan";
          // Duration & Density biarkan default (-)
        }
      }

      parsedData['total'] = total;
      parsedData['status'] = status;
      parsedData['duration'] = duration;
      parsedData['density'] = density;
      parsedData['last_update'] = lastUpdate;

      setState(() {
        _currentPreviewData = parsedData;
      });
    } else {
      setState(() {
        _currentPreviewData = null; // Data tanggal ini kosong
      });
    }
  }

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
            _buildFilterCard(cctvList),
            const SizedBox(height: 24),
            _buildPreviewSection(),
            const SizedBox(height: 24),
            _buildHistorySection(),
          ],
        ),
      ),
    );
  }

  // WIDGET FILTER
  Widget _buildFilterCard(List<CCTV> cctvList) {
    return Card(
      color: Theme.of(context).cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Pilih Sumber CCTV",
                style: TextStyle(color: Colors.grey, fontSize: 12)),
            const SizedBox(height: 8),
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
                        hint: const Text("Pilih CCTV...",
                            style: TextStyle(color: Colors.white54)),
                        isExpanded: true,
                        dropdownColor: const Color(0xFF2C2C2C),
                        icon: const SizedBox.shrink(),
                        items: cctvList.map((cctv) {
                          return DropdownMenuItem(
                            value: cctv.id,
                            child: Text(cctv.name,
                                style: const TextStyle(color: Colors.white),
                                overflow: TextOverflow.ellipsis),
                          );
                        }).toList(),
                        onChanged: (val) {
                          setState(() {
                            _selectedCCTVId = val;
                            if (val != null) _findAndProcessCCTVData(val);
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
                          _cctvDailyReports = null;
                          _currentPreviewData = null;
                        });
                      },
                    )
                  else
                    const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 12.0),
                        child: Icon(Icons.keyboard_arrow_down,
                            color: Colors.white54)),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Text("Pilih Tanggal Laporan",
                style: TextStyle(color: Colors.grey, fontSize: 12)),
            const SizedBox(height: 8),
            InkWell(
              onTap: () async {
                final DateTime? picked = await showDatePicker(
                  context: context,
                  initialDate: _selectedDate,
                  firstDate: DateTime(2024),
                  lastDate: DateTime(2030),
                  builder: (context, child) => Theme(
                    data: Theme.of(context).copyWith(
                        colorScheme: const ColorScheme.dark(
                            primary: Colors.blueAccent,
                            onPrimary: Colors.white,
                            surface: const Color(0xFF2C2C2C),
                            onSurface: Colors.white)),
                    child: child!,
                  ),
                );
                if (picked != null) {
                  setState(() {
                    _selectedDate = picked;
                    _updatePreviewData();
                  });
                }
              },
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                decoration: BoxDecoration(
                    color: Colors.black26,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white12)),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.calendar_today,
                            color: Colors.blueAccent, size: 20),
                        const SizedBox(width: 10),
                        Text(DateFormat('dd-MM-yyyy').format(_selectedDate),
                            style: const TextStyle(color: Colors.white)),
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

  // WIDGET PREVIEW (HANDLES OLD & NEW DATA)
  Widget _buildPreviewSection() {
    if (_selectedCCTVId == null)
      return _buildEmptyState("Pilih CCTV untuk melihat data");

    if (_currentPreviewData == null) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
            color: const Color(0xFF2C2C2C),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white10)),
        child: Column(
          children: [
            const Icon(Icons.warning_amber_rounded,
                size: 48, color: Colors.orange),
            const SizedBox(height: 12),
            Text(
                "Data Tanggal ${_formatDateDisplay(DateFormat('yyyy-MM-dd').format(_selectedDate))} Kosong",
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            const Text("Silakan pilih tanggal lain di bawah.",
                style: TextStyle(color: Colors.grey, fontSize: 12)),
          ],
        ),
      );
    }

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
          border: Border.all(color: Colors.white10)),
      child: Column(
        children: [
          const Icon(Icons.analytics, size: 48, color: Colors.white24),
          const SizedBox(height: 16),
          Text("Laporan: ${_formatDateDisplay(_displayedDateKey!)}",
              style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white)),
          const SizedBox(height: 20),
          Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
            _buildInfoColumn("Total Kendaraan", "$total", Colors.blueAccent),
            // Jika data lama (Info Terbatas), warnanya Putih/Abu. Jika data baru, warnanya sesuai status.
            _buildInfoColumn(
                "Status",
                "$status",
                status.toString().contains('Macet')
                    ? Colors.red
                    : (status == "Info Terbatas"
                        ? Colors.white70
                        : Colors.green)),
          ]),
          const SizedBox(height: 16),
          Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
            _buildInfoColumn("Durasi Aktif", "$duration", Colors.orange),
            _buildInfoColumn("Kepadatan", "$density%", Colors.white),
          ]),
          const SizedBox(height: 20),
          Text("Update Terakhir: $lastUpdate",
              style: const TextStyle(color: Colors.grey, fontSize: 10)),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text("Fitur Download PDF (Simulasi) Berhasil"))),
              icon: const Icon(Icons.download),
              label: const Text("Unduh Laporan PDF"),
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12)),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Container(
      height: 150,
      width: double.infinity,
      decoration: BoxDecoration(
          color: const Color(0xFF2C2C2C).withOpacity(0.5),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white10)),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        const Icon(Icons.touch_app, size: 48, color: Colors.white24),
        const SizedBox(height: 12),
        Text(message,
            style: const TextStyle(color: Colors.grey),
            textAlign: TextAlign.center),
      ]),
    );
  }

  Widget _buildInfoColumn(String label, String value, Color color) {
    return Column(children: [
      Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
      const SizedBox(height: 4),
      Text(value,
          style: TextStyle(
              color: color, fontWeight: FontWeight.bold, fontSize: 16)),
    ]);
  }

  // WIDGET RIWAYAT
  Widget _buildHistorySection() {
    List<String> availableDates = [];
    if (_cctvDailyReports != null) {
      availableDates = _cctvDailyReports!.keys.cast<String>().toList();
      availableDates.sort((a, b) => b.compareTo(a));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          const Text("Riwayat Tersedia (Firebase)",
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white)),
          if (availableDates.isNotEmpty)
            Text("${availableDates.length} Data",
                style: const TextStyle(color: Colors.blueAccent, fontSize: 12)),
        ]),
        const SizedBox(height: 12),
        if (_selectedCCTVId == null)
          const Text("Pilih CCTV dulu.", style: TextStyle(color: Colors.grey))
        else if (availableDates.isEmpty)
          const Text("Belum ada data riwayat sama sekali.",
              style: TextStyle(color: Colors.grey))
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: availableDates.length,
            itemBuilder: (context, index) {
              String dateKey = availableDates[index];
              final data = _cctvDailyReports![dateKey];
              int total = 0;
              if (data is Map)
                total =
                    int.tryParse(data['total_hari_ini']?.toString() ?? '0') ??
                        0;

              // Cek Status untuk List Riwayat
              String status = "Info Terbatas";
              if (data is Map &&
                  data['detail'] != null &&
                  data['detail']['status_terakhir'] != null) {
                status = data['detail']['status_terakhir'];
              } else if (total > 0) {
                status = "Data Tersimpan";
              }

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                    color: const Color(0xFF2C2C2C),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white10)),
                child: InkWell(
                  onTap: () {
                    setState(() {
                      _selectedDate = DateTime.parse(dateKey);
                      _updatePreviewData();
                    });
                  },
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                            color: Colors.blueAccent.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8)),
                        child:
                            const Icon(Icons.history, color: Colors.blueAccent),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                            Text(_formatDateDisplay(dateKey),
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white)),
                            const SizedBox(height: 4),
                            Text("Total: $total • $status",
                                style: const TextStyle(
                                    color: Colors.grey, fontSize: 12)),
                          ])),
                      const Icon(Icons.chevron_right, color: Colors.white54)
                    ],
                  ),
                ),
              );
            },
          ),
      ],
    );
  }
}
