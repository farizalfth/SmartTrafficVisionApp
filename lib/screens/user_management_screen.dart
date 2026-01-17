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
    // 1. Jika baru saja ganti di laptop (masih ada di RAM)
    if (user.webImageBytes != null) {
      return MemoryImage(user.webImageBytes!);
    }

    // 2. Jika ada URL internet (Hasil tarikan dari MySQL)
    // Tambahkan Timestamp agar browser tidak menampilkan gambar lama dari cache
    if (user.profilePictureUrl.startsWith('http')) {
      return NetworkImage(
          "${user.profilePictureUrl}?t=${DateTime.now().millisecondsSinceEpoch}");
    }

    // 3. Jika tidak ada, gunakan default aset
    return const AssetImage('assets/images/users.jpg');
  }

  String _formatDate(DateTime date) {
    const List<String> months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'Mei',
      'Jun',
      'Jul',
      'Agu',
      'Sep',
      'Okt',
      'Nov',
      'Des'
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
      appBar: AppBar(
        title: const Text('Profil Pengguna'),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,

        // --- TAMBAHKAN KODE INI (TOMBOL MENU) ---
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () {
            // Membuka Sidebar/Drawer dari MainScreen
            Scaffold.of(context).openDrawer();
          },
        ),
      ),
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

                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  padding: const EdgeInsets.all(20),
                  width: double.infinity, // Memastikan kontainer selebar layar
                  decoration: BoxDecoration(
                    color: const Color(0xFF2C2C2C),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black.withOpacity(0.5),
                          blurRadius: 15,
                          offset: const Offset(0, 5))
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment:
                        CrossAxisAlignment.center, // RATA TENGAH
                    children: [
                      const SizedBox(height: 60),

                      // PERBAIKAN IMAGE 1: NAMA RATA TENGAH
                      Text(
                        user.username,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.white),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        user.email,
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 14, color: Colors.grey[400]),
                      ),
                      const SizedBox(height: 15),

                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 6),
                        decoration: BoxDecoration(
                            color: Colors.blueAccent.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                                color: Colors.blueAccent.withOpacity(0.5))),
                        child: Text(user.role.toUpperCase(),
                            style: const TextStyle(
                                color: Colors.blueAccent,
                                fontWeight: FontWeight.bold,
                                fontSize: 12)),
                      ),

                      const SizedBox(height: 25),

                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: () =>
                              _showEditProfileDialog(context, authService),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blueAccent,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30)),
                          ),
                          child: const Text("EDIT PROFIL",
                              style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ),

                      const SizedBox(height: 20),
                      const Divider(color: Colors.white12),
                      const SizedBox(height: 10),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildStatItem("Status", "Aktif"),
                          _buildStatItem(
                              "Bergabung", _formatDate(user.joinedDate)),
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
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    children: [
                      // Menu Ganti Password
                      _buildMenuItem(
                        Icons.lock_reset,
                        "Ganti Password",
                        () => _showChangePasswordDialog(context),
                      ),

                      const Divider(color: Colors.white12, height: 1),

                      // Menu Logout
                      _buildMenuItem(
                        Icons.logout,
                        "Logout",
                        () async {
                          final authService =
                              Provider.of<AuthService>(context, listen: false);

                          // 1. Jalankan proses logout
                          await authService.signOut();

                          if (context.mounted) {
                            // 2. Beri notifikasi berhasil keluar
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text("Berhasil Keluar"),
                                backgroundColor: Colors.green,
                                duration: Duration(seconds: 2),
                              ),
                            );

                            // 3. Navigasi paksa ke halaman login & hapus semua history
                            Navigator.pushNamedAndRemoveUntil(
                              context,
                              '/login',
                              (route) => false,
                            );
                          }
                        },
                        isDestructive: true,
                      ),
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
                      border:
                          Border.all(color: const Color(0xFF2C2C2C), width: 6),
                      boxShadow: [
                        BoxShadow(
                            color: Colors.black.withOpacity(0.3),
                            blurRadius: 10,
                            offset: const Offset(0, 5))
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
                      child: const Icon(Icons.camera_alt,
                          color: Colors.white, size: 20),
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
    return Column(children: [
      Text(value,
          style: const TextStyle(
              color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
      const SizedBox(height: 4),
      Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12))
    ]);
  }

  Widget _buildMenuItem(IconData icon, String title, VoidCallback onTap,
      {bool isDestructive = false}) {
    return ListTile(
      leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
              color: isDestructive
                  ? Colors.red.withOpacity(0.1)
                  : Colors.blueAccent.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8)),
          child: Icon(icon,
              color: isDestructive ? Colors.redAccent : Colors.blueAccent)),
      title: Text(title,
          style: TextStyle(
              color: isDestructive ? Colors.redAccent : Colors.white,
              fontWeight: FontWeight.w500)),
      trailing:
          const Icon(Icons.arrow_forward_ios, color: Colors.grey, size: 16),
      onTap: onTap,
    );
  }

  // --- DIALOG EDIT PROFIL (DIPERBAIKI AGAR TIDAK OVERFLOW) ---
  Future<void> _showEditProfileDialog(
      BuildContext context, AuthService authService) async {
    final nameController =
        TextEditingController(text: authService.currentUser!.username);
    final emailController =
        TextEditingController(text: authService.currentUser!.email);

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return Consumer<AuthService>(
          builder: (context, auth, child) {
            final user = auth.currentUser!;
            return AlertDialog(
              backgroundColor: const Color(0xFF1E1E1E),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 25),
              // PERBAIKAN UTAMA: Bungkus Column dengan SingleChildScrollView
              content: SizedBox(
                width: MediaQuery.of(context)
                    .size
                    .width, // Lebar menyesuaikan layar
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min, // Agar tinggi mengikuti isi
                    children: [
                      const Text("Edit Profil",
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold)),
                      const SizedBox(height: 25),

                      // FOTO PROFIL
                      CircleAvatar(
                          radius: 55,
                          backgroundColor: Colors.grey[800],
                          backgroundImage: _getImageProvider(user)),

                      const SizedBox(height: 15),

                      // BARIS TOMBOL AKSI (GANTI & HAPUS)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildPhotoButton(
                            icon: Icons.camera_alt,
                            label: "Ganti",
                            color: Colors.blueAccent,
                            onTap: () => auth.pickNewProfileImage(),
                          ),

                          // Tampilkan tombol hapus jika bukan foto default
                          if (user.webImageBytes != null ||
                              !user.profilePictureUrl.contains('users.jpg'))
                            const SizedBox(width: 20),

                          if (user.webImageBytes != null ||
                              !user.profilePictureUrl.contains('users.jpg'))
                            _buildPhotoButton(
                              icon: Icons.delete_forever,
                              label: "Hapus",
                              color: Colors.redAccent,
                              onTap: () => auth.removeProfileImage(),
                            ),
                        ],
                      ),

                      const SizedBox(height: 25),
                      // INPUT NAMA
                      TextField(
                          controller: nameController,
                          style: const TextStyle(color: Colors.white),
                          decoration:
                              _inputDecorDialog("Nama Lengkap", Icons.person)),
                      const SizedBox(height: 15),
                      // INPUT EMAIL
                      TextField(
                          controller: emailController,
                          style: const TextStyle(color: Colors.white),
                          decoration: _inputDecorDialog("Email", Icons.email)),

                      // Tambahan sedikit padding bawah agar tidak mepet keyboard
                      const SizedBox(height: 10),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text("Batal",
                        style: TextStyle(color: Colors.grey))),
                ElevatedButton(
                  onPressed: () {
                    auth.updateUserData(
                        nameController.text, emailController.text);
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                        content: Text("Profil berhasil diperbarui"),
                        backgroundColor: Colors.green));
                  },
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueAccent,
                      foregroundColor: Colors.white),
                  child: const Text("Simpan"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // --- HELPER UNTUK STYLE INPUT DIALOG ---
  InputDecoration _inputDecorDialog(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.grey),
      prefixIcon: Icon(icon, color: Colors.grey),
      filled: true,
      fillColor: Colors.black26,
      border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
    );
  }

  // Widget Helper untuk membuat tombol di bawah foto agar rapi
  Widget _buildPhotoButton(
      {required IconData icon,
      required String label,
      required Color color,
      required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
                border: Border.all(color: color.withOpacity(0.5))),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(height: 4),
          Text(label,
              style: TextStyle(
                  color: color, fontSize: 12, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  // --- DIALOG GANTI PASSWORD (DENGAN FITUR LIHAT PASSWORD) ---
  Future<void> _showChangePasswordDialog(BuildContext context) async {
    final oldPassController = TextEditingController();
    final newPassController = TextEditingController();
    final confirmPassController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    // Variabel untuk mengontrol status mata (sembunyi/lihat)
    bool obscureOld = true;
    bool obscureNew = true;
    bool obscureConfirm = true;

    await showDialog(
      context: context,
      builder: (context) {
        // StatefulBuilder digunakan agar UI di dalam dialog bisa update saat icon mata diklik
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              backgroundColor: const Color(0xFF1E1E1E),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
              title: const Text("Ganti Password",
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold)),
              content: SingleChildScrollView(
                // Tambahkan agar tidak overflow di layar kecil
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // --- PASSWORD LAMA ---
                      TextFormField(
                        controller: oldPassController,
                        obscureText: obscureOld,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          labelText: "Password Lama",
                          labelStyle: const TextStyle(color: Colors.grey),
                          filled: true,
                          fillColor: Colors.black26,
                          suffixIcon: IconButton(
                            icon: Icon(
                              obscureOld
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                              color: Colors.grey,
                            ),
                            onPressed: () =>
                                setStateDialog(() => obscureOld = !obscureOld),
                          ),
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide.none),
                        ),
                        validator: (v) => v!.isEmpty ? "Wajib diisi" : null,
                      ),
                      const SizedBox(height: 12),

                      // --- PASSWORD BARU ---
                      TextFormField(
                        controller: newPassController,
                        obscureText: obscureNew,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          labelText: "Password Baru",
                          labelStyle: const TextStyle(color: Colors.grey),
                          filled: true,
                          fillColor: Colors.black26,
                          suffixIcon: IconButton(
                            icon: Icon(
                              obscureNew
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                              color: Colors.grey,
                            ),
                            onPressed: () =>
                                setStateDialog(() => obscureNew = !obscureNew),
                          ),
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide.none),
                        ),
                        validator: (v) =>
                            v!.length < 6 ? "Minimal 6 karakter" : null,
                      ),
                      const SizedBox(height: 12),

                      // --- KONFIRMASI PASSWORD ---
                      TextFormField(
                        controller: confirmPassController,
                        obscureText: obscureConfirm,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          labelText: "Konfirmasi Password",
                          labelStyle: const TextStyle(color: Colors.grey),
                          filled: true,
                          fillColor: Colors.black26,
                          suffixIcon: IconButton(
                            icon: Icon(
                              obscureConfirm
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                              color: Colors.grey,
                            ),
                            onPressed: () => setStateDialog(
                                () => obscureConfirm = !obscureConfirm),
                          ),
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide.none),
                        ),
                        validator: (v) => v != newPassController.text
                            ? "Password tidak sama"
                            : null,
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text("Batal",
                        style: TextStyle(color: Colors.grey))),
                ElevatedButton(
                  onPressed: () async {
                    if (formKey.currentState!.validate()) {
                      final authService =
                          Provider.of<AuthService>(context, listen: false);
                      String? error = await authService.changePassword(
                          oldPassController.text, newPassController.text);

                      if (error == null) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text("Berhasil mengubah password!"),
                                backgroundColor: Colors.green));
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            content: Text(error), backgroundColor: Colors.red));
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text("Simpan"),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
