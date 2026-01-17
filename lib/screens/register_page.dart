// lib/screens/register_page.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smarttrafficapp/services/auth_service.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  
  bool _isLoading = false;
  bool _obscureText = true;
  bool _obscureConfirmText = true;

  // Membersihkan memori saat halaman ditutup
  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

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
                height: size.height * 0.35,
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
                      "SmartTrafficApp",
                      style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 1.2),
                    ),
                    const SizedBox(height: 5),
                    Text("Create your account", style: TextStyle(fontSize: 14, color: Colors.white.withOpacity(0.8))),
                    const SizedBox(height: 40),
                  ],
                ),
              ),

              // FORM CARD
              Positioned(
                top: size.height * 0.25,
                left: 0,
                right: 0,
                bottom: 0,
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: const BoxDecoration(
                    color: Color(0xFF1A1A1A),
                    borderRadius: BorderRadius.only(topLeft: Radius.circular(30), topRight: Radius.circular(30)),
                  ),
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        const Text("Register", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
                        const SizedBox(height: 25),

                        // Input Fields
                        TextField(
                          controller: _usernameController,
                          style: const TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold),
                          decoration: _inputDecor("Username", Icons.person),
                        ),
                        const SizedBox(height: 15),
                        TextField(
                          controller: _emailController,
                          style: const TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold),
                          decoration: _inputDecor("Email", Icons.email),
                        ),
                        const SizedBox(height: 15),
                        TextField(
                          controller: _passwordController,
                          obscureText: _obscureText,
                          style: const TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold),
                          decoration: _inputDecor("Password", Icons.lock).copyWith(
                            suffixIcon: IconButton(
                              icon: Icon(_obscureText ? Icons.visibility_off : Icons.visibility, color: Colors.blueGrey),
                              onPressed: () => setState(() => _obscureText = !_obscureText),
                            ),
                          ),
                        ),
                        const SizedBox(height: 15),
                        TextField(
                          controller: _confirmPasswordController,
                          obscureText: _obscureConfirmText,
                          style: const TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold),
                          decoration: _inputDecor("Confirm Password", Icons.lock_outline).copyWith(
                            suffixIcon: IconButton(
                              icon: Icon(_obscureConfirmText ? Icons.visibility_off : Icons.visibility, color: Colors.blueGrey),
                              onPressed: () => setState(() => _obscureConfirmText = !_obscureConfirmText),
                            ),
                          ),
                        ),
                        const SizedBox(height: 25),

                        // Tombol Register
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _handleRegister,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF2C2C2C),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                              side: const BorderSide(color: Colors.grey, width: 0.5),
                            ),
                            child: _isLoading
                                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.blueAccent, strokeWidth: 2))
                                : const Text("Register", style: TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold)),
                          ),
                        ),

                        const SizedBox(height: 20),
                        const Text("OR", style: TextStyle(color: Colors.grey)),
                        const SizedBox(height: 20),

                        // Social Login (Google)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _socialButton(
                              icon: Icons.g_mobiledata, 
                              onTap: _handleGoogleLogin,
                            ),
                          ],
                        ),
                        
                        const SizedBox(height: 30),
                        
                        // Link ke Login
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text("Already have an account? ", style: TextStyle(color: Colors.grey)),
                            GestureDetector(
                              onTap: () => Navigator.pop(context),
                              child: const Text("Login", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecor(String label, IconData icon) {
    return InputDecoration(
      prefixIcon: Icon(icon, color: Colors.blueAccent),
      labelText: label,
      labelStyle: const TextStyle(color: Colors.blueGrey),
      floatingLabelStyle: const TextStyle(color: Colors.blueAccent),
      filled: true,
      fillColor: const Color(0xFF2C2C2C),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.blueAccent, width: 1.5),
      ),
    );
  }

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

  // --- LOGIKA REGISTER ---
  void _handleRegister() async {
    // Validasi input kosong
    if (_usernameController.text.isEmpty || _emailController.text.isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Field tidak boleh kosong'), backgroundColor: Colors.orange));
      return;
    }

    // Validasi kecocokan password
    if (_passwordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Password tidak cocok'), backgroundColor: Colors.red));
      return;
    }

    setState(() => _isLoading = true);
    final authService = Provider.of<AuthService>(context, listen: false);
    
    // Panggil Service (Return null jika sukses, return String jika error)
    String? error = await authService.registerWithEmailPassword(
      _usernameController.text.trim(),
      _emailController.text.trim(),
      _passwordController.text.trim(),
    );

    if (mounted) {
      setState(() => _isLoading = false);

      if (error == null) {
        // JIKA SUKSES
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Registrasi Berhasil! Silakan Login.'), backgroundColor: Colors.green)
        );
        
        // Pindah ke halaman Login setelah jeda 1 detik
        Future.delayed(const Duration(seconds: 1), () {
          if (mounted) Navigator.pop(context); // Kembali ke halaman Login
        });

      } else {
        // JIKA GAGAL
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error), backgroundColor: Colors.red)
        );
      }
    }
  }

  void _handleGoogleLogin() async {
    setState(() => _isLoading = true);
    final authService = Provider.of<AuthService>(context, listen: false);
    
    String? error = await authService.signInWithGoogle();
    
    if (mounted) {
      setState(() => _isLoading = false);
      if (error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal: $error'), backgroundColor: Colors.red),
        );
      }
    }
  }
}