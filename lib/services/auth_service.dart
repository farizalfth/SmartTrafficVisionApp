// lib/services/auth_service.dart

import 'dart:typed_data';
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
    // Session dicek oleh AuthWrapper di main.dart
  }

  // --- 1. REGISTER (EMAIL & PASSWORD) ---
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
        DocumentSnapshot snap =
            await _firestore.collection('users').doc(cred.user!.uid).get();
        if (snap.exists) {
          Map<String, dynamic> data = snap.data() as Map<String, dynamic>;
          _currentUser = User(
            id: data['uid'],
            username: data['username'],
            email: data['email'],
            password: password,
            role: data['role'] ?? 'user',
            profilePictureUrl:
                data['profile_picture'] ?? 'assets/images/users.jpg',
            joinedDate: data['created_at'] != null
                ? (data['created_at'] as Timestamp).toDate()
                : DateTime.now(),
          );
          notifyListeners();
          return true;
        }
      }
    } catch (e) {
      debugPrint("Login Error: $e");
    }
    return false;
  }

  // --- 3. GOOGLE SIGN IN (FIXED: TANPA GAGAL SINKRON) ---
  Future<String?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return "Batal";

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final firebase_auth.AuthCredential credential =
          firebase_auth.GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      firebase_auth.UserCredential userCred =
          await _auth.signInWithCredential(credential);

      // Ambil atau buat data di Firestore
      DocumentSnapshot snap =
          await _firestore.collection('users').doc(userCred.user!.uid).get();

      Map<String, dynamic> userData;
      if (!snap.exists) {
        userData = {
          'uid': userCred.user!.uid,
          'username': userCred.user!.displayName ?? "User Google",
          'email': userCred.user!.email,
          'role': 'user',
          'profile_picture':
              userCred.user!.photoURL ?? 'assets/images/users.jpg',
          'created_at': FieldValue.serverTimestamp(),
        };
        await _firestore
            .collection('users')
            .doc(userCred.user!.uid)
            .set(userData);
      } else {
        userData = snap.data() as Map<String, dynamic>;
      }

      // LANGSUNG SET CURRENT USER (Tanpa panggil fungsi signIn email/pass)
      _currentUser = User(
        id: userData['uid'],
        username: userData['username'],
        email: userData['email'],
        password: null,
        role: userData['role'] ?? 'user',
        profilePictureUrl:
            userData['profile_picture'] ?? 'assets/images/users.jpg',
        joinedDate: userData['created_at'] != null
            ? (userData['created_at'] as Timestamp).toDate()
            : DateTime.now(),
      );

      notifyListeners(); // <--- WAJIB ADA: Agar UI tahu user sudah masuk
      return null; // <--- WAJIB RETURN NULL: Tanda sukses ke UI
    } catch (e) {
      return "Gagal masuk dengan Google: $e";
    }
  }

  // --- 4. GANTI PASSWORD ---
  Future<String?> changePassword(String oldPass, String newPass) async {
    try {
      firebase_auth.User? user = _auth.currentUser;
      if (user != null) {
        firebase_auth.AuthCredential credential =
            firebase_auth.EmailAuthProvider.credential(
                email: user.email!, password: oldPass);
        await user.reauthenticateWithCredential(credential);
        await user.updatePassword(newPass);
        if (_currentUser != null) _currentUser!.password = newPass;
        notifyListeners();
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

  // --- 6. GANTI FOTO (UPLOAD KE STORAGE PERMANEN) ---
  Future<void> pickNewProfileImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null && _currentUser != null) {
      try {
        final Uint8List bytes = await image.readAsBytes();
        String fileName = 'profile_${_currentUser!.id}.jpg';

        firebase_storage.Reference ref = firebase_storage
            .FirebaseStorage.instance
            .ref()
            .child('user_profiles')
            .child(fileName);

        await ref.putData(bytes);
        String downloadUrl = await ref.getDownloadURL();

        await _firestore
            .collection('users')
            .doc(_currentUser!.id)
            .update({'profile_picture': downloadUrl});

        _currentUser!.webImageBytes = bytes;
        _currentUser!.profilePictureUrl = downloadUrl;
        notifyListeners();
      } catch (e) {
        debugPrint("Upload Foto Error: $e");
      }
    }
  }

  Future<void> removeProfileImage() async {
    if (_currentUser != null) {
      await _firestore
          .collection('users')
          .doc(_currentUser!.id)
          .update({'profile_picture': 'assets/images/users.jpg'});
      _currentUser!.profilePictureUrl = 'assets/images/users.jpg';
      _currentUser!.webImageBytes = null;
      notifyListeners();
    }
  }

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
