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
  static const String _dbUrl =
      'https://smart-traffic-vision-app-default-rtdb.asia-southeast1.firebasedatabase.app/';
  late final DatabaseReference _trafficRef;

  String? _selectedCCTVId;
  DateTime _selectedDate = DateTime.now();
  String? _displayedDateKey;

  Map<dynamic, dynamic>? _allTrafficData;
  Map<String, dynamic>? _currentPreviewData;
  Map<dynamic, dynamic>? _cctvDailyReports;

  bool get _isTodaySelected {
    final now = DateTime.now();
    return _selectedDate.year == now.year &&
        _selectedDate.month == now.month &&
        _selectedDate.day == now.day;
  }

  @override
  void initState() {
    super.initState();
    final firebaseApp = Firebase.app();
    final rtdb = FirebaseDatabase.instanceFor(app: firebaseApp, databaseURL: _dbUrl);
    _trafficRef = rtdb.ref('traffic_stats');

    _listenToAllData();
  }

  void _listenToAllData() {
    _trafficRef.onValue.listen((event) {
      if (mounted) {
        setState(() {
          _allTrafficData = event.snapshot.value as Map<dynamic, dynamic>?;
          _updatePreviewData();
        });
      }
    });
  }

  void _updatePreviewData() {
    if (_selectedCCTVId == null || _allTrafficData == null) {
      setState(() {
        _currentPreviewData = null;
        _cctvDailyReports = null;
      });
      return;
    }

    // --- LOGIKA MAPPING ID ---
    // Mengubah "cctv_03" atau "03" menjadi "3" agar sesuai database
    String cleanId = _selectedCCTVId!.replaceAll(RegExp(r'[^0-9]'), '');
    while (cleanId.startsWith('0') && cleanId.length > 1) {
      cleanId = cleanId.substring(1);
    }
    
    final cctvData = _allTrafficData![cleanId];
    if (cctvData == null) {
      setState(() {
        _currentPreviewData = null;
        _cctvDailyReports = null;
      });
      return;
    }

    // Simpan list daily reports untuk bagian riwayat di bawah
    _cctvDailyReports = cctvData['daily_reports'];

    String dateKey = DateFormat('yyyy-MM-dd').format(_selectedDate);
    _displayedDateKey = dateKey;

    Map<String, dynamic> parsedData = {};

    // ==========================================
    // 1. CEK DATA HARI INI (LIVE)
    // ==========================================
    if (_isTodaySelected) {
      final live = cctvData['live'];
      if (live != null) {
        parsedData['total'] = live['total_akumulasi_hari_ini'] ?? 0;
        parsedData['status'] = live['status'] ?? 'Mendeteksi...';
        parsedData['duration'] = live['session_duration'] ?? '-';
        parsedData['density'] = int.tryParse(live['kepadatan_persen']?.toString() ?? '0') ?? 0;
        parsedData['last_update'] = live['last_update'] ?? '-';
        parsedData['is_live'] = true;
      }
    } 
    
    // ==========================================
    // 2. CEK DATA MASA LAMPAU (DAILY REPORTS)
    // ==========================================
    // Jika tidak ada data live hari ini ATAU memang pilih tanggal lampau
    if (parsedData.isEmpty || !_isTodaySelected) {
      final reports = cctvData['daily_reports'];
      if (reports != null && reports.containsKey(dateKey)) {
        final report = reports[dateKey];
        parsedData['total'] = report['total_hari_ini'] ?? 0;
        
        final detail = report['detail'];
        if (detail != null) {
          parsedData['status'] = detail['status_terakhir'] ?? 'Selesai';
          parsedData['duration'] = detail['duration_active'] ?? '-';
          parsedData['density'] = int.tryParse(detail['kepadatan_terakhir_persen']?.toString() ?? '0') ?? 0;
          parsedData['last_update'] = detail['last_update'] ?? '-';
        }
        parsedData['is_live'] = false;
      }
    }

    setState(() {
      _currentPreviewData = parsedData.isEmpty ? null : parsedData;
    });
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

    return Scaffold(
      appBar: AppBar(
        title: const Text('Laporan Otomatis'),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () => Scaffold.of(context).openDrawer(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildFilterCard(cctvProvider.cctvList),
            const SizedBox(height: 24),
            _buildPreviewSection(),
            const SizedBox(height: 24),
            _buildHistorySection(),
          ],
        ),
      ),
    );
  }

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
            DropdownButtonFormField<String>(
              value: _selectedCCTVId,
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.black26,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12),
              ),
              hint: const Text("Pilih CCTV...", style: TextStyle(color: Colors.white54)),
              items: cctvList.map((c) => DropdownMenuItem(value: c.id, child: Text(c.name, overflow: TextOverflow.ellipsis))).toList(),
              onChanged: (val) {
                setState(() {
                  _selectedCCTVId = val;
                  _updatePreviewData();
                });
              },
            ),
            const SizedBox(height: 16),
            const Text("Pilih Tanggal Laporan", style: TextStyle(color: Colors.grey, fontSize: 12)),
            const SizedBox(height: 8),
            InkWell(
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _selectedDate,
                  firstDate: DateTime(2024),
                  lastDate: DateTime.now(),
                );
                if (picked != null) {
                  setState(() {
                    _selectedDate = picked;
                    _updatePreviewData();
                  });
                }
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                decoration: BoxDecoration(color: Colors.black26, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.white12)),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(children: [
                      const Icon(Icons.calendar_today, color: Colors.blueAccent, size: 20),
                      const SizedBox(width: 10),
                      Text(DateFormat('dd-MM-yyyy').format(_selectedDate), style: const TextStyle(color: Colors.white)),
                    ]),
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

  Widget _buildPreviewSection() {
    if (_selectedCCTVId == null) return _buildEmptyState("Silakan pilih CCTV");

    if (_currentPreviewData == null) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(color: const Color(0xFF2C2C2C), borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.white10)),
        child: Column(
          children: [
            const Icon(Icons.warning_amber_rounded, size: 50, color: Colors.orange),
            const SizedBox(height: 16),
            Text("Data Tanggal ${_formatDateDisplay(_displayedDateKey ?? '')} Kosong", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text("Silakan pilih tanggal yang tersedia di riwayat bawah.", style: TextStyle(color: Colors.grey, fontSize: 12), textAlign: TextAlign.center),
          ],
        ),
      );
    }

    final data = _currentPreviewData!;
    final bool isLive = data['is_live'] ?? false;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
          color: const Color(0xFF2C2C2C),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isLive ? Colors.blueAccent.withOpacity(0.5) : Colors.white10)),
      child: Column(
        children: [
          Text(isLive ? "🔴 LIVE HARI INI" : "📄 LAPORAN RIWAYAT",
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: isLive ? Colors.redAccent : Colors.blueAccent)),
          const SizedBox(height: 12),
          Text("Tanggal: ${_formatDateDisplay(_displayedDateKey!)}", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
          const Divider(height: 32, color: Colors.white10),
          Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
            _buildInfoColumn("Total Kendaraan", "${data['total']}", Colors.blueAccent),
            _buildInfoColumn("Kepadatan", "${data['density']}%", data['density'] > 70 ? Colors.red : Colors.green),
          ]),
          const SizedBox(height: 24),
          Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
            _buildInfoColumn("Durasi Aktif", "${data['duration']}", Colors.orange),
            _buildInfoColumn("Status", "${data['status']}", Colors.white),
          ]),
          const SizedBox(height: 24),
          Text("Update Terakhir: ${data['last_update']}", style: const TextStyle(color: Colors.grey, fontSize: 10)),
        ],
      ),
    );
  }

  Widget _buildHistorySection() {
    if (_cctvDailyReports == null) return const SizedBox();

    final availableDates = _cctvDailyReports!.keys.cast<String>().toList();
    availableDates.sort((a, b) => b.compareTo(a));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Riwayat Tersedia (Firebase)", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
        const SizedBox(height: 12),
        ...availableDates.map((dateKey) => ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16),
          tileColor: const Color(0xFF2C2C2C),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          leading: const Icon(Icons.history, color: Colors.blueAccent),
          title: Text(_formatDateDisplay(dateKey), style: const TextStyle(color: Colors.white)),
          subtitle: Text("Total: ${_cctvDailyReports![dateKey]['total_hari_ini']}", style: const TextStyle(color: Colors.grey, fontSize: 12)),
          trailing: const Icon(Icons.chevron_right, color: Colors.white54),
          onTap: () {
            setState(() {
              _selectedDate = DateTime.parse(dateKey);
              _updatePreviewData();
            });
          },
        )).toList(),
      ],
    );
  }

  Widget _buildEmptyState(String msg) {
    return Container(
      height: 150, width: double.infinity,
      decoration: BoxDecoration(color: const Color(0xFF2C2C2C).withOpacity(0.5), borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.white10)),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        const Icon(Icons.analytics_outlined, size: 48, color: Colors.white24),
        const SizedBox(height: 12),
        Text(msg, style: const TextStyle(color: Colors.grey)),
      ]),
    );
  }

  Widget _buildInfoColumn(String label, String value, Color color) {
    return Column(children: [
      Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
      const SizedBox(height: 4),
      Text(value, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 18)),
    ]);
  }
}