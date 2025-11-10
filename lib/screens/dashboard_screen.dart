import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:smarttrafficapp/widgets/summary_card.dart';
import 'package:smarttrafficapp/widgets/cctv_feed_thumbnail.dart';
import 'package:smarttrafficapp/services/api_service.dart';
import 'package:smarttrafficapp/models/cctv.dart';
import 'package:smarttrafficapp/screens/live_cctv_screen.dart'; // Import LiveCCTVScreen

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final ApiService _apiService = ApiService();
  List<CCTV> _cctvList = [];
  bool _isLoadingCCTVs = true;
  Set<Marker> _markers = {};

  // Initial Camera Position untuk Jawa Tengah
  static const CameraPosition _initialCameraPosition = CameraPosition(
    target: LatLng(-7.150975, 110.140259), // Pusat Jawa Tengah (kurang lebih)
    zoom: 8, // Zoom level agar Jawa Tengah terlihat semua
  );

  @override
  void initState() {
    super.initState();
    _fetchCCTVsAndSetupMap();
  }

  Future<void> _fetchCCTVsAndSetupMap() async {
    try {
      final cctvs = await _apiService.getCCTVs();
      if (mounted) {
        setState(() {
          _cctvList = cctvs;
          _isLoadingCCTVs = false;
          _markers = cctvs.map((cctv) {
            return Marker(
              markerId: MarkerId(cctv.id),
              position: LatLng(cctv.latitude, cctv.longitude),
              infoWindow: InfoWindow(
                title: cctv.name,
                snippet: cctv.location,
                onTap: () {
                  // Aksi saat marker ditekan: navigasi ke LiveCCTVScreen
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
              ),
              icon: cctv.status == 'Online'
                  ? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen)
                  : BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
            );
          }).toSet();
        });
      }
    } catch (e) {
      print('Error fetching CCTV list: $e');
      if (mounted) {
        setState(() {
          _isLoadingCCTVs = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSummaryCards(context),
          const SizedBox(height: 20),
          _buildMapSection(context), // Menggunakan nama baru untuk membedakan dengan placeholder
          const SizedBox(height: 20),
          _buildLiveFeedPlaceholder(context),
          const SizedBox(height: 20),
          _buildChartPlaceholder(context),
          const SizedBox(height: 20),
          _buildEarlyWarningPlaceholder(context),
        ],
      ),
    );
  }

  Widget _buildSummaryCards(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        SummaryCard(
          title: 'Total Kendaraan Terdeteksi Hari Ini',
          value: '15,450',
          valueColor: Colors.green,
          icon: Icons.directions_car,
        ),
        SummaryCard(
          title: 'Rata-rata Kepadatan',
          value: '65%',
          valueColor: Colors.orange,
          icon: Icons.traffic,
        ),
        SummaryCard(
          title: 'Peringatan Macet (Aktif)',
          value: '3',
          valueColor: Colors.red,
          icon: Icons.warning,
        ),
      ],
    );
  }

  Widget _buildMapSection(BuildContext context) {
    return Card(
      color: Theme.of(context).cardColor,
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Peta Lalu Lintas Interaktif Jawa Tengah', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 10),
            _isLoadingCCTVs
                ? Container(
                    height: 200,
                    width: double.infinity,
                    color: Colors.grey[800],
                    child: const Center(
                      child: CircularProgressIndicator(),
                    ),
                  )
                : Container(
                    height: 200,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8.0),
                      border: Border.all(color: Colors.white12),
                    ),
                    child: GoogleMap(
                      mapType: MapType.normal,
                      initialCameraPosition: _initialCameraPosition,
                      onMapCreated: (GoogleMapController controller) {
                        // Anda bisa menyimpan controller untuk interaksi lebih lanjut
                      },
                      markers: _markers, // Tampilkan marker CCTV
                      myLocationButtonEnabled: false,
                      zoomControlsEnabled: false,
                    ),
                  ),
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton.icon(
                onPressed: () {
                  _showRoutePlanningDialog(context);
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

  Future<void> _showRoutePlanningDialog(BuildContext context) async {
    TextEditingController destinationController = TextEditingController();
    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Rencanakan Rute'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: destinationController,
                decoration: const InputDecoration(
                  labelText: 'Lokasi Tujuan (misal: Semarang Tawang)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Fitur ini akan menghitung rute terbaik berdasarkan data kepadatan CCTV. '
                'Integrasi dengan layanan peta eksternal dan analisis Machine Learning '
                'di backend diperlukan untuk fungsionalitas penuh.',
                style: TextStyle(fontSize: 12, color: Colors.white70),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () {
                if (destinationController.text.isNotEmpty) {
                  // Ini akan memanggil backend Anda (atau langsung API peta)
                  // untuk mendapatkan rute dan data lalu lintas.
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                            'Mencari rute ke: ${destinationController.text}...\n'
                            'Memerlukan integrasi API Routing dan Data Lalu Lintas.'),
                      ),
                    );
                    Navigator.of(context).pop();
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
            _isLoadingCCTVs
                ? const Center(child: CircularProgressIndicator())
                : SizedBox(
                    height: 120,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _cctvList.length,
                      itemBuilder: (context, index) {
                        final cctv = _cctvList[index];
                        return CCTVCFeedThumbnail(
                          cctvId: cctv.id,
                          location: cctv.location,
                          // Contoh placeholder untuk tingkat kepadatan dari analisis ML
                          congestionLevel: cctv.status == 'Online' ? 'Padat (60%)' : 'Offline',
                          onTap: () {
                            // Navigasi ke detail CCTV, bisa dengan parameter
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
            Container(
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

  Widget _buildEarlyWarningPlaceholder(BuildContext context) {
    return Card(
      color: Colors.red[800],
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            const Icon(Icons.warning, color: Colors.white, size: 30),
            const SizedBox(width: 10),
            Expanded(
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