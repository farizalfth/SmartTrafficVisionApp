import 'package:flutter/material.dart';

class NotificationScreen extends StatefulWidget {
  final List<String> initialNotifications; // List notifikasi awal

  const NotificationScreen({
    super.key,
    this.initialNotifications = const [],
  });

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  // Notifikasi akan ditambahkan ke sini
  List<String> _notifications = [];

  @override
  void initState() {
    super.initState();
    // Inisialisasi notifikasi dengan yang diterima dari parameter
    _notifications = List.from(widget.initialNotifications);
  }

  // Fungsi untuk menambahkan notifikasi baru (bisa dipanggil dari luar)
  void addNotification(String message) {
    setState(() {
      _notifications.add(message);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifikasi'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: _notifications.isEmpty
          ? const Center(
              child: Text(
                'Tidak ada notifikasi baru.',
                style: TextStyle(color: Colors.white54),
              ),
            )
          : ListView.builder(
              itemCount: _notifications.length,
              itemBuilder: (context, index) {
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
                  color: Colors.red[800], // Warna merah untuk peringatan
                  child: ListTile(
                    leading: const Icon(Icons.warning, color: Colors.white),
                    title: Text(
                      _notifications[index],
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                    // Optional: aksi saat notifikasi ditekan (misal: navigasi ke detail)
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Melihat detail: ${_notifications[index]}')),
                      );
                    },
                  ),
                );
              },
            ),
    );
  }
}