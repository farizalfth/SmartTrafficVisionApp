import 'package:flutter/material.dart';
import 'package:smarttrafficapp/widgets/cctv_feed_thumbnail.dart'; // Import CCTVCFeedThumbnail

class LiveCCTVScreen extends StatelessWidget {
  const LiveCCTVScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Live CCTV View', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 16),
          _buildMainCCTVFeed(context),
          const SizedBox(height: 20),
          _buildCCTVGrid(context),
        ],
      ),
    );
  }

  Widget _buildMainCCTVFeed(BuildContext context) { // Menerima context
    return Card(
      color: Theme.of(context).cardColor,
      elevation: 4,
      child: Column(
        children: [
          Container(
            height: 250,
            width: double.infinity,
            color: Colors.grey[800], // Placeholder for main video stream
            child: const Center(
              child: Text('Main CCTV Stream', style: TextStyle(color: Colors.white54)),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Kepadatan: Macet (85%)',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.red),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Kecepatan Rata-rata: 15 km/jam', style: Theme.of(context).textTheme.bodyMedium),
                    Text('Jumlah Kendaraan Terdeteksi: 237', style: Theme.of(context).textTheme.bodyMedium),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCCTVGrid(BuildContext context) { // Menerima context
    List<Map<String, String>> dummyCCTVs = [
      {'id': '001', 'location': 'Jl. Jakarta - Botumpuk KM 10'},
      {'id': '002', 'location': 'Jl. Jakarta - Cikarang KM 10'},
      {'id': '003', 'location': 'Jl. Sudirman - Bundaran HI'},
      {'id': '004', 'location': 'Tol Jakarta - Cilegon KM 10'},
      {'id': '005', 'location': 'Jl. Gatot Subroto'},
      {'id': '006', 'location': 'Jl. Asia Afrika'},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('CCTV Lainnya', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 10),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 1.5,
          ),
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
      ],
    );
  }
}