import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../config/api_config.dart';

class ApiService {
  final storage = const FlutterSecureStorage();

  // ── Authentication ────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await http.post(
        ApiConfig.getUri('/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      ).timeout(const Duration(seconds: 10));

      final decoded = jsonDecode(response.body);
      if (response.statusCode == 200) {
        final token = decoded['data']?['tokens']?['accessToken'] ?? decoded['token'];
        final user = decoded['data']?['user'] ?? decoded['user'];
        await storage.write(key: 'jwt_token', value: token);
        return {'success': true, 'user': user};
      } else {
        final msg = decoded['message'] ?? decoded['msg'] ?? 'Login failed';
        return {'success': false, 'msg': msg};
      }
    } catch (_) {
      return {'success': false, 'msg': 'Network Error. Is the backend running?'};
    }
  }

  Future<Map<String, dynamic>> register(
      String name, String email, String password) async {
    try {
      final response = await http.post(
        ApiConfig.getUri('/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'name': name, 'email': email, 'password': password}),
      ).timeout(const Duration(seconds: 10));

      final decoded = jsonDecode(response.body);
      if (response.statusCode == 200 || response.statusCode == 201) {
        final token = decoded['data']?['tokens']?['accessToken'] ?? decoded['token'];
        final user = decoded['data']?['user'] ?? decoded['user'];
        await storage.write(key: 'jwt_token', value: token);
        return {'success': true, 'user': user};
      } else {
        final msg = decoded['message'] ?? decoded['msg'] ?? 'Registration failed';
        return {'success': false, 'msg': msg};
      }
    } catch (_) {
      return {'success': false, 'msg': 'Network Error. Is the backend running?'};
    }
  }

  Future<void> logout() async => storage.delete(key: 'jwt_token');

  Future<String?> getToken() async => storage.read(key: 'jwt_token');

  // ── Destinations ──────────────────────────────────────────────────────────

  Future<List<dynamic>> getDestinations() async {
    for (int i = 0; i < 2; i++) {
      try {
        final response = await http
            .get(ApiConfig.getUri('/destinations'))
            .timeout(const Duration(seconds: 8));
        if (response.statusCode == 200) {
          final decoded = jsonDecode(response.body);
          if (decoded is Map && decoded.containsKey('data')) {
            final dataVal = decoded['data'];
            if (dataVal is Map && dataVal.containsKey('items')) {
              return dataVal['items'];
            }
            return dataVal;
          }
          return decoded;
        }
      } catch (_) {
        if (i == 0) ApiConfig.useBackupUrl();
      }
    }
    return [];
  }

  // ── Trips ─────────────────────────────────────────────────────────────────

  Future<List<dynamic>> getTrips() async {
    try {
      final token = await getToken();
      if (token == null) return [];
      final response = await http.get(
        ApiConfig.getUri('/trips'),
        headers: {'Authorization': 'Bearer $token'},
      ).timeout(const Duration(seconds: 8));
      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        if (decoded is Map && decoded.containsKey('data')) {
          return decoded['data'];
        }
        return decoded;
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  // ── AI Features (no auth token needed) ────────────────────────────────────

  Future<String> translateText(String text, String targetLanguage) async {
    final Map<String, String> languageCodes = {
      'Arabic': 'ar',
      'Bengali': 'bn',
      'Chinese Simplified': 'zh',
      'Chinese Traditional': 'zh-TW',
      'Dutch': 'nl',
      'English': 'en',
      'French': 'fr',
      'German': 'de',
      'Greek': 'el',
      'Gujarati': 'gu',
      'Hebrew': 'he',
      'Hindi': 'hi',
      'Indonesian': 'id',
      'Italian': 'it',
      'Japanese': 'ja',
      'Kannada': 'kn',
      'Korean': 'ko',
      'Malay': 'ms',
      'Malayalam': 'ml',
      'Marathi': 'mr',
      'Nepali': 'ne',
      'Odia': 'or',
      'Persian': 'fa',
      'Polish': 'pl',
      'Portuguese': 'pt',
      'Punjabi': 'pa',
      'Russian': 'ru',
      'Sanskrit': 'sa',
      'Spanish': 'es',
      'Swahili': 'sw',
      'Tamil': 'ta',
      'Telugu': 'te',
      'Thai': 'th',
      'Turkish': 'tr',
      'Ukrainian': 'uk',
      'Urdu': 'ur',
      'Vietnamese': 'vi',
    };

    final targetCode = languageCodes[targetLanguage] ?? targetLanguage;

    for (int i = 0; i < 2; i++) {
      try {
        final token = await getToken();
        final response = await http.post(
          ApiConfig.getUri('/translator'),
          headers: {
            'Content-Type': 'application/json',
            if (token != null) 'Authorization': 'Bearer $token',
          },
          body: jsonEncode({'text': text, 'target': targetCode}),
        ).timeout(const Duration(seconds: 8));

        if (response.statusCode == 200) {
          final resData = jsonDecode(response.body);
          final translated = resData['data']?['translated'] ?? resData['translated'];
          if (translated != null) {
            final isMock = resData['data']?['mock'] == true || resData['mock'] == true || translated.toString().startsWith('[mock-');
            final hasError = resData['data']?['error'] != null || resData['error'] != null;

            if (isMock || hasError) {
              try {
                final freeUrl = 'https://translate.googleapis.com/translate_a/single?client=gtx&sl=auto&tl=$targetCode&dt=t&q=${Uri.encodeComponent(text)}';
                final freeRes = await http.get(Uri.parse(freeUrl)).timeout(const Duration(seconds: 5));
                if (freeRes.statusCode == 200) {
                  final decoded = jsonDecode(freeRes.body);
                  if (decoded != null && decoded is List && decoded.isNotEmpty && decoded[0] is List && decoded[0].isNotEmpty) {
                    return decoded[0][0][0].toString();
                  }
                }
              } catch (_) {}
            }
            return translated;
          }
        }
      } catch (_) {
        if (i == 0) ApiConfig.useBackupUrl();
      }
    }

    // Direct frontend fallback if backend is offline/failed
    try {
      final freeUrl = 'https://translate.googleapis.com/translate_a/single?client=gtx&sl=auto&tl=$targetCode&dt=t&q=${Uri.encodeComponent(text)}';
      final freeRes = await http.get(Uri.parse(freeUrl)).timeout(const Duration(seconds: 5));
      if (freeRes.statusCode == 200) {
        final decoded = jsonDecode(freeRes.body);
        if (decoded != null && decoded is List && decoded.isNotEmpty && decoded[0] is List && decoded[0].isNotEmpty) {
          return decoded[0][0][0].toString();
        }
      }
    } catch (_) {}

    return '[mock-$targetCode] $text';
  }

  Future<String> chatWithGuide(String message, String context) async {
    for (int i = 0; i < 2; i++) {
      final uri = ApiConfig.getUri('/ai/chat');
      debugPrint('ApiService: POST $uri');
      try {
        final token = await getToken();
        debugPrint('ApiService: JWT Token is present: ${token != null}');
        final response = await http.post(
          uri,
          headers: {
            'Content-Type': 'application/json',
            if (token != null) 'Authorization': 'Bearer $token',
          },
          body: jsonEncode({
            'messages': [
              {'role': 'user', 'content': message}
            ],
            'system': context,
          }),
        ).timeout(const Duration(seconds: 20));

        debugPrint('ApiService: Response status: ${response.statusCode}');
        debugPrint('ApiService: Response body: ${response.body}');

        if (response.statusCode == 200) {
          final resData = jsonDecode(response.body);
          return resData['data']?['content'] ?? resData['reply'] ?? 'No reply.';
        }
      } catch (e) {
        debugPrint('ApiService: Exception in chatWithGuide: $e');
        if (i == 0) ApiConfig.useBackupUrl();
      }
    }

    // Direct local chatbot fallback to prevent broken UI
    final lastMsg = message.toLowerCase();
    String responseText = "I had trouble reaching the ExploreMate AI assistant, but here is some local travel advice! ";
    if (lastMsg.contains('audio') || lastMsg.contains('chat') || lastMsg.contains('guide')) {
      responseText += "To start an audio tour, tap 'Audio Tour Guide' from the side drawer or tap the 'Audio Tour' option on any destination card.";
    } else if (lastMsg.contains('schedule') || lastMsg.contains('plan') || lastMsg.contains('trip')) {
      responseText += "To create an automated itinerary, head to the 'Trip Scheduler' from the drawer, type your city, and tap 'Generate New Plan'.";
    } else if (lastMsg.contains('food') || lastMsg.contains('restaurant') || lastMsg.contains('eat')) {
      responseText += "To find places to eat, open the 'Food Explorer' page to select street food, cafes, or dining spots matching your mood.";
    } else {
      responseText += "Explore the live map on the 'Explore' tab or check out the 'City Game' page to earn XP by visiting hidden viewpoint gems.";
    }
    return responseText;
  }

  Future<List<dynamic>> generateItinerary(
      String destination, int days, int budget) async {
    for (int i = 0; i < 2; i++) {
      try {
        final response = await http.post(
          ApiConfig.getUri('/ai/schedule'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(
              {'destination': destination, 'days': days, 'budget': budget}),
        ).timeout(const Duration(seconds: 30));

        if (response.statusCode == 200) {
          final decoded = jsonDecode(response.body);
          if (decoded is Map) {
            return decoded['itinerary'] ?? decoded['data']?['itinerary'] ?? [];
          }
          return decoded;
        }
      } catch (_) {
        if (i == 0) ApiConfig.useBackupUrl();
      }
    }
    return [];
  }

  Future<String> getAudioNarration(String place, {String? question}) async {
    for (int i = 0; i < 2; i++) {
      try {
        final response = await http.post(
          ApiConfig.getUri('/ai/audio-narration'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'place': place, 'question': question}),
        ).timeout(const Duration(seconds: 20));

        if (response.statusCode == 200) {
          final decoded = jsonDecode(response.body);
          if (decoded is Map) {
            return decoded['narration'] ?? decoded['data']?['narration'] ?? '';
          }
          return decoded.toString();
        }
      } catch (_) {
        if (i == 0) ApiConfig.useBackupUrl();
      }
    }
    return '';
  }

  Future<String?> getTtsAudioUrl(String text) async {
    for (int i = 0; i < 2; i++) {
      try {
        final response = await http.get(
          ApiConfig.getUri('/free/tts?text=${Uri.encodeComponent(text)}'),
        ).timeout(const Duration(seconds: 10));

        if (response.statusCode == 200) {
          return jsonDecode(response.body)['audioUrl'];
        }
      } catch (_) {
        if (i == 0) ApiConfig.useBackupUrl();
      }
    }
    return null;
  }

  Future<List<dynamic>> getFoodPlaces(String query, String city) async {
    for (int i = 0; i < 2; i++) {
      try {
        final response = await http.get(
          ApiConfig.getUri('/free/places?query=$query&city=$city'),
        ).timeout(const Duration(seconds: 15));

        if (response.statusCode == 200) {
          return jsonDecode(response.body)['places'] ?? [];
        }
      } catch (_) {
        if (i == 0) ApiConfig.useBackupUrl();
      }
    }
    return [];
  }
}

