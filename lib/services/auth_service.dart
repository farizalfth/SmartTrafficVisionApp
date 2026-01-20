// lib/services/auth_service.dart

import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;

// Model User
class User {
  String id;
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
  final firebase_auth.FirebaseAuth _auth = firebase_auth.FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  User? _currentUser;
  User? get currentUser => _currentUser;

  AuthService() {
    // Memantau perubahan status login (Auto-load data saat aplikasi dibuka)
    _auth.authStateChanges().listen((firebaseUser) {
      if (firebaseUser != null) {
        _loadUserData(firebaseUser.uid);
      } else {
        _currentUser = null;
        notifyListeners();
      }
    });
  }

  // --- HELPER: AMBIL DATA DARI FIRESTORE ---
  // Ini fungsi kunci agar foto tidak hilang saat login kembali
  Future<void> _loadUserData(String uid) async {
    try {
      DocumentSnapshot snap = await _firestore.collection('users').doc(uid).get();
      if (snap.exists) {
        Map<String, dynamic> data = snap.data() as Map<String, dynamic>;
        _currentUser = User(
          id: data['uid'] ?? uid,
          username: data['username'] ?? 'User',
          email: data['email'] ?? '',
          role: data['role'] ?? 'user',
          profilePictureUrl: data['profile_picture'] ?? 'assets/images/users.jpg',
          joinedDate: data['created_at'] != null
              ? (data['created_at'] as Timestamp).toDate()
              : DateTime.now(),
        );
        notifyListeners();
      }
    } catch (e) {
      debugPrint("Error loading user data: $e");
    }
  }

  // --- 1. REGISTER ---
  Future<String?> registerWithEmailPassword(
      String username, String email, String password) async {
    try {
      firebase_auth.UserCredential cred = await _auth
          .createUserWithEmailAndPassword(email: email, password: password);

      if (cred.user != null) {
        await _firestore.collection('users').doc(cred.user!.uid).set({
          'uid': cred.user!.uid,
          'username': username,
          'email': email,
          'role': 'user',
          'profile_picture': 'assets/images/users.jpg',
          'created_at': FieldValue.serverTimestamp(),
        });

        await signOut();
        return null;
      }
    } catch (e) {
      return e.toString();
    }
    return "Gagal mendaftar";
  }

  // --- 2. SIGN IN (EMAIL & PASSWORD) ---
  Future<bool> signIn(String email, String password) async {
    try {
      firebase_auth.UserCredential cred = await _auth
          .signInWithEmailAndPassword(email: email, password: password);

      if (cred.user != null) {
        await _loadUserData(cred.user!.uid); // Ambil data lengkap dari Firestore
        return true;
      }
    } catch (e) {
      debugPrint("Login Error: $e");
    }
    return false;
  }

  // --- 3. GOOGLE SIGN IN ---
  Future<String?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return "Batal";

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final firebase_auth.AuthCredential credential = firebase_auth.GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      firebase_auth.UserCredential userCred = await _auth.signInWithCredential(credential);

      // Cek apakah user sudah ada di Firestore
      DocumentSnapshot snap = await _firestore.collection('users').doc(userCred.user!.uid).get();

      if (!snap.exists) {
        await _firestore.collection('users').doc(userCred.user!.uid).set({
          'uid': userCred.user!.uid,
          'username': userCred.user!.displayName ?? "User Google",
          'email': userCred.user!.email,
          'role': 'user',
          'profile_picture': userCred.user!.photoURL ?? 'assets/images/users.jpg',
          'created_at': FieldValue.serverTimestamp(),
        });
      }

      await _loadUserData(userCred.user!.uid);
      return null;
    } catch (e) {
      return "Gagal masuk dengan Google: $e";
    }
  }

  // --- 4. GANTI PASSWORD ---
  Future<String?> changePassword(String oldPass, String newPass) async {
    try {
      firebase_auth.User? user = _auth.currentUser;
      if (user != null) {
        firebase_auth.AuthCredential credential = firebase_auth.EmailAuthProvider.credential(
                email: user.email!, password: oldPass);
        await user.reauthenticateWithCredential(credential);
        await user.updatePassword(newPass);
        return null;
      }
    } catch (e) {
      return "Password lama salah atau terjadi gangguan.";
    }
    return "User tidak ditemukan";
  }

  // --- 5. UPDATE DATA PROFIL ---
  Future<void> updateUserData(String name, String email) async {
    if (_currentUser == null) return;
    try {
      await _firestore.collection('users').doc(_currentUser!.id).update({
        'username': name,
        'email': email,
      });
      _currentUser!.username = name;
      _currentUser!.email = email;
      notifyListeners();
    } catch (e) {
      debugPrint("Update Error: $e");
    }
  }

  // --- 6. GANTI FOTO (FIXED) ---
  Future<void> pickNewProfileImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 40,
    );

    if (image != null && _currentUser != null) {
      try {
        // PREVIEW INSTAN
        if (kIsWeb) {
          _currentUser!.webImageBytes = await image.readAsBytes();
        } else {
          // Gunakan path file lokal untuk preview di HP agar tidak abu-abu
          _currentUser!.profilePictureUrl = image.path;
        }
        notifyListeners();

        // PROSES UPLOAD
        final Uint8List bytes = await image.readAsBytes();
        String fileName = 'profile_${_currentUser!.id}.jpg';
        firebase_storage.Reference ref = firebase_storage.FirebaseStorage.instance
            .ref().child('user_profiles').child(fileName);

        await ref.putData(bytes);
        String rawUrl = await ref.getDownloadURL();
        
        // Cache busting agar gambar langsung ganti
        String finalUrl = "$rawUrl?v=${DateTime.now().millisecondsSinceEpoch}";

        // UPDATE FIRESTORE
        await _firestore.collection('users').doc(_currentUser!.id).update({
          'profile_picture': finalUrl
        });

        // UPDATE FIREBASE AUTH PROFILE (CADANGAN)
        await _auth.currentUser?.updatePhotoURL(finalUrl);

        // SYNC STATE
        _currentUser!.profilePictureUrl = finalUrl;
        _currentUser!.webImageBytes = null;
        notifyListeners();

        debugPrint("Update Foto Berhasil: $finalUrl");
      } catch (e) {
        debugPrint("Upload Foto Error: $e");
      }
    }
  }

  // --- 7. HAPUS FOTO ---
  Future<void> removeProfileImage() async {
    if (_currentUser != null) {
      const defaultImg = 'assets/images/users.jpg';
      await _firestore.collection('users').doc(_currentUser!.id).update({
        'profile_picture': defaultImg
      });
      await _auth.currentUser?.updatePhotoURL(null);
      
      _currentUser!.profilePictureUrl = defaultImg;
      _currentUser!.webImageBytes = null;
      notifyListeners();
    }
  }

  // --- 8. LOGOUT ---
  Future<void> signOut() async {
    await _auth.signOut();
    await _googleSignIn.signOut();
    _currentUser = null;
    notifyListeners();
  }

  Future<bool> isLoggedIn() async {
    return _auth.currentUser != null;
  }
}