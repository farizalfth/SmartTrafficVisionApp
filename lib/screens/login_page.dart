// lib/screens/login_page.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smarttrafficapp/services/auth_service.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscureText = true;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      body: SingleChildScrollView(
        child: SizedBox(
          height: size.height,
          child: Stack(
            children: [
              // HEADER BACKGROUND
              Container(
                height: size.height * 0.45,
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: Colors.blueAccent,
                  image: DecorationImage(
                    image: AssetImage('assets/images/hero.png'),
                    fit: BoxFit.cover,
                    colorFilter: ColorFilter.mode(
                      Colors.blueAccent,
                      BlendMode.multiply,
                    ),
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 20),
                    const Text(
                      "Smart Traffic App",
                      style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 1.5),
                    ),
                    const SizedBox(height: 10),
                    Text("Welcome back",
                        style: TextStyle(
                            fontSize: 16,
                            color: Colors.white.withOpacity(0.8))),
                    const SizedBox(height: 50),
                  ],
                ),
              ),

              // FORM CARD
              Positioned(
                top: size.height * 0.35,
                left: 0,
                right: 0,
                bottom: 0,
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: const BoxDecoration(
                    color: Color(0xFF1A1A1A),
                    borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(30),
                        topRight: Radius.circular(30)),
                  ),
                  child: Column(
                    children: [
                      const Text("Login",
                          style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.white)),
                      const SizedBox(height: 30),

                      // Input Fields
                      TextField(
                        controller: _emailController,
                        style: const TextStyle(
                            color: Colors.blueAccent,
                            fontWeight: FontWeight.bold),
                        decoration: _inputDecor("Email", Icons.email),
                      ),
                      const SizedBox(height: 20),
                      TextField(
                        controller: _passwordController,
                        obscureText: _obscureText,
                        style: const TextStyle(
                            color: Colors.blueAccent,
                            fontWeight: FontWeight.bold),
                        decoration:
                            _inputDecor("Password", Icons.lock).copyWith(
                          suffixIcon: IconButton(
                            icon: Icon(
                                _obscureText
                                    ? Icons.visibility_off
                                    : Icons.visibility,
                                color: Colors.blueGrey),
                            onPressed: () =>
                                setState(() => _obscureText = !_obscureText),
                          ),
                        ),
                      ),
                      const SizedBox(height: 30),

                      // Tombol Login
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _handleLogin,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2C2C2C),
                            shadowColor: Colors.transparent,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30)),
                            side: const BorderSide(
                                color: Colors.grey, width: 0.5),
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                      color: Colors.blueAccent, strokeWidth: 2))
                              : const Text("Log In",
                                  style: TextStyle(
                                      color: Colors.blueAccent,
                                      fontWeight: FontWeight.bold)),
                        ),
                      ),

                      const SizedBox(height: 20),
                      const Text("OR", style: TextStyle(color: Colors.grey)),
                      const SizedBox(height: 20),

                      // Social Login (Hanya Google)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _socialButton(
                            icon: Icons
                                .g_mobiledata, // Ikon Google (bawaan material)
                            onTap: _handleGoogleLogin,
                          ),
                        ],
                      ),

                      const Spacer(),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text("Don't have an Account? ",
                              style: TextStyle(color: Colors.grey)),
                          GestureDetector(
                            onTap: () =>
                                Navigator.pushNamed(context, '/register'),
                            child: const Text("Create Account",
                                style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Helper Input Decor
  InputDecoration _inputDecor(String label, IconData icon) {
    return InputDecoration(
      prefixIcon: Icon(icon, color: Colors.blueAccent),
      labelText: label,
      labelStyle: const TextStyle(color: Colors.blueGrey),
      floatingLabelStyle: const TextStyle(color: Colors.blueAccent),
      filled: true,
      fillColor: const Color(0xFF2C2C2C),
      border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.blueAccent, width: 1.5),
      ),
    );
  }

  // Helper Social Button (Ditambah onTap)
  Widget _socialButton({required IconData icon, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: CircleAvatar(
        radius: 24,
        backgroundColor: const Color(0xFF2C2C2C),
        child: Icon(icon, color: Colors.white, size: 28),
      ),
    );
  }

  // Logic Login Email Biasa
  void _handleLogin() async {
    // 1. Validasi input kosong
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Email dan Password wajib diisi!")),
      );
      return;
    }

    setState(() => _isLoading = true);

    // 2. Panggil fungsi Sign In dari AuthService
    final authService = Provider.of<AuthService>(context, listen: false);
    bool success = await authService.signIn(
      _emailController.text.trim(),
      _passwordController.text.trim(),
    );

    if (mounted) {
      setState(() => _isLoading = false);

      if (success) {
        // --- JIKA LOGIN BERHASIL ---

        // 3. Tampilkan Notifikasi Sukses
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Login Berhasil! Selamat Datang kembali."),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );

        // 4. PINDAH KE DASHBOARD
        // Pastikan route '/dashboard' sudah ada di main.dart
        Navigator.pushReplacementNamed(context, '/dashboard');
      } else {
        // --- JIKA LOGIN GAGAL ---
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Login Gagal! Email atau Password salah."),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Logic Login Google (DIPERBARUI DENGAN NOTIFIKASI)
  void _handleGoogleLogin() async {
    setState(() => _isLoading = true);
    final authService = Provider.of<AuthService>(context, listen: false);

    // Panggil service
    String? error = await authService.signInWithGoogle();

    setState(() => _isLoading = false);

    // --- 1. LOGIKA SUKSES ---
    // Cek apakah user berhasil masuk (currentUser tidak null)
    if (authService.currentUser != null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Login Berhasil! Mengalihkan...'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
      // Return agar AuthWrapper mengambil alih navigasi ke Dashboard
      return;
    }

    // --- 2. LOGIKA GAGAL / DIBATALKAN ---
    if (mounted) {
      if (error != null && error != "null") {
        // Jika ada pesan error spesifik dari Firebase/Google
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Login Gagal: $error'),
              backgroundColor: Colors.red),
        );
      } else {
        // Jika error null tapi user juga null (biasanya user menutup popup login / cancel)
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Login Dibatalkan'),
              backgroundColor: Colors.orange),
        );
      }
    }
  }
}
