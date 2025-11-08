import 'package:flutter/material.dart';

class CameraManagementScreen extends StatelessWidget {
  const CameraManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Manajemen Kamera', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 16),
          _buildSearchBar(context),
          const SizedBox(height: 16),
          _buildCameraList(context),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Tambah Kamera Baru')),
              );
            },
            icon: const Icon(Icons.add),
            label: const Text('Tambah Kamera Baru'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue, // Warna tombol
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              textStyle: const TextStyle(fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(BuildContext context) { // Menerima context
    return Card(
      color: Theme.of(context).cardColor,
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: TextField(
          style: Theme.of(context).textTheme.bodyLarge,
          decoration: InputDecoration(
            hintText: 'Cari kamera...',
            hintStyle: Theme.of(context).textTheme.bodyMedium,
            border: InputBorder.none,
            icon: Icon(Icons.search, color: Theme.of(context).iconTheme.color),
          ),
        ),
      ),
    );
  }

  Widget _buildCameraList(BuildContext context) { // Menerima context
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: 4, // Example cameras
      itemBuilder: (context, index) {
        return Card(
          color: Theme.of(context).cardColor,
          margin: const EdgeInsets.symmetric(vertical: 8.0),
          elevation: 4,
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: [
                Container(
                  width: 80,
                  height: 60,
                  color: Colors.grey[700], // Placeholder for camera preview
                  child: Center(
                    child: Text('CCTV ${index + 1}', style: const TextStyle(color: Colors.white54, fontSize: 10)),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Jl. Sudirman - Bundaran HI',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Status: Online | ID: CCTV00${index + 1}',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.edit, color: Colors.blue),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Edit CCTV ${index + 1}')),
                    );
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Hapus CCTV ${index + 1}')),
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}