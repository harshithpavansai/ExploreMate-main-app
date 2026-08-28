import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../models/audio_tour_model.dart';
import 'api_service.dart';

/// Audio Tour service.
///
/// Narration text: fetched from the Gemini backend (`POST /api/ai/audio-narration`).
/// Text-to-Speech: rendered locally via the `flutter_tts` package.
///
/// This replaces the old mock asset-URL approach with a fully live AI + TTS pipeline.
class AudioTourService {
  AudioTourService._();
  static final AudioTourService instance = AudioTourService._();

  final ApiService _api = ApiService();
  final FlutterTts _tts = FlutterTts();

  bool _ttsInitialized = false;
  bool _isPlaying = false;
  bool get isPlaying => _isPlaying;

  // ── TTS initialisation ─────────────────────────────────────────────────────

  Future<void> _initTts({String language = 'en-IN'}) async {
    if (_ttsInitialized) return;
    await _tts.setLanguage(language);
    await _tts.setSpeechRate(0.48);   // natural pace
    await _tts.setVolume(1.0);
    await _tts.setPitch(1.0);
    _tts.setCompletionHandler(() => _isPlaying = false);
    _ttsInitialized = true;
  }

  // ── Public API ─────────────────────────────────────────────────────────────

  /// Fetch an AI-generated narration for [placeName] from the backend,
  /// then speak it aloud via device TTS. Returns the narration text.
  Future<String> playNarration(
    String placeName, {
    String? question,
    String language = 'en-IN',
  }) async {
    try {
      await _initTts(language: language);

      // 1. Fetch narration text from Gemini backend
      final text = await _api.getAudioNarration(placeName, question: question);
      if (text.isEmpty) return 'No narration available for this place.';

      // 2. Speak it out
      _isPlaying = true;
      await _tts.speak(text);
      return text;
    } catch (e) {
      debugPrint('AudioTourService.playNarration error: $e');
      _isPlaying = false;
      return 'Audio narration failed. Please try again.';
    }
  }

  /// Stop any ongoing TTS playback.
  Future<void> stopNarration() async {
    _isPlaying = false;
    await _tts.stop();
  }

  /// Pause TTS (platform-dependent; falls back to stop on Android).
  Future<void> pauseNarration() async {
    _isPlaying = false;
    await _tts.pause();
  }

  /// Speak any arbitrary [text] through the device TTS engine.
  Future<void> speak(String text, {String language = 'en-IN'}) async {
    await _initTts(language: language);
    _isPlaying = true;
    await _tts.speak(text);
  }

  // ── Catalogue (metadata only — no audio files needed) ─────────────────────

  /// Returns catalogue entries for a given place (metadata, no audio file).
  Future<List<AudioTourModel>> getToursForPlace(String placeId) async {
    return _catalogue.where((t) => t.placeId == placeId).toList();
  }

  /// Returns all catalogue entries.
  Future<List<AudioTourModel>> getAllTours() async {
    return List.unmodifiable(_catalogue);
  }

  /// Returns tours in a specific language.
  Future<List<AudioTourModel>> getToursByLanguage(String language) async {
    return _catalogue
        .where((t) => t.language.toLowerCase() == language.toLowerCase())
        .toList();
  }

  // ── Static catalogue (metadata — AI generates actual narration live) ───────
  static const List<AudioTourModel> _catalogue = [
    AudioTourModel(
      tourId: 'at001',
      placeId: 'p006',
      placeName: 'Submarine Museum',
      language: 'English',
      durationSec: 720,
      audioUrl: '', // live AI narration, no file needed
      rating: 4.7,
      playCount: 1240,
    ),
    AudioTourModel(
      tourId: 'at002',
      placeId: 'p003',
      placeName: 'Sunset Cliffside',
      language: 'English',
      durationSec: 540,
      audioUrl: '',
      rating: 4.9,
      playCount: 870,
    ),
    AudioTourModel(
      tourId: 'at003',
      placeId: 'p004',
      placeName: 'Borra Caves',
      language: 'English',
      durationSec: 900,
      audioUrl: '',
      rating: 4.8,
      playCount: 2100,
    ),
    AudioTourModel(
      tourId: 'at004',
      placeId: 'p004',
      placeName: 'Borra Caves',
      language: 'Telugu',
      durationSec: 870,
      audioUrl: '',
      rating: 4.6,
      playCount: 560,
    ),
    AudioTourModel(
      tourId: 'at005',
      placeId: 'p001',
      placeName: 'Lotus Lake Viewpoint',
      language: 'English',
      durationSec: 420,
      audioUrl: '',
      rating: 4.5,
      playCount: 320,
    ),
  ];
}
