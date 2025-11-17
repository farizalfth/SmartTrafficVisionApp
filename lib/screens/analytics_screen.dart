import 'package:flutter/material.dart';

/// Widget untuk menampilkan halaman Analitik dan Statistik.
/// Ini adalah StatelessWidget karena semua kontennya bersifat statis (placeholder)
/// dan tidak ada state yang berubah di dalamnya.
class AnalyticsScreen extends StatelessWidget {
  const AnalyticsScreen({super.key});

  /// Metode build yang mendefinisikan struktur UI dari halaman analitik.
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView( // Memungkinkan konten dapat digulir jika melebihi tinggi layar.
      padding: const EdgeInsets.all(16.0), // Padding di sekitar seluruh konten.
      child: Column( // Mengatur widget anak-anak secara vertikal.
        crossAxisAlignment: CrossAxisAlignment.start, // Menyelaraskan konten ke kiri.
        children: [
          // Judul utama halaman.
          Text('Statistik & Analitik', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 16), // Jarak vertikal.

          // Membangun kartu untuk menampilkan chart tren kepadatan harian.
          _buildChartCard(context, 'Tren Kepadatan Harian (Bulan Ini)'),
          const SizedBox(height: 20), // Jarak vertikal.

          // Membangun kartu untuk menampilkan pie chart distribusi kendaraan.
          _buildPieChartCard(context, 'Distribusi Kendaraan Berdasarkan Tipe'),
          const SizedBox(height: 20), // Jarak vertikal.

          // Membangun kartu untuk menampilkan peringkat titik terpadat.
          _buildRankingCard(context, 'Peringkat Titik Terpadat (Minggu Ini)'),
        ],
      ),
    );
  }

  /// Fungsi pembantu untuk membangun kartu yang berisi chart (placeholder).
  /// [context] digunakan untuk mengakses Theme data.
  /// [title] adalah judul yang akan ditampilkan di kartu chart.
  Widget _buildChartCard(BuildContext context, String title) {
    return Card( // Widget Card sebagai wadah visual.
      color: Theme.of(context).cardColor, // Mengambil warna kartu dari tema.
      elevation: 4, // Efek bayangan kartu.
      child: Padding(
        padding: const EdgeInsets.all(16.0), // Padding di dalam kartu.
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium), // Menampilkan judul chart.
            const SizedBox(height: 10), // Jarak vertikal.
            Container( // Placeholder visual untuk area chart.
              height: 200,
              width: double.infinity, // Lebar penuh
              color: Colors.grey[800], // Warna latar belakang placeholder.
              child: const Center(
                child: Text('Chart Placeholder', style: TextStyle(color: Colors.white54)), // Teks placeholder.
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Fungsi pembantu untuk membangun kartu yang berisi pie chart (placeholder)
  /// beserta legendanya.
  /// [context] digunakan untuk mengakses Theme data.
  /// [title] adalah judul yang akan ditampilkan di kartu pie chart.
  Widget _buildPieChartCard(BuildContext context, String title) {
    return Card(
      color: Theme.of(context).cardColor,
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium), // Menampilkan judul pie chart.
            const SizedBox(height: 10),
            Row( // Mengatur pie chart dan legenda secara horizontal.
              children: [
                Container( // Placeholder visual untuk area pie chart.
                  width: 120,
                  height: 120,
                  color: Colors.grey[800], // Warna latar belakang placeholder.
                  child: const Center(
                    child: Text('Pie', style: TextStyle(color: Colors.white54)), // Teks placeholder.
                  ),
                ),
                const SizedBox(width: 20), // Jarak horizontal antara pie chart dan legenda.
                Column( // Mengatur item legenda secara vertikal.
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildLegendItem(context, Colors.blue, 'Mobil (60%)'), // Item legenda untuk mobil.
                    _buildLegendItem(context, Colors.yellow, 'Truk/Bus (25%)'), // Item legenda untuk truk/bus.
                    _buildLegendItem(context, Colors.red, 'Lainnya (15%)'), // Item legenda untuk lainnya.
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Fungsi pembantu untuk membangun satu item legenda untuk pie chart.
  /// [context] digunakan untuk mengakses Theme data.
  /// [color] adalah warna kotak kecil di legenda.
  /// [text] adalah teks deskripsi untuk item legenda.
  Widget _buildLegendItem(BuildContext context, Color color, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0), // Padding vertikal untuk setiap item.
      child: Row( // Mengatur kotak warna dan teks secara horizontal.
        children: [
          Container( // Kotak warna kecil.
            width: 16,
            height: 16,
            color: color,
          ),
          const SizedBox(width: 8), // Jarak horizontal.
          Text(text, style: Theme.of(context).textTheme.bodyMedium), // Teks deskripsi legenda.
        ],
      ),
    );
  }

  /// Fungsi pembantu untuk membangun kartu yang berisi peringkat titik terpadat (placeholder).
  /// [context] digunakan untuk mengakses Theme data.
  /// [title] adalah judul yang akan ditampilkan di kartu peringkat.
  Widget _buildRankingCard(BuildContext context, String title) {
    return Card(
      color: Theme.of(context).cardColor,
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium), // Menampilkan judul peringkat.
            const SizedBox(height: 10),
            ListView.builder( // Menggunakan ListView.builder untuk daftar item peringkat.
              shrinkWrap: true, // Membuat ListView hanya mengambil ruang yang dibutuhkan oleh itemnya.
              physics: const NeverScrollableScrollPhysics(), // Menonaktifkan scroll ListView ini sendiri,
                                                            // agar SingleChildScrollView di atasnya yang menangani scroll.
              itemCount: 3, // Jumlah item peringkat contoh.
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Row( // Mengatur nomor, nama lokasi, dan persentase kepadatan secara horizontal.
                    children: [
                      Text('${index + 1}.', style: Theme.of(context).textTheme.bodyLarge), // Nomor peringkat.
                      const SizedBox(width: 10), // Jarak horizontal.
                      Expanded( // Memungkinkan teks lokasi mengisi sisa ruang.
                        child: Text(
                          'Jl. Jakarta - Cikampek KM ${10 + index}', // Nama lokasi contoh.
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                      Text('75%', style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.red)), // Persentase kepadatan.
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