// lib/main.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:smarttrafficapp/firebase_options.dart';

// --- IMPORT SERVICES & DATA ---
import 'package:smarttrafficapp/services/auth_service.dart';
import 'package:smarttrafficapp/services/traffic_service.dart';
import 'package:smarttrafficapp/data/cctv_data_source.dart';

// --- IMPORT SCREENS ---
import 'package:smarttrafficapp/screens/login_page.dart';
import 'package:smarttrafficapp/screens/register_page.dart';
import 'package:smarttrafficapp/screens/dashboard_screen.dart';
import 'package:smarttrafficapp/screens/live_cctv_screen.dart';
import 'package:smarttrafficapp/screens/analytics_screen.dart';
import 'package:smarttrafficapp/screens/camera_management_screen.dart';
import 'package:smarttrafficapp/screens/report_screen.dart';
import 'package:smarttrafficapp/screens/user_management_screen.dart';

// --- TAMBAHKAN IMPORT INI UNTUK MEMPERBAIKI ERROR TANGGAL ---
import 'package:intl/date_symbol_data_local.dart'; 

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inisialisasi Firebase menggunakan DefaultFirebaseOptions
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  await initializeDateFormatting('id_ID', null);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => AuthService()),
        ChangeNotifierProvider(create: (context) => CCTVDataSource()),

      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Smart Traffic Vision',
      debugShowCheckedModeBanner: false,
      
      theme: ThemeData(
        brightness: Brightness.dark,
        useMaterial3: true,
        primaryColor: Colors.blueAccent,
        scaffoldBackgroundColor: const Color(0xFF1A1A1A), 
        cardColor: const Color(0xFF2C2C2C), 
        
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF1A1A1A),
          foregroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
        ),
        
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFF2C2C2C),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          hintStyle: TextStyle(color: Colors.grey[600]),
        ),

        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: Colors.blueAccent,
          foregroundColor: Colors.white,
        ),


        textTheme: const TextTheme(
          titleLarge: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          bodyMedium: TextStyle(color: Colors.white70),
        ), 
        colorScheme: ColorScheme.dark(
          primary: Colors.blueAccent, 
          surface: const Color(0xFF2C2C2C)
        ),
      ),

      home: const AuthWrapper(),
      routes: {
        '/login': (context) => const LoginPage(),
        '/register': (context) => const RegisterPage(),
        '/dashboard': (context) => const MainScreen(),
      },
    );
  }
}


class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthService>(
      builder: (context, authService, child) {
        if (authService.currentUser != null) {
          return const MainScreen();
        } else {
          return const LoginPage();
        }
      },
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
    'Profil',
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    Navigator.pop(context); 
  }

  void _handleLogout() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    await authService.signOut();
  }

  ImageProvider _getProfileImage(User? user) {

    if (user == null) return const AssetImage('assets/images/profile.jpg');

    if (user.webImageBytes != null) {
      return MemoryImage(user.webImageBytes!);
    }
    
    if (user.profilePictureUrl.isNotEmpty && user.profilePictureUrl.startsWith('http')) {
      return NetworkImage(user.profilePictureUrl);
    }
    
    if (user.profilePictureUrl.startsWith('assets/')) {
      return AssetImage(user.profilePictureUrl);
    }

    try {
      if (user.profilePictureUrl.isNotEmpty) {
        return FileImage(File(user.profilePictureUrl));
      }
    } catch (e) {
    }

    return const AssetImage('assets/images/profile.jpg');
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final user = authService.currentUser;
    final String userName = user?.username ?? 'Admin User';
    final String userEmail = user?.email ?? 'admin@smarttraffic.id';

    return Scaffold(

      drawer: Drawer(
        backgroundColor: const Color(0xFF1E1E1E), 
        child: Column(
          children: [
            UserAccountsDrawerHeader(
              decoration: const BoxDecoration(
                color: Color(0xFF1A1A1A),
                image: DecorationImage(
                  image: AssetImage('assets/images/hero.png'), 
                  fit: BoxFit.cover,
                  colorFilter: ColorFilter.mode(Colors.black54, BlendMode.darken),
                ),
              ),
              currentAccountPicture: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.blueAccent, width: 2),
                  boxShadow: [BoxShadow(blurRadius: 10, color: Colors.black.withOpacity(0.5))],
                ),
                child: CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.grey[800],
                  backgroundImage: _getProfileImage(user),
                ),
              ),
              accountName: Text(
                userName,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              accountEmail: Text(userEmail),
            ),

            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 8),
                children: [
                  _buildDrawerItem(0, Icons.dashboard_rounded, 'Dashboard'),
                  _buildDrawerItem(1, Icons.videocam_rounded, 'Live CCTV'),
                  _buildDrawerItem(2, Icons.bar_chart_rounded, 'Statistik & Analitik'),
                  _buildDrawerItem(3, Icons.camera_alt_rounded, 'Manajemen Kamera'),
                  _buildDrawerItem(4, Icons.description_rounded, 'Laporan Otomatis'),
                  const Divider(color: Colors.white24, thickness: 0.5),
                  _buildDrawerItem(5, Icons.person, 'Profile'), // Ikon Profile
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: ListTile(
                leading: const Icon(Icons.logout_rounded, color: Colors.redAccent),
                title: const Text(
                  'Logout',
                  style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold),
                ),
                onTap: _handleLogout,
              ),
            ),
          ],
        ),
      ),
      body: _widgetOptions.elementAt(_selectedIndex),
    );
  }

  Widget _buildDrawerItem(int index, IconData icon, String title) {
    bool isSelected = _selectedIndex == index;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isSelected ? Colors.blueAccent.withOpacity(0.2) : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
      ),
      child: ListTile(
        leading: Icon(icon, color: isSelected ? Colors.blueAccent : Colors.grey),
        title: Text(
          title,
          style: TextStyle(
            color: isSelected ? Colors.blueAccent : Colors.white70,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
        onTap: () => _onItemTapped(index),
      ),
    );
  }
}