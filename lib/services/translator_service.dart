import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/translation_model.dart';
import 'api_service.dart';

/// Translator service.
///
/// Translation:   calls the Node.js/Gemini backend (`POST /api/ai/translate`).
/// History:       persisted to Firestore `translations/{uid}/history` sub-collection.
class TranslatorService {
  TranslatorService._();
  static final TranslatorService instance = TranslatorService._();

  final ApiService _api = ApiService();
  FirebaseFirestore get _db => FirebaseFirestore.instance;

  // ── Translation ────────────────────────────────────────────────────────────

  /// Translate [text] to [toLang] using the Gemini-powered backend.
  /// Falls back to a bracket placeholder when the backend is offline.
  Future<String> translate(
      String text, String fromLang, String toLang) async {
    try {
      final result = await _api.translateText(text, toLang);
      // If the backend returned an error string, return it as-is
      return result;
    } catch (e) {
      debugPrint('TranslatorService.translate error: $e');
      return '[$toLang translation unavailable — check your network]';
    }
  }

  // ── History (Firestore) ────────────────────────────────────────────────────

  /// Save a translation to Firestore under `translations/{userId}/history`.
  Future<void> saveToHistory(TranslationModel translation) async {
    try {
      await _db
          .collection('translations')
          .doc(translation.userId)
          .collection('history')
          .doc(translation.id)
          .set(translation.toMap());
    } catch (e) {
      debugPrint('TranslatorService.saveToHistory error: $e');
    }
  }

  /// Fetch the last 20 saved translations for [userId].
  Future<List<TranslationModel>> getHistory(String userId) async {
    try {
      final snap = await _db
          .collection('translations')
          .doc(userId)
          .collection('history')
          .orderBy('savedAt', descending: true)
          .limit(20)
          .get();

      return snap.docs
          .map((d) => TranslationModel.fromMap(d.id, d.data()))
          .toList();
    } catch (e) {
      debugPrint('TranslatorService.getHistory error: $e');
      return [];
    }
  }

  /// Delete a single history entry.
  Future<void> deleteHistory(String userId, String translationId) async {
    try {
      await _db
          .collection('translations')
          .doc(userId)
          .collection('history')
          .doc(translationId)
          .delete();
    } catch (e) {
      debugPrint('TranslatorService.deleteHistory error: $e');
    }
  }
}
