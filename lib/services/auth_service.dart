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
  String username;
  String email;
  String? password;
  String profilePictureUrl;
  Uint8List? webImageBytes;
  DateTime joinedDate;
  String role;

  User({
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
  // Ganti localhost dengan 10.0.2.2 jika menggunakan emulator Android
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
    // Aplikasi selalu mulai dari halaman Login saat pertama dibuka
  }

  // --- PERSISTENCE (PENYIMPANAN DATA PERMANEN KE HP) ---

  Future<void> _saveToPrefs() async {
    if (_currentUser == null) return;
    final prefs = await SharedPreferences.getInstance();

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
    final String? name = prefs.getString('user_name');

    if (name != null) {
      String? webBytesBase64 = prefs.getString('user_web_bytes');
      _currentUser = User(
        username: name,
        email: prefs.getString('user_email') ?? '',
        password: prefs.getString('user_password'),
        role: prefs.getString('user_role') ?? 'user',
        profilePictureUrl:
            prefs.getString('user_pp') ?? 'assets/images/profile.jpg',
        joinedDate: DateTime.now(),
        webImageBytes:
            webBytesBase64 != null ? base64Decode(webBytesBase64) : null,
      );
    }
  }

  // --- PROFILE ACTIONS (FOTO & DATA) ---

  Future<void> pickNewProfileImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null && _currentUser != null) {
      final Uint8List bytes = await image.readAsBytes();
      _currentUser!.webImageBytes = bytes;
      _currentUser!.profilePictureUrl = image.path;
      await _saveToPrefs();
      notifyListeners();
    }
  }

  Future<void> removeProfileImage() async {
    if (_currentUser != null) {
      _currentUser!.profilePictureUrl = 'assets/images/users.jpg';
      _currentUser!.webImageBytes = null;
      await _saveToPrefs();
      notifyListeners();
    }
  }

  void updateUserData(String name, String email) {
    if (_currentUser != null) {
      _currentUser!.username = name;
      _currentUser!.email = email;
      _saveToPrefs();
      notifyListeners();
    }
  }

  Future<String?> changePassword(String oldPass, String newPass) async {
    final prefs = await SharedPreferences.getInstance();
    String storedPass = prefs.getString('user_password') ?? '';

    if (oldPass != storedPass) {
      return "Password lama tidak sesuai!";
    }

    if (_currentUser != null) {
      _currentUser!.password = newPass;
      await _saveToPrefs();
      notifyListeners();
      return null;
    }
    return "Terjadi kesalahan";
  }

  // --- AUTH ACTIONS (INTEGRASI KE PHP ANDA) ---

  // LOGIN DISESUAIKAN DENGAN login.php ANDA
  Future<bool> signIn(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/login.php"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        // Pengecekan status 'success' sesuai login.php Anda
        if (data != null && data['status'] == 'success') {
          final userData = data['user'];
          
          _currentUser = User(
            username: userData['username'],
            email: userData['email'],
            password: password,
            role: userData['role'] ?? 'user',
            profilePictureUrl: 'assets/images/profile.jpg', // Default awal
            joinedDate: DateTime.now(), 
          );

          await _saveToPrefs();
          notifyListeners();
          return true;
        }
      }
    } catch (e) {
      debugPrint("Login Error: $e");
    }
    return false;
  }

  // REGISTER DISESUAIKAN DENGAN register.php ANDA
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
        
        // Pengecekan status 'success' sesuai register.php Anda
        if (data != null && data['status'] == 'success') {
          // Backup data ke prefs lokal
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('user_name', username);
          await prefs.setString('user_email', email);
          await prefs.setString('user_password', password);
          
          _currentUser = null; 
          notifyListeners();
          return null; // Berhasil
        } else {
          return data['message'] ?? "Gagal mendaftar";
        }
      }
      return "Gagal terhubung ke server (HTTP ${response.statusCode})";
    } catch (e) {
      return "Koneksi Error: Pastikan XAMPP Aktif ($e)";
    }
  }

  // --- FIREBASE & GOOGLE (TETAP DIPERTAHANKAN) ---

  Future<void> signOut() async {
    if (await _googleSignIn.isSignedIn()) {
      await _googleSignIn.signOut();
      await _firebaseAuth.signOut();
    }
    _currentUser = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear(); 
    notifyListeners();
  }

  Future<bool> isLoggedIn() async {
    return _currentUser != null;
  }

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
          username: firebaseUser.displayName ?? 'Google User',
          email: firebaseUser.email ?? '',
          role: 'user',
          profilePictureUrl:
              firebaseUser.photoURL ?? 'assets/images/profile.jpg',
          joinedDate: firebaseUser.metadata.creationTime ?? DateTime.now(),
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