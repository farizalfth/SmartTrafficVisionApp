import 'package:flutter/material.dart';

class ReportScreen extends StatelessWidget {
  const ReportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Laporan Otomatis', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 16),
          _buildReportOptions(context),
          const SizedBox(height: 20),
          _buildRecentReports(context),
        ],
      ),
    );
  }

  Widget _buildReportOptions(BuildContext context) { // Menerima context
    return Card(
      color: Theme.of(context).cardColor,
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Jenis Laporan', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 10),
            Row(
              children: [
                _buildReportButton(context, 'Harian', Icons.calendar_today),
                const SizedBox(width: 10),
                _buildReportButton(context, 'Mingguan', Icons.calendar_view_week),
                const SizedBox(width: 10),
                _buildReportButton(context, 'Bulanan', Icons.calendar_month),
              ],
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Generate Laporan Baru')),
                );
              },
              icon: const Icon(Icons.generating_tokens),
              label: const Text('Generate Laporan Sekarang'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                textStyle: const TextStyle(fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReportButton(BuildContext context, String text, IconData icon) { // Menerima context
    return Expanded(
      child: OutlinedButton.icon(
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Pilih Laporan $text')),
          );
        },
        icon: Icon(icon, color: Colors.blue),
        label: Text(text, style: TextStyle(color: Colors.blue)),
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: Colors.blue),
          padding: const EdgeInsets.symmetric(vertical: 10),
        ),
      ),
    );
  }

  Widget _buildRecentReports(BuildContext context) { // Menerima context
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Laporan Terbaru', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 10),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: 3, // Example reports
          itemBuilder: (context, index) {
            return Card(
              color: Theme.of(context).cardColor,
              margin: const EdgeInsets.symmetric(vertical: 8.0),
              elevation: 2,
              child: ListTile(
                leading: const Icon(Icons.picture_as_pdf, color: Colors.red),
                title: Text('Laporan Harian - 2024-07-0${index + 1}', style: Theme.of(context).textTheme.bodyLarge),
                subtitle: Text('Ukuran: 1.2 MB | Dibuat: 08:00 AM', style: Theme.of(context).textTheme.bodyMedium),
                trailing: IconButton(
                  icon: const Icon(Icons.download, color: Colors.blue),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Unduh Laporan Harian ${index + 1}')),
                    );
                  },
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}