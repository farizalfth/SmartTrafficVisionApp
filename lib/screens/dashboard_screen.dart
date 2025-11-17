import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:smarttrafficapp/screens/chat_screen.dart';
import 'package:smarttrafficapp/widgets/summary_card.dart';
import 'package:smarttrafficapp/widgets/cctv_feed_thumbnail.dart';
import 'package:smarttrafficapp/services/api_service.dart';
import 'package:smarttrafficapp/models/cctv.dart';
import 'package:smarttrafficapp/screens/live_cctv_screen.dart'; // Import LiveCCTVScreen
import 'dart:io' show Platform; // Untuk mendeteksi jenis platform OS (misal: Linux)
import 'package:flutter/foundation.dart' show kIsWeb; // Untuk mendeteksi apakah aplikasi berjalan di web

/// Widget utama untuk tampilan Dashboard aplikasi.
/// Ini adalah StatefulWidget karena state-nya (data CCTV, status loading, markers peta) dapat berubah.
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

/// State untuk DashboardScreen. Mengelola data dan logika tampilan dashboard.
class _DashboardScreenState extends State<DashboardScreen> {
  // Instance dari ApiService untuk mengambil data dari backend.
  final ApiService _apiService = ApiService();
  // List untuk menyimpan objek CCTV yang diambil dari API.
  List<CCTV> _cctvList = [];
  // Flag untuk menunjukkan status loading data CCTV.
  bool _isLoadingCCTVs = true;
  // Set of Marker untuk menampilkan lokasi CCTV di Google Map.
  Set<Marker> _markers = {};

  // Posisi kamera awal untuk peta (pusat Jawa Tengah dengan zoom level 8).
  static const CameraPosition _initialCameraPosition = CameraPosition(
    target: LatLng(-7.150975, 110.140259), // Koordinat lintang dan bujur
    zoom: 8, // Tingkat zoom
  );

  /// Dipanggil sekali saat widget pertama kali dibuat.
  /// Digunakan untuk inisialisasi state, seperti memuat data.
  @override
  void initState() {
    super.initState();
    _fetchCCTVsAndSetupMap(); // Memanggil fungsi untuk mengambil data CCTV dan menyiapkan peta.
  }

  /// Fungsi asinkron untuk mengambil daftar CCTV dari API dan menyiapkan marker peta.
  Future<void> _fetchCCTVsAndSetupMap() async {
    try {
      final cctvs = await _apiService.getCCTVs(); // Mengambil data CCTV dari API.
      if (mounted) {
        setState(() {
          _cctvList = cctvs; // Memperbarui list CCTV.
          _isLoadingCCTVs = false; // Mengatur status loading menjadi false.

          // Hanya membuat markers jika aplikasi tidak berjalan di Linux Desktop.
          // Ini mencegah error dari plugin google_maps_flutter yang tidak mendukung Linux.
          if (!(!kIsWeb && Platform.isLinux)) {
            _markers = cctvs.map((cctv) {
              return Marker(
                markerId: MarkerId(cctv.id), // ID unik untuk marker
                position: LatLng(cctv.latitude, cctv.longitude), // Posisi marker
                infoWindow: InfoWindow(
                  title: cctv.name, // Judul yang muncul saat marker diklik
                  snippet: cctv.location, // Sub-judul info window
                  onTap: () {
                    // Aksi saat info window di marker ditekan: navigasi ke LiveCCTVScreen.
                    if (mounted) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => LiveCCTVScreen(
                            initialCCTVId: cctv.id, // Meneruskan ID CCTV ke layar detail
                          ),
                        ),
                      );
                    }
                  },
                ),
                // Mengatur warna ikon marker berdasarkan status CCTV (online/offline).
                icon: cctv.status == 'Online'
                    ? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen)
                    : BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
              );
            }).toSet(); // Mengubah list markers menjadi Set.
          }
        });
      }
    } catch (e) {
      // Menangani error jika gagal mengambil data CCTV.
      print('Error fetching CCTV list: $e');
      if (mounted) {
        setState(() {
          _isLoadingCCTVs = false;
        });
        // Menampilkan Snackbar dengan pesan error.
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    }
  }

  /// Metode build yang mendefinisikan struktur UI dari dashboard.
  @override
  Widget build(BuildContext context) {
    return Scaffold( // Menyediakan struktur visual dasar material design.
      appBar: AppBar( // Bilah aplikasi di bagian atas layar.
        title: const Text('Dashboard'), // Judul AppBar.
        backgroundColor: Colors.transparent, // Warna latar belakang AppBar.
        elevation: 0, // Mengatur bayangan AppBar.
        actions: [
          // Tombol Chatbot di AppBar.
          IconButton(
            icon: const Icon(Icons.chat_bubble_outline), // Ikon gelembung chat.
            tooltip: 'Tanya AI Lalu Lintas', // Teks tooltip.
            onPressed: () {
              // Navigasi ke ChatScreen saat tombol ditekan.
              Navigator.push(context, MaterialPageRoute(builder: (context) => const ChatScreen()));
            },
          ),
          // Tombol Search di AppBar.
          IconButton(
            icon: const Icon(Icons.search), // Ikon pencarian.
            onPressed: () {
            },
          ),
          // Tombol Notifikasi di AppBar.
          IconButton(
            icon: const Icon(Icons.notifications_none), // Ikon notifikasi.
            onPressed: () {
            },
          ),
        ],
      ),
      body: SingleChildScrollView( // Memungkinkan konten dapat digulir jika melebihi tinggi layar.
        padding: const EdgeInsets.all(16.0), // Padding di sekitar seluruh konten.
        child: Column( // Mengatur widget secara vertikal.
          crossAxisAlignment: CrossAxisAlignment.start, // Menyelaraskan konten ke kiri.
          children: [
            _buildSummaryCards(context), // Membangun bagian kartu ringkasan.
            const SizedBox(height: 20), // Memberikan jarak vertikal.
            _buildMapSection(context), // Membangun bagian peta.
            const SizedBox(height: 20),
            _buildLiveFeedPlaceholder(context), // Membangun bagian live feed CCTV.
            const SizedBox(height: 20),
            _buildChartPlaceholder(context), // Membangun bagian placeholder chart.
            const SizedBox(height: 20),
            _buildEarlyWarningPlaceholder(context), // Membangun bagian peringatan dini.
          ],
        ),
      ),
    );
  }

  /// Membangun baris kartu ringkasan di bagian atas dashboard.
  Widget _buildSummaryCards(BuildContext context) {
    return Row( // Mengatur kartu secara horizontal.
      mainAxisAlignment: MainAxisAlignment.spaceAround, // Meratakan ruang di sekitar kartu.
      children: [
        SummaryCard( // Kartu untuk total kendaraan.
          title: 'Total Kendaraan Terdeteksi Hari Ini',
          value: '15,450',
          valueColor: Colors.green,
          icon: Icons.directions_car,
        ),
        SummaryCard( // Kartu untuk rata-rata kepadatan.
          title: 'Rata-rata Kepadatan',
          value: '65%',
          valueColor: Colors.orange,
          icon: Icons.traffic,
        ),
        SummaryCard( // Kartu untuk peringatan macet aktif.
          title: 'Peringatan Macet (Aktif)',
          value: '3',
          valueColor: Colors.red,
          icon: Icons.warning,
        ),
      ],
    );
  }

  /// Membangun bagian peta interaktif.
  Widget _buildMapSection(BuildContext context) {
    // Deteksi apakah platform saat ini adalah Linux Desktop.
    // Ini digunakan untuk menampilkan placeholder jika Google Maps tidak didukung.
    final bool isLinuxDesktop = !kIsWeb && Platform.isLinux;

    return Card( // Menggunakan Card sebagai wadah dengan elevasi dan warna.
      color: Theme.of(context).cardColor,
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Peta Lalu Lintas Interaktif Jawa Tengah', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 10),
            _isLoadingCCTVs // Menampilkan indikator loading jika data CCTV masih dimuat.
                ? Container(
                    height: 200,
                    width: double.infinity,
                    color: Colors.grey[800],
                    child: const Center(
                      child: CircularProgressIndicator(),
                    ),
                  )
                : Container( // Wadah untuk peta atau placeholder.
                    height: 200,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8.0),
                      border: Border.all(color: Colors.white12),
                    ),
                    child: isLinuxDesktop // Jika di Linux Desktop, tampilkan teks placeholder.
                        ? const Center(
                            child: Text(
                              'Peta tidak didukung di Linux Desktop.',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.white54),
                            ),
                          )
                        : GoogleMap( // Jika bukan Linux Desktop, tampilkan GoogleMap.
                            mapType: MapType.normal, // Jenis peta (normal, satelit, dll.)
                            initialCameraPosition: _initialCameraPosition, // Posisi awal kamera.
                            onMapCreated: (GoogleMapController controller) {
                              // Callback saat peta selesai dibuat.
                              // Anda bisa menyimpan controller untuk interaksi lebih lanjut dengan peta.
                            },
                            markers: _markers, // Menampilkan marker CCTV di peta.
                            myLocationButtonEnabled: false, // Menyembunyikan tombol lokasi saya.
                            zoomControlsEnabled: false, // Menyembunyikan kontrol zoom.
                          ),
                  ),
            const SizedBox(height: 10),
            Align( // Menyelaraskan tombol ke kanan.
              alignment: Alignment.centerRight,
              child: ElevatedButton.icon( // Tombol untuk mendapatkan rute.
                onPressed: () {
                  _showRoutePlanningDialog(context); // Menampilkan dialog perencanaan rute.
                },
                icon: const Icon(Icons.route),
                label: const Text('Dapatkan Rute & Hindari Macet'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Menampilkan dialog untuk perencanaan rute.
  Future<void> _showRoutePlanningDialog(BuildContext context) async {
    TextEditingController destinationController = TextEditingController(); // Controller untuk input tujuan.
    await showDialog( // Menampilkan dialog.
      context: context,
      builder: (context) {
        return AlertDialog( // Dialog Material Design.
          title: const Text('Rencanakan Rute'),
          content: Column(
            mainAxisSize: MainAxisSize.min, // Membuat kolom seukuran kontennya.
            children: [
              TextFormField( // Input field untuk lokasi tujuan.
                controller: destinationController,
                decoration: const InputDecoration(
                  labelText: 'Lokasi Tujuan (misal: Semarang Tawang)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              const Text( // Deskripsi fitur perencanaan rute.
                'Fitur ini akan menghitung rute terbaik berdasarkan data kepadatan CCTV. '
                'Integrasi dengan layanan peta eksternal dan analisis Machine Learning '
                'di backend diperlukan untuk fungsionalitas penuh.',
                style: TextStyle(fontSize: 12, color: Colors.white70),
              ),
            ],
          ),
          actions: [
            TextButton( // Tombol Batal.
              onPressed: () => Navigator.of(context).pop(), // Menutup dialog.
              child: const Text('Batal'),
            ),
            ElevatedButton( // Tombol Cari Rute.
              onPressed: () {
                if (destinationController.text.isNotEmpty) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar( // Menampilkan Snackbar.
                      SnackBar(
                        content: Text(
                            'Mencari rute ke: ${destinationController.text}...\n'
                            'Memerlukan integrasi API Routing dan Data Lalu Lintas.'),
                      ),
                    );
                    Navigator.of(context).pop(); // Menutup dialog setelah mencari rute.
                  }
                }
              },
              child: const Text('Cari Rute'),
            ),
          ],
        );
      },
    );
  }

  /// Membangun bagian live feed CCTV utama.
  Widget _buildLiveFeedPlaceholder(BuildContext context) {
    return Card(
      color: Theme.of(context).cardColor,
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Live Feed CCTV Utama', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 10),
            _isLoadingCCTVs // Menampilkan indikator loading jika data CCTV masih dimuat.
                ? const Center(child: CircularProgressIndicator())
                : SizedBox(
                    height: 120, // Mengatur tinggi untuk ListView horizontal.
                    child: ListView.builder( // Membuat daftar CCTV secara horizontal.
                      scrollDirection: Axis.horizontal, // Arah gulir horizontal.
                      itemCount: _cctvList.length, // Jumlah item sesuai jumlah CCTV.
                      itemBuilder: (context, index) {
                        final cctv = _cctvList[index];
                        return CCTVCFeedThumbnail( // Widget thumbnail untuk setiap CCTV.
                          cctvId: cctv.id,
                          location: cctv.location,
                          // Menampilkan tingkat kepadatan berdasarkan status CCTV.
                          congestionLevel: cctv.status == 'Online' ? 'Padat (60%)' : 'Offline',
                          onTap: () {
                            // Navigasi ke LiveCCTVScreen saat thumbnail ditekan.
                            if (mounted) {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => LiveCCTVScreen(
                                    initialCCTVId: cctv.id,
                                  ),
                                ),
                              );
                            }
                          },
                        );
                      },
                    ),
                  ),
          ],
        ),
      ),
    );
  }

  /// Membangun bagian placeholder untuk chart tren kepadatan.
  Widget _buildChartPlaceholder(BuildContext context) {
    return Card(
      color: Theme.of(context).cardColor,
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Tren Kepadatan (Minggu Ini)', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 10),
            Container( // Placeholder visual untuk chart.
              height: 150,
              color: Colors.grey[800],
              child: const Center(
                child: Text(
                  'Chart Placeholder (Data dari Analisis ML)',
                  style: TextStyle(color: Colors.white54),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Membangun bagian peringatan dini.
  Widget _buildEarlyWarningPlaceholder(BuildContext context) {
    return Card(
      color: Colors.red[800], // Warna latar belakang kartu peringatan (merah).
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row( // Mengatur ikon dan teks secara horizontal.
          children: [
            const Icon(Icons.warning, color: Colors.white, size: 30), // Ikon peringatan.
            const SizedBox(width: 10),
            Expanded( // Memungkinkan teks mengisi sisa ruang yang tersedia.
              child: Text(
                'PERINGATAN DINI: Kepadatan Ekstrem di Jl. Gatot Subroto, Semarang. Gunakan jalur alternatif.',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}