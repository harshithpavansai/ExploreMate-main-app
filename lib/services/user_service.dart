import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/user_model.dart';

/// User profile & XP service backed by Firestore.
/// Collection: `users/{uid}`
class UserService {
  UserService._();
  static final UserService instance = UserService._();

  final FirebaseFirestore _db = FirebaseFirestore.instance;
  static const String _col = 'users';

  // ── XP / Level helpers (pure — also used in unit tests) ──────────────────

  /// Returns the level for a given total XP (each level costs level×500 XP).
  static int calculateLevel(int xp) {
    int level = 1;
    while (xp >= level * 500) {
      level++;
    }
    return level;
  }

  /// Progress fraction [0..1] within the current level band.
  static double calculateLevelProgress(UserModel user) {
    final lower = (user.level - 1) * 500;
    final upper = user.level * 500;
    return ((user.xp - lower) / (upper - lower)).clamp(0.0, 1.0);
  }

  // ── Firestore CRUD ────────────────────────────────────────────────────────

  /// Fetch a user profile from Firestore.
  Future<UserModel?> getUserProfile(String uid) async {
    try {
      final doc = await _db.collection(_col).doc(uid).get();
      if (!doc.exists || doc.data() == null) return null;
      return UserModel.fromMap(uid, doc.data()!);
    } catch (e) {
      debugPrint('UserService.getUserProfile error: $e');
      return null;
    }
  }

  /// Create or merge a user document (called after sign-up / first login).
  Future<void> createOrUpdateProfile(UserModel user) async {
    try {
      await _db.collection(_col).doc(user.uid).set(
            user.toMap(),
            SetOptions(merge: true),
          );
    } catch (e) {
      debugPrint('UserService.createOrUpdateProfile error: $e');
    }
  }

  /// Full profile overwrite (name, avatar, etc.).
  Future<void> updateProfile(UserModel updated) async {
    try {
      await _db.collection(_col).doc(updated.uid).update(updated.toMap());
    } catch (e) {
      debugPrint('UserService.updateProfile error: $e');
    }
  }

  /// Award [delta] XP to user [uid], auto-calculating the new level.
  /// Returns the updated [UserModel] or null on failure.
  Future<UserModel?> updateXP(String uid, int delta) async {
    try {
      final ref = _db.collection(_col).doc(uid);
      final doc = await ref.get();
      if (!doc.exists || doc.data() == null) return null;

      final user = UserModel.fromMap(uid, doc.data()!);
      final newXp = user.xp + delta;
      final newLevel = calculateLevel(newXp);

      await ref.update({'xp': newXp, 'level': newLevel});
      return user.copyWith(xp: newXp, level: newLevel);
    } catch (e) {
      debugPrint('UserService.updateXP error: $e');
      return null;
    }
  }

  /// Fetch the top-20 leaderboard ordered by XP descending.
  Future<List<UserModel>> getLeaderboard() async {
    try {
      final snap = await _db
          .collection(_col)
          .orderBy('xp', descending: true)
          .limit(20)
          .get();
      return snap.docs
          .map((d) => UserModel.fromMap(d.id, d.data()))
          .toList();
    } catch (e) {
      debugPrint('UserService.getLeaderboard error: $e');
      return [];
    }
  }

  /// Add a badge if the user doesn't already have it.
  Future<void> addBadge(String uid, String badge) async {
    try {
      await _db.collection(_col).doc(uid).update({
        'badges': FieldValue.arrayUnion([badge]),
      });
    } catch (e) {
      debugPrint('UserService.addBadge error: $e');
    }
  }

  // ── Convenience wrapper (kept for backward compat) ────────────────────────
  double levelProgress(UserModel user) => calculateLevelProgress(user);
}
