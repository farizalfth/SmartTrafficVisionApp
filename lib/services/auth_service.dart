// lib/services/auth_service.dart

// ignore_for_file: unnecessary_nullable_for_final_variable_declarations, unused_element

import 'dart:typed_data';
import 'dart:convert'; // Untuk jsonEncode dan jsonDecode
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

// Model User Lokal
class User {
  int id; // ID unik dari database MySQL
  String username;
  String email;
  String? password;
  String profilePictureUrl;
  Uint8List? webImageBytes;
  DateTime joinedDate;
  String role;

  User({
    required this.id,
    required this.username,
    required this.email,
    this.password,
    required this.profilePictureUrl,
    this.webImageBytes,
    required this.joinedDate,
    required this.role,
  });
}

class AuthService extends ChangeNotifier {
  // Ganti IP dengan IP Laptop Anda agar HP bisa mengakses API
  final String baseUrl = "http://192.168.0.103/smarttraffic_api";

  final firebase_auth.FirebaseAuth _firebaseAuth =
      firebase_auth.FirebaseAuth.instance;

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    clientId:
        '736900760074-pdgt2vqlrpf4f8ioes3eu2h9gt62hscp.apps.googleusercontent.com',
    scopes: ['email', 'profile'],
  );

  User? _currentUser;
  User? get currentUser => _currentUser;

  AuthService() {
    // Biarkan kosong agar saat aplikasi dibuka user selalu diarahkan ke halaman Login
  }

  // --- PERSISTENCE (PENYIMPANAN SESSION LOKAL DI HP) ---

  Future<void> _saveToPrefs() async {
    if (_currentUser == null) return;
    final prefs = await SharedPreferences.getInstance();

    await prefs.setInt('user_id', _currentUser!.id);
    await prefs.setString('user_name', _currentUser!.username);
    await prefs.setString('user_email', _currentUser!.email);
    await prefs.setString('user_pp', _currentUser!.profilePictureUrl);
    await prefs.setString('user_role', _currentUser!.role);

    if (_currentUser!.password != null) {
      await prefs.setString('user_password', _currentUser!.password!);
    }

    if (_currentUser!.webImageBytes != null) {
      await prefs.setString(
          'user_web_bytes', base64Encode(_currentUser!.webImageBytes!));
    } else {
      await prefs.remove('user_web_bytes');
    }
  }

  Future<void> _loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final int? id = prefs.getInt('user_id');
    final String? name = prefs.getString('user_name');

    if (id != null && name != null) {
      String? webBytesBase64 = prefs.getString('user_web_bytes');
      _currentUser = User(
        id: id,
        username: name,
        email: prefs.getString('user_email') ?? '',
        password: prefs.getString('user_password'),
        role: prefs.getString('user_role') ?? 'user',
        profilePictureUrl:
            prefs.getString('user_pp') ?? 'assets/images/users.jpg',
        joinedDate: DateTime.now(),
        webImageBytes:
            webBytesBase64 != null ? base64Decode(webBytesBase64) : null,
      );
    }
  }

  // --- FUNGSI GANTI FOTO FINAL (SUPPORT WEB & HP) ---
  Future<void> pickNewProfileImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null && _currentUser != null) {
      try {
        final Uint8List imageBytes = await image.readAsBytes();

        // 1. Kirim File menggunakan MultipartRequest (Metode Bytes aman untuk Web & HP)
        var request =
            http.MultipartRequest('POST', Uri.parse("$baseUrl/upload_pp.php"));
        request.fields['id'] = _currentUser!.id.toString();

        // Gunakan fromBytes agar Laptop (Web) tidak error
        request.files.add(http.MultipartFile.fromBytes(
          'image',
          imageBytes,
          filename: 'upload.jpg',
        ));

        var streamedResponse = await request.send();
        var response = await http.Response.fromStream(streamedResponse);

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          if (data['status'] == 'success') {
            // 2. AMBIL URL PERMANEN DARI SERVER
            String serverImageUrl = data['url'];

            // 3. UPDATE USER MODEL SECARA TOTAL
            _currentUser!.profilePictureUrl = serverImageUrl;
            _currentUser!.webImageBytes =
                imageBytes; // Untuk tampilan instan di laptop

            // 4. SIMPAN PERMANEN KE HP (Agar saat buka app lagi tidak hilang)
            await _saveToPrefs();

            notifyListeners();
            debugPrint("Upload Berhasil! URL: $serverImageUrl");
          }
        }
      } catch (e) {
        debugPrint("Error Upload: $e");
      }
    }
  }

  // --- HAPUS FOTO (KEMBALI KE DEFAULT DI SERVER) ---
  Future<void> removeProfileImage() async {
    if (_currentUser != null) {
      try {
        await http.post(
          Uri.parse("$baseUrl/update_user.php"),
          headers: {"Content-Type": "application/json"},
          body: jsonEncode({
            'id': _currentUser!.id,
            'profile_picture': 'assets/images/users.jpg', // Kembali ke default
          }),
        );

        _currentUser!.profilePictureUrl = 'assets/images/users.jpg';
        _currentUser!.webImageBytes = null;
        await _saveToPrefs();
        notifyListeners();
      } catch (e) {
        debugPrint("Error Hapus Foto: $e");
      }
    }
  }

  // GANTI PASSWORD PERMANEN KE DATABASE
  Future<String?> changePassword(String oldPass, String newPass) async {
    final prefs = await SharedPreferences.getInstance();
    String storedPass = prefs.getString('user_password') ?? '';

    if (oldPass != storedPass) {
      return "Password lama tidak sesuai!";
    }

    if (_currentUser != null) {
      try {
        // 1. Update Password Baru ke Database MySQL
        final response = await http.post(
          Uri.parse("$baseUrl/update_user.php"),
          headers: {"Content-Type": "application/json"},
          body: jsonEncode({
            'id': _currentUser!.id,
            'new_password': newPass, // PHP harus menangani key 'new_password'
          }),
        );

        if (response.statusCode == 200) {
          // 2. Update lokal
          _currentUser!.password = newPass;
          await _saveToPrefs();
          notifyListeners();
          return null; // Sukses
        }
      } catch (e) {
        return "Gagal terhubung ke server: $e";
      }
    }
    return "Terjadi kesalahan sistem";
  }

  // UPDATE NAMA & EMAIL PERMANEN KE DATABASE
  Future<void> updateUserData(String name, String email) async {
    if (_currentUser == null) return;

    try {
      final response = await http.post(
        Uri.parse("$baseUrl/update_user.php"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          'id': _currentUser!.id,
          'username': name,
          'email': email,
          'role': _currentUser!.role,
        }),
      );

      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['status'] == 'success') {
        _currentUser!.username = name;
        _currentUser!.email = email;
        await _saveToPrefs();
        notifyListeners();
      }
    } catch (e) {
      debugPrint("Koneksi Error saat update: $e");
    }
  }

  // --- AUTH ACTIONS (LOGIN & REGISTER) ---

  Future<bool> signIn(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/login.php"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({'email': email, 'password': password}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['status'] == 'success') {
          final userData = data['user'];

          // --- UPDATE BAGIAN INI ---
          _currentUser = User(
            id: int.parse(userData['id'].toString()),
            username: userData['username'],
            email: userData['email'],
            password: password,
            role: userData['role'] ?? 'user',

            // INI YANG PENTING: Ambil URL foto profil dari database server
            // Jika di database kosong, gunakan gambar default aset
            profilePictureUrl: (userData['profile_picture'] != null &&
                    userData['profile_picture'] != "")
                ? userData['profile_picture']
                : 'assets/images/users.jpg',

            joinedDate: DateTime.now(),
          );
          // --------------------------

          await _saveToPrefs(); // Simpan data ke memori HP agar permanent
          notifyListeners(); // Beritahu UI untuk berubah (termasuk Sidebar)
          return true;
        }
      }
    } catch (e) {
      debugPrint("Login Error: $e");
    }
    return false;
  }

  Future<String?> registerWithEmailPassword(
      String username, String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/register.php"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          'username': username,
          'email': email,
          'password': password,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        if (data != null && data['status'] == 'success') {
          _currentUser = null; // Paksa login manual setelah daftar
          notifyListeners();
          return null;
        } else {
          return data['message'] ?? "Gagal mendaftar";
        }
      }
    } catch (e) {
      return "Koneksi Error: Pastikan Server Aktif ($e)";
    }
    return "Terjadi kesalahan";
  }

  Future<void> signOut() async {
    if (await _googleSignIn.isSignedIn()) {
      await _googleSignIn.signOut();
      await _firebaseAuth.signOut();
    }
    _currentUser = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear(); // Bersihkan session untuk login bersih berikutnya
    notifyListeners();
  }

  Future<bool> isLoggedIn() async {
    return _currentUser != null;
  }

  // --- GOOGLE SIGN IN (OPSIONAL) ---
  Future<String?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null;
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final firebase_auth.AuthCredential credential =
          firebase_auth.GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      final userCredential =
          await _firebaseAuth.signInWithCredential(credential);
      final firebaseUser = userCredential.user;

      if (firebaseUser != null) {
        _currentUser = User(
          id: 0,
          username: firebaseUser.displayName ?? 'Google User',
          email: firebaseUser.email ?? '',
          role: 'user',
          profilePictureUrl: firebaseUser.photoURL ?? 'assets/images/users.jpg',
          joinedDate: DateTime.now(),
        );
        await _saveToPrefs();
        notifyListeners();
      }
      return null;
    } catch (e) {
      return e.toString();
    }
  }
}
