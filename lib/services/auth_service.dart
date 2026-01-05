// lib/services/auth_service.dart

// ignore_for_file: unnecessary_nullable_for_final_variable_declarations

import 'dart:typed_data'; // WAJIB: Untuk Uint8List (Gambar dari Komputer/Web)
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:image_picker/image_picker.dart'; // WAJIB: Import Image Picker

// Model User Lokal
class User {
  final String username;
  final String email;
  final String role;
  String profilePictureUrl;
  Uint8List? webImageBytes; // PROPERTI BARU: Simpan data gambar (Bytes)
  final DateTime joinedDate;

  User({
    required this.username,
    required this.email,
    this.role = 'user',
    this.profilePictureUrl = 'assets/images/profile.jpg',
    this.webImageBytes, // Tambahkan di constructor
    DateTime? joinedDate,
  }) : joinedDate = joinedDate ?? DateTime.now();
}

class AuthService extends ChangeNotifier {
  // Instance Firebase & Google Sign In
  final firebase_auth.FirebaseAuth _firebaseAuth = firebase_auth.FirebaseAuth.instance;
  
  // Konfigurasi Google Sign In
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    clientId: '736900760074-pdgt2vqlrpf4f8ioes3eu2h9gt62hscp.apps.googleusercontent.com',
    scopes: [
      'email',
      'profile',
    ],
  );

  User? _currentUser;
  User? get currentUser => _currentUser;

  // --- FUNGSI BARU: GANTI FOTO PROFIL (SUPPORT WEB & LOCAL) ---
  Future<void> pickNewProfileImage() async {
    final ImagePicker picker = ImagePicker();
    
    // Buka File Explorer / Galeri
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null && _currentUser != null) {
      // Baca file sebagai Bytes (Cocok untuk Web & Mobile)
      final Uint8List bytes = await image.readAsBytes();
      
      // Update data user di memori
      _currentUser!.webImageBytes = bytes;
      _currentUser!.profilePictureUrl = ''; // Kosongkan URL agar Bytes diprioritaskan
      
      notifyListeners(); // Update UI otomatis
    }
  }

  // LOGIN BIASA (SIMULASI)
  Future<bool> signIn(String email, String password) async {
    await Future.delayed(const Duration(seconds: 2));

    if (email.isNotEmpty && password.length > 3) {
      _currentUser = User(
        username: 'Faras', 
        email: email,
        role: 'user', 
        profilePictureUrl: 'assets/images/profile.jpg',
        joinedDate: DateTime.now(),
      );
      notifyListeners(); 
      return true; 
    } else {
      return false; 
    }
  }

  // UPDATE FOTO PROFIL (Legacy - String Path)
  void updateProfilePicture(String newPath) {
    if (_currentUser != null) {
      _currentUser!.profilePictureUrl = newPath;
      notifyListeners(); 
    }
  }

  // UPDATE DATA USER
  void updateUserData(String name, String email) {
    if (_currentUser != null) {
      // Kita buat object baru tapi pertahankan gambar yang sudah ada
      _currentUser = User(
        username: name,
        email: email,
        role: _currentUser!.role,
        profilePictureUrl: _currentUser!.profilePictureUrl,
        webImageBytes: _currentUser!.webImageBytes, // Pertahankan bytes gambar
        joinedDate: _currentUser!.joinedDate,
      );
      notifyListeners();
    }
  }

  // LOGOUT
  Future<void> signOut() async {
    if (await _googleSignIn.isSignedIn()) {
      await _googleSignIn.signOut();
      await _firebaseAuth.signOut();
    }
    
    await Future.delayed(const Duration(seconds: 1));
    _currentUser = null;
    notifyListeners(); 
  }

  // REGISTER
  Future<String?> registerWithEmailPassword(String username, String email, String password) async {
    await Future.delayed(const Duration(seconds: 2));
    if (email.isNotEmpty && password.length > 3) {
      _currentUser = User(
        username: username, 
        email: email, 
        role: 'user', 
        profilePictureUrl: 'assets/images/profile.jpg',
        joinedDate: DateTime.now(),
      );
      notifyListeners();
      return null;
    } else {
      return "Password lemah";
    }
  }
  
  // Fungsi cek login
  Future<bool> isLoggedIn() async {
    return _currentUser != null;
  }

  // GOOGLE SIGN IN
  Future<String?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null;

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      final firebase_auth.AuthCredential credential = firebase_auth.GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final firebase_auth.UserCredential userCredential = 
          await _firebaseAuth.signInWithCredential(credential);
      final firebaseUser = userCredential.user;

      if (firebaseUser != null) {
        _currentUser = User(
          username: firebaseUser.displayName ?? 'Google User', 
          email: firebaseUser.email ?? '', 
          role: 'user',
          profilePictureUrl: firebaseUser.photoURL ?? 'assets/images/profile.jpg',
          joinedDate: firebaseUser.metadata.creationTime ?? DateTime.now(),
        );
        notifyListeners();
      }
      
      return null;

    } on firebase_auth.FirebaseAuthException catch (e) {
      return e.message;
    } catch (e) {
      return e.toString();
    }
  }
}