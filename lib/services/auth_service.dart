// lib/services/auth_service.dart

// ignore_for_file: unnecessary_nullable_for_final_variable_declarations

import 'dart:typed_data';
import 'dart:convert'; // Untuk Base64 encoding gambar
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
    // Biarkan kosong agar aplikasi selalu mulai dari halaman Login saat pertama dibuka
  }

  // --- PERSISTENCE (PENYIMPANAN DATA PERMANEN KE HP) ---

  Future<void> _saveToPrefs() async {
    if (_currentUser == null) return;
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString('user_name', _currentUser!.username);
    await prefs.setString('user_email', _currentUser!.email);
    await prefs.setString('user_pp', _currentUser!.profilePictureUrl);

    // Simpan password secara permanen
    if (_currentUser!.password != null) {
      await prefs.setString('user_password', _currentUser!.password!);
    }

    // Simpan gambar web (Bytes) jika ada
    if (_currentUser!.webImageBytes != null) {
      await prefs.setString(
          'user_web_bytes', base64Encode(_currentUser!.webImageBytes!));
    } else {
      await prefs.remove('user_web_bytes');
    }
  }

  // Dipanggil saat Login berhasil untuk mengambil data yang tersimpan
  Future<void> _loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final String? name = prefs.getString('user_name');

    if (name != null) {
      String? webBytesBase64 = prefs.getString('user_web_bytes');
      _currentUser = User(
        username: name,
        email: prefs.getString('user_email') ?? '',
        password: prefs.getString('user_password'),
        role: 'user',
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
      _currentUser!.profilePictureUrl =
          'assets/images/users.jpg'; // Gambar Avatar Default
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

  // --- FUNGSI GANTI PASSWORD (LOGIKA PERMANEN) ---
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

  // --- AUTH ACTIONS (LOGIN & REGISTER) ---

  Future<bool> signIn(String email, String password) async {
    await Future.delayed(const Duration(seconds: 1));
    final prefs = await SharedPreferences.getInstance();

    String? storedEmail = prefs.getString('user_email');
    String? storedPass = prefs.getString('user_password');

    // Validasi: Harus cocok dengan data yang didaftarkan/disimpan di HP
    if (email == storedEmail && password == storedPass) {
      await _loadFromPrefs();
      notifyListeners();
      return true;
    }
    return false; // Login gagal
  }

  Future<void> signOut() async {
    if (await _googleSignIn.isSignedIn()) {
      await _googleSignIn.signOut();
      await _firebaseAuth.signOut();
    }
    _currentUser = null;
    notifyListeners();
  }

  // --- FUNGSI REGISTER (DIPERBAIKI) ---
  Future<String?> registerWithEmailPassword(
      String username, String email, String password) async {
    try {
      await Future.delayed(const Duration(seconds: 2));

      final prefs = await SharedPreferences.getInstance();

      // Simpan data calon user ke memori HP
      await prefs.setString('user_name', username);
      await prefs.setString('user_email', email);
      await prefs.setString('user_password', password);
      await prefs.setString('user_pp', 'assets/images/profile.jpg');

      // PENTING: Jangan isi _currentUser di sini!
      // Agar user wajib login manual lewat halaman login.
      _currentUser = null;

      notifyListeners();
      return null; // Sukses daftar
    } catch (e) {
      return e.toString();
    }
  }

  Future<bool> isLoggedIn() async {
    return _currentUser != null;
  }

  // GOOGLE SIGN IN
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
