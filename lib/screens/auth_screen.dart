// lib/screens/auth_screen.dart

import 'package:flutter/material.dart';
import 'package:smarttrafficapp/services/auth_service.dart';
import 'package:smarttrafficapp/screens/dashboard_screen.dart'; // Ganti dengan halaman utama Anda

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final AuthService _authService = AuthService();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  // Cek apakah user sudah login saat aplikasi dibuka
  Future<void> _checkLoginStatus() async {
    bool loggedIn = await _authService.isLoggedIn();
    if (loggedIn && mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const DashboardScreen()), // Ganti dengan halaman utama Anda
      );
    }
  }

  Future<void> _handleGoogleSignIn() async {
    setState(() {
      _isLoading = true;
    });

    String? success = await _authService.signInWithGoogle();

    if (mounted) {
      setState(() {
        _isLoading = false;
      });

      if (success != null) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const DashboardScreen()), // Ganti dengan halaman utama Anda
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gagal login dengan Google. Coba lagi.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('SmartTrafficApp - Login'),
        backgroundColor: Theme.of(context).primaryColor,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Selamat Datang di SmartTrafficApp',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
              _isLoading
                  ? const CircularProgressIndicator()
                  : ElevatedButton.icon(
                      onPressed: _handleGoogleSignIn,
                      icon: Image.asset(
                        'assets/images/google_logo.png', // Pastikan path ini benar
                        height: 24.0,
                        width: 24.0,
                      ),
                      label: const Text(
                        'Login dengan Google',
                        style: TextStyle(fontSize: 18),
                      ),
                      style: ElevatedButton.styleFrom(
                        foregroundColor: Colors.black, backgroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 50), // Lebar penuh
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30.0),
                        ),
                        elevation: 3,
                      ),
                    ),
              const SizedBox(height: 20),
              const Text(
                'Akses informasi lalu lintas real-time.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            ],
          ),
        ),
      ),
    );
  }
}