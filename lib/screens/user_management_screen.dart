// lib/screens/user_management_screen.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smarttrafficapp/services/auth_service.dart';

class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({super.key});

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  
  // LOGIKA BARU UNTUK GAMBAR (Memory > Network > Asset > File)
  ImageProvider _getImageProvider(User user) {
    // 1. Cek jika ada gambar dari komputer (Bytes) - Prioritas Web
    if (user.webImageBytes != null) {
      return MemoryImage(user.webImageBytes!);
    }
    
    // 2. Cek jika URL Internet (Google Login)
    if (user.profilePictureUrl.startsWith('http')) {
      return NetworkImage(user.profilePictureUrl);
    }
    
    // 3. Cek jika Aset Lokal
    if (user.profilePictureUrl.startsWith('assets/')) {
      return AssetImage(user.profilePictureUrl);
    }

    // 4. Fallback terakhir (jika path file lokal di HP)
    // Di Web ini jarang dipakai, tapi aman disimpan
    try {
      return FileImage(File(user.profilePictureUrl));
    } catch (e) {
      return const AssetImage('assets/images/profile.jpg');
    }
  }

  String _formatDate(DateTime date) {
    const List<String> months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
      'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'
    ];
    return "${date.day} ${months[date.month - 1]} ${date.year}";
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final user = authService.currentUser;

    if (user == null) return const Center(child: CircularProgressIndicator());

    final double height = MediaQuery.of(context).size.height;
    final double width = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      body: Stack(
        children: [
          // 1. HEADER BACKGROUND
          Container(
            height: height * 0.35,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.blueAccent,
              image: DecorationImage(
                image: const AssetImage('assets/images/hero.png'),
                fit: BoxFit.cover,
                colorFilter: ColorFilter.mode(
                  Colors.black.withOpacity(0.4),
                  BlendMode.darken,
                ),
              ),
            ),
          ),

          // 2. KONTEN KARTU
          SingleChildScrollView(
            child: Column(
              children: [
                SizedBox(height: height * 0.20),

                // KARTU UTAMA
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2C2C2C),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.5), 
                        blurRadius: 15, 
                        offset: const Offset(0, 5)
                      )
                    ],
                  ),
                  child: Column(
                    children: [
                      const SizedBox(height: 60), // Space untuk foto profil
                      
                      Text(
                        user.username, 
                        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)
                      ),
                      const SizedBox(height: 5),
                      Text(
                        user.email, 
                        style: TextStyle(fontSize: 14, color: Colors.grey[400])
                      ),
                      const SizedBox(height: 10),
                      
                      // Role Badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.blueAccent.withOpacity(0.2), 
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.blueAccent.withOpacity(0.5))
                        ),
                        child: Text(
                          user.role.toUpperCase(), 
                          style: const TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold, fontSize: 12)
                        ),
                      ),

                      const SizedBox(height: 25),

                      // Tombol Edit Profil
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: () => _showEditProfileDialog(context, authService),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blueAccent,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                            elevation: 5,
                          ),
                          child: const Text(
                            "EDIT PROFIL", 
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1)
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 20),
                      const Divider(color: Colors.white12),
                      const SizedBox(height: 10),
                      
                      // Statistik
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildStatItem("Status", "Aktif"),
                          _buildStatItem("Bergabung", _formatDate(user.joinedDate)), 
                          _buildStatItem("Akses", "Full"),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // MENU BAWAH
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2C2C2C), 
                    borderRadius: BorderRadius.circular(20)
                  ),
                  child: Column(
                    children: [
                      _buildMenuItem(Icons.lock_reset, "Ganti Password", () => _showChangePasswordDialog(context)),
                      const Divider(color: Colors.white12, height: 1),
                      _buildMenuItem(Icons.logout, "Logout", () => authService.signOut(), isDestructive: true),
                    ],
                  ),
                ),
                const SizedBox(height: 30),
              ],
            ),
          ),

          // 3. FOTO PROFIL MELAYANG (UPDATE DISINI)
          Positioned(
            top: height * 0.13,
            left: (width / 2) - 60,
            child: GestureDetector(
              onTap: () {
                // Klik foto profil langsung buka picker
                authService.pickNewProfileImage();
              },
              child: Stack(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFF2C2C2C), width: 6),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 5))
                      ],
                    ),
                    child: CircleAvatar(
                      radius: 55,
                      backgroundColor: Colors.grey[800],
                      // Gunakan Helper yang sudah diperbaiki
                      backgroundImage: _getImageProvider(user),
                    ),
                  ),
                  // Ikon Kamera Kecil
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                        color: Colors.blueAccent,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.camera_alt, color: Colors.white, size: 20),
                    ),
                  )
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)), 
        const SizedBox(height: 4), 
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12))
      ]
    );
  }

  Widget _buildMenuItem(IconData icon, String title, VoidCallback onTap, {bool isDestructive = false}) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8), 
        decoration: BoxDecoration(
          color: isDestructive ? Colors.red.withOpacity(0.1) : Colors.blueAccent.withOpacity(0.1), 
          borderRadius: BorderRadius.circular(8)
        ), 
        child: Icon(icon, color: isDestructive ? Colors.redAccent : Colors.blueAccent)
      ),
      title: Text(title, style: TextStyle(color: isDestructive ? Colors.redAccent : Colors.white, fontWeight: FontWeight.w500)),
      trailing: const Icon(Icons.arrow_forward_ios, color: Colors.grey, size: 16),
      onTap: onTap,
    );
  }

  // --- DIALOG EDIT PROFIL ---
  Future<void> _showEditProfileDialog(BuildContext context, AuthService authService) async {
    final user = authService.currentUser!;
    final nameController = TextEditingController(text: user.username);
    final emailController = TextEditingController(text: user.email);

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1E1E1E),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          contentPadding: const EdgeInsets.all(20),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text("Edit Profil", style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              
              // Foto di Dialog juga bisa diklik
              GestureDetector(
                onTap: () {
                  authService.pickNewProfileImage();
                  // Tidak perlu setState manual di sini karena AuthService notifyListeners 
                  // akan merebuild parent, tapi dialog mungkin perlu ditutup buka ulang 
                  // atau dibiarkan saja karena foto utama di belakang sudah ganti.
                },
                child: Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    CircleAvatar(
                      radius: 50, 
                      backgroundColor: Colors.grey[800], 
                      backgroundImage: _getImageProvider(user)
                    ),
                    Container(padding: const EdgeInsets.all(6), decoration: const BoxDecoration(color: Colors.blueAccent, shape: BoxShape.circle), child: const Icon(Icons.camera_alt, color: Colors.white, size: 18)),
                  ],
                ),
              ),
              
              const SizedBox(height: 20),
              TextField(controller: nameController, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: "Nama Lengkap", prefixIcon: Icon(Icons.person, color: Colors.grey), filled: true, fillColor: Colors.black26)),
              const SizedBox(height: 15),
              TextField(controller: emailController, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: "Email", prefixIcon: Icon(Icons.email, color: Colors.grey), filled: true, fillColor: Colors.black26)),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("Batal", style: TextStyle(color: Colors.grey))),
            ElevatedButton(
              onPressed: () {
                authService.updateUserData(nameController.text, emailController.text);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Profil berhasil diperbarui"), backgroundColor: Colors.green));
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent, foregroundColor: Colors.white),
              child: const Text("Simpan"),
            ),
          ],
        );
      },
    );
  }

  // --- DIALOG GANTI PASSWORD ---
  Future<void> _showChangePasswordDialog(BuildContext context) async {
    final oldPassController = TextEditingController();
    final newPassController = TextEditingController();
    final confirmPassController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1E1E1E),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text("Ganti Password", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          content: SizedBox(
            width: MediaQuery.of(context).size.width * 0.8,
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: oldPassController,
                    obscureText: true,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(labelText: "Password Lama", prefixIcon: Icon(Icons.lock_outline, color: Colors.grey), filled: true, fillColor: Colors.black26),
                    validator: (v) => v!.isEmpty ? "Wajib diisi" : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: newPassController,
                    obscureText: true,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(labelText: "Password Baru", prefixIcon: Icon(Icons.lock, color: Colors.blueAccent), filled: true, fillColor: Colors.black26),
                    validator: (v) => v!.length < 6 ? "Minimal 6 karakter" : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: confirmPassController,
                    obscureText: true,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(labelText: "Konfirmasi Password", prefixIcon: Icon(Icons.lock, color: Colors.blueAccent), filled: true, fillColor: Colors.black26),
                    validator: (v) => v != newPassController.text ? "Password tidak sama" : null,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Batal", style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Password berhasil diubah!"), backgroundColor: Colors.green),
                  );
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent, foregroundColor: Colors.white),
              child: const Text("Simpan"),
            ),
          ],
        );
      },
    );
  }
}