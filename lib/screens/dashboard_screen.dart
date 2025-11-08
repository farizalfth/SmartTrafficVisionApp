import 'package:flutter/material.dart';
import 'package:smarttrafficapp/widgets/summary_card.dart'; // Import SummaryCard
import 'package:smarttrafficapp/widgets/cctv_feed_thumbnail.dart'; // Import CCTVCFeedThumbnail

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSummaryCards(context),
          const SizedBox(height: 20),
          _buildMapPlaceholder(context),
          const SizedBox(height: 20),
          _buildLiveFeedPlaceholder(context), // Pass context here
          const SizedBox(height: 20),
          _buildChartPlaceholder(context),
          const SizedBox(height: 20),
          _buildEarlyWarningPlaceholder(context),
        ],
      ),
    );
  }

  Widget _buildSummaryCards(BuildContext context) { // Menerima context
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

  Widget _buildMapPlaceholder(BuildContext context) { // Menerima context
    return Card(
      color: Theme.of(context).cardColor,
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Peta Lalu Lintas Interaktif', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 10),
            Container(
              height: 200,
              width: double.infinity,
              color: Colors.grey[800], // Placeholder for map
              child: const Center(
                child: Text('Map Placeholder', style: TextStyle(color: Colors.white54)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLiveFeedPlaceholder(BuildContext context) { // Menerima context
    // Menggunakan CCTVCFeedThumbnail yang sudah dibuat di widgets
    List<Map<String, String>> dummyCCTVs = [
      {'id': '001', 'location': 'Jl. Sudirman - Bundaran HI'},
      {'id': '002', 'location': 'Tol Jakarta - Cikampek KM 10'},
      {'id': '003', 'location': 'Jl. Gatot Subroto'},
      {'id': '004', 'location': 'Jl. Rasuna Said'},
    ];

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
            SizedBox(
              height: 120,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: dummyCCTVs.length,
                itemBuilder: (context, index) {
                  return CCTVCFeedThumbnail(
                    cctvId: dummyCCTVs[index]['id']!,
                    location: dummyCCTVs[index]['location']!,
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Tapped on CCTV ${dummyCCTVs[index]['id']}')),
                      );
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

  Widget _buildChartPlaceholder(BuildContext context) { // Menerima context
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
              color: Colors.grey[800], // Placeholder for chart
              child: const Center(
                child: Text('Chart Placeholder', style: TextStyle(color: Colors.white54)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEarlyWarningPlaceholder(BuildContext context) { // Menerima context
    return Card(
      color: Colors.red[800], // Warna khusus untuk peringatan
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            const Icon(Icons.warning, color: Colors.white, size: 30),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'PERINGATAN DINI: Kepadatan Ekstrem di Jl. Gatot Subroto. Gunakan jalur alternatif.',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}