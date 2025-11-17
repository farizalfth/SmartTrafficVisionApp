import 'package:flutter/material.dart';
import 'package:smarttrafficapp/screens/dashboard_screen.dart';
import 'package:smarttrafficapp/screens/live_cctv_screen.dart';
import 'package:smarttrafficapp/screens/analytics_screen.dart';
import 'package:smarttrafficapp/screens/camera_management_screen.dart';
import 'package:smarttrafficapp/screens/report_screen.dart';
import 'package:smarttrafficapp/screens/user_management_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized(); // Penting untuk inisialisasi SharedPreferences
  // Anda mungkin perlu memanggil StorageService.init() di sini jika sudah dibuat
  // await StorageService.init(); // Pastikan Anda sudah membuat StorageService.init()

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Smart Traffic Vision',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        brightness: Brightness.dark, // Menggunakan tema gelap
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
        ),
        scaffoldBackgroundColor: const Color(
          0xFF1A1A1A,
        ), // Warna latar belakang gelap
        cardColor: const Color(0xFF2C2C2C), // Warna card gelap
        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: Colors.white),
          bodyMedium: TextStyle(color: Colors.white70),
          titleLarge: TextStyle(color: Colors.white),
          titleMedium: TextStyle(color: Colors.white),
          displayLarge: TextStyle(
            color: Colors.white,
          ), // Tambahkan ini jika dibutuhkan
          displayMedium: TextStyle(color: Colors.white),
          displaySmall: TextStyle(color: Colors.white),
          headlineLarge: TextStyle(color: Colors.white),
          headlineMedium: TextStyle(color: Colors.white),
          headlineSmall: TextStyle(color: Colors.white),
          titleSmall: TextStyle(color: Colors.white),
          labelLarge: TextStyle(color: Colors.white),
          labelMedium: TextStyle(color: Colors.white),
          labelSmall: TextStyle(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      home: const MainScreen(),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  static final List<Widget> _widgetOptions = <Widget>[
    const DashboardScreen(),
    const LiveCCTVScreen(),
    const AnalyticsScreen(),
    const CameraManagementScreen(),
    const ReportScreen(),
    const UserManagementScreen(),
  ];

  final List<String> _titles = <String>[
    'Dashboard',
    'Live CCTV',
    'Statistik & Analitik',
    'Manajemen Kamera',
    'Laporan Otomatis',
    'Manajemen Pengguna',
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    Navigator.pop(context); // Close the drawer
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_titles[_selectedIndex]),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('Search clicked')));
            },
          ),
          IconButton(
            icon: const Icon(Icons.notifications),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Notifications clicked')),
              );
            },
          ),
        ],
      ),
      drawer: Drawer(
        backgroundColor: const Color(0xFF2C2C2C), // Warna drawer gelap
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            DrawerHeader(
              decoration: const BoxDecoration(color: Colors.black),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Smart Traffic Vision',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Destination your Applications', // Contoh tagline
                    style: TextStyle(
                      color: Colors.white.withOpacity(
                        0.7,
                      ), // Tetap gunakan withOpacity di sini karena ini langsung pada Color
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            _buildDrawerItem(0, Icons.dashboard, 'Dashboard'),
            _buildDrawerItem(1, Icons.videocam, 'Live CCTV'),
            _buildDrawerItem(2, Icons.analytics, 'Statistik & Analitik'),
            _buildDrawerItem(3, Icons.camera, 'Manajemen Kamera'),
            _buildDrawerItem(4, Icons.description, 'Laporan Otomatis'),
            _buildDrawerItem(5, Icons.people, 'Manajemen Pengguna'),
          ],
        ),
      ),
      body: _widgetOptions.elementAt(_selectedIndex),
    );
  }

  Widget _buildDrawerItem(int index, IconData icon, String title) {
    return ListTile(
      leading: Icon(icon, color: Colors.white),
      title: Text(
        title,
        style: TextStyle(
          color: Colors.white,
          fontWeight: _selectedIndex == index
              ? FontWeight.bold
              : FontWeight.normal,
        ),
      ),
      selected: _selectedIndex == index,
      tileColor: _selectedIndex == index
          ? Colors.blue.withOpacity(0.3)
          : Colors.transparent,
      onTap: () => _onItemTapped(index),
    );
  }
}
