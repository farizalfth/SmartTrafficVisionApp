import 'package:flutter/material.dart';

class AnalyticsScreen extends StatelessWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Statistik & Analitik', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 16),
          _buildChartCard(context, 'Tren Kepadatan Harian (Bulan Ini)'),
          const SizedBox(height: 20),
          _buildPieChartCard(context, 'Distribusi Kendaraan Berdasarkan Tipe'),
          const SizedBox(height: 20),
          _buildRankingCard(context, 'Peringkat Titik Terpadat (Minggu Ini)'),
        ],
      ),
    );
  }

  Widget _buildChartCard(BuildContext context, String title) { // Menerima context
    return Card(
      color: Theme.of(context).cardColor,
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 10),
            Container(
              height: 200,
              color: Colors.grey[800], // Placeholder for line/bar chart
              child: Center(
                child: Text('Chart Placeholder', style: TextStyle(color: Colors.white54)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPieChartCard(BuildContext context, String title) { // Menerima context
    return Card(
      color: Theme.of(context).cardColor,
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 10),
            Row(
              children: [
                Container(
                  width: 120,
                  height: 120,
                  color: Colors.grey[800], // Placeholder for pie chart
                  child: const Center(
                    child: Text('Pie', style: TextStyle(color: Colors.white54)),
                  ),
                ),
                const SizedBox(width: 20),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildLegendItem(context, Colors.blue, 'Mobil (60%)'),
                    _buildLegendItem(context, Colors.yellow, 'Truk/Bus (25%)'),
                    _buildLegendItem(context, Colors.red, 'Lainnya (15%)'),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendItem(BuildContext context, Color color, String text) { // Menerima context
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Container(
            width: 16,
            height: 16,
            color: color,
          ),
          const SizedBox(width: 8),
          Text(text, style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }

  Widget _buildRankingCard(BuildContext context, String title) { // Menerima context
    return Card(
      color: Theme.of(context).cardColor,
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 10),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: 3, // Example items
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Row(
                    children: [
                      Text('${index + 1}.', style: Theme.of(context).textTheme.bodyLarge),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Jl. Jakarta - Cikampek KM ${10 + index}',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                      Text('75%', style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.red)),
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