import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/user_model.dart';

import '../config/api_config.dart';

class AuthService {
  AuthService._();
  static final AuthService instance = AuthService._();

  final _storage = const FlutterSecureStorage();

  UserModel? _currentUser;
  UserModel? get currentUser => _currentUser;
  bool get isSignedIn => FirebaseAuth.instance.currentUser != null;

  /// Sign in with Firebase and Sync to Node.js Backend
  Future<String?> signIn(String email, String password) async {
    try {
      // 1. Firebase Auth
      final credential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // 2. Sync with Node.js/PostgreSQL
      if (credential.user != null) {
        await _syncWithBackend(credential.user!);
      }
      return null; // success
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') return 'No user found for that email.';
      if (e.code == 'wrong-password') return 'Wrong password provided.';
      if (e.code == 'invalid-email') return 'The email address is badly formatted.';
      if (e.code == 'invalid-credential') return 'Invalid email or password.';
      return e.message;
    } catch (e) {
      return 'An unexpected error occurred during login.';
    }
  }

  /// Sign Up with Firebase and Sync to Node.js Backend
  Future<String?> signUp(String name, String email, String password) async {
    try {
      // 1. Firebase Auth
      final credential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credential.user != null) {
        await credential.user!.updateDisplayName(name);
        
        // 2. Sync with Node.js/PostgreSQL
        await _syncWithBackend(credential.user!, overrideName: name);
      }
      return null; // success
    } on FirebaseAuthException catch (e) {
      if (e.code == 'weak-password') return 'The password provided is too weak.';
      if (e.code == 'email-already-in-use') return 'The account already exists for that email.';
      if (e.code == 'invalid-email') return 'The email address is badly formatted.';
      return e.message;
    } catch (e) {
      return 'An unexpected error occurred during sign up.';
    }
  }

  Future<void> _syncWithBackend(User firebaseUser, {String? overrideName}) async {
    final body = jsonEncode({
      'uid': firebaseUser.uid,
      'email': firebaseUser.email,
      'name': overrideName ?? firebaseUser.displayName ?? 'Explorer',
    });
    final headers = {'Content-Type': 'application/json'};

    // Try local backend first, then Render fallback
    for (int i = 0; i < 2; i++) {
      try {
        final response = await http.post(
          ApiConfig.getUri('/auth/sync'),
          headers: headers,
          body: body,
        ).timeout(const Duration(seconds: 8));

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          await _storage.write(key: 'jwt_token', value: data['token']);

          final userMap = data['user'];
          _currentUser = UserModel(
            uid: userMap['id'],
            name: userMap['name'] ?? 'Explorer',
            email: userMap['email'],
            level: userMap['level'] ?? 1,
            xp: userMap['xp'] ?? 0,
            createdAt: DateTime.now(),
          );
          return; // synced successfully
        }
      } catch (e) {
        debugPrint('Warning: sync failed — $e');
        if (i == 0) ApiConfig.useBackupUrl();
      }
    }
    // Both failed — user is still logged in via Firebase; XP/level will load from Firestore
    debugPrint('Backend sync skipped — continuing with Firebase-only session.');
  }

  Future<void> signOut() async {
    await FirebaseAuth.instance.signOut();
    await _storage.delete(key: 'jwt_token');
    _currentUser = null;
  }
}
