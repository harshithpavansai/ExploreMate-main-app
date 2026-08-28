# Connecting the ExploreMate Flutter App to the Backend

A step-by-step guide to wire your existing Flutter screens (`login_screen.dart`, `home_screen.dart`, `audio_tour_screen.dart`, etc.) to this Node.js + Express + PostgreSQL backend.

---

## 1. Start the backend

```bash
cd exploremate-backend
npm install
cp .env.example .env       # edit DATABASE_URL + secrets
npm run db:init            # apply schema.sql
npm run db:seed            # adds 5 sample destinations + admin user
npm run dev                # http://localhost:5000/api/v1
```

Quick sanity check:
```bash
curl http://localhost:5000/api/v1/health
# -> { "success": true, "message": "OK", "data": { "status": "healthy", ... } }
```

---

## 2. Pick the right base URL for your Flutter platform

| Where Flutter runs | Use this URL |
|---|---|
| Android emulator | `http://10.0.2.2:5000/api/v1` |
| iOS simulator | `http://localhost:5000/api/v1` |
| Real device on same Wi-Fi | `http://<your-PC-LAN-IP>:5000/api/v1` |
| Production / hosted | `https://your-domain.com/api/v1` |

For Android, also allow cleartext HTTP in `android/app/src/main/AndroidManifest.xml` while developing:
```xml
<application
    android:usesCleartextTraffic="true"
    ...>
```

---

## 3. Add the Flutter dependencies

In `pubspec.yaml`:
```yaml
dependencies:
  flutter:
    sdk: flutter
  http: ^1.2.0
  flutter_secure_storage: ^9.2.2
  shared_preferences: ^2.3.2
```

---

## 4. Drop in an API client

Create `lib/api/api_client.dart`:

```dart
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

class ApiException implements Exception {
  final int status;
  final String message;
  ApiException(this.status, this.message);
  @override
  String toString() => 'ApiException($status): $message';
}

class ApiClient {
  static const String baseUrl = 'http://10.0.2.2:5000/api/v1'; // Android emulator
  static const _storage = FlutterSecureStorage();

  static Future<String?> _accessToken() => _storage.read(key: 'access');
  static Future<String?> _refreshToken() => _storage.read(key: 'refresh');

  static Future<void> saveTokens(String access, String refresh) async {
    await _storage.write(key: 'access',  value: access);
    await _storage.write(key: 'refresh', value: refresh);
  }

  static Future<void> clearTokens() async {
    await _storage.delete(key: 'access');
    await _storage.delete(key: 'refresh');
  }

  static Future<Map<String, String>> _headers({bool auth = true}) async {
    final h = <String, String>{'Content-Type': 'application/json'};
    if (auth) {
      final t = await _accessToken();
      if (t != null) h['Authorization'] = 'Bearer $t';
    }
    return h;
  }

  static Future<dynamic> get(String path, {Map<String, dynamic>? query, bool auth = true}) async {
    final uri = Uri.parse('$baseUrl$path').replace(
      queryParameters: query?.map((k, v) => MapEntry(k, '$v')),
    );
    final res = await http.get(uri, headers: await _headers(auth: auth));
    return _decode(res);
  }

  static Future<dynamic> post(String path, {Map<String, dynamic>? body, bool auth = true}) async {
    final res = await http.post(
      Uri.parse('$baseUrl$path'),
      headers: await _headers(auth: auth),
      body: jsonEncode(body ?? {}),
    );
    return _decode(res);
  }

  static Future<dynamic> put(String path, {Map<String, dynamic>? body}) async {
    final res = await http.put(
      Uri.parse('$baseUrl$path'),
      headers: await _headers(),
      body: jsonEncode(body ?? {}),
    );
    return _decode(res);
  }

  static Future<dynamic> patch(String path, {Map<String, dynamic>? body}) async {
    final res = await http.patch(
      Uri.parse('$baseUrl$path'),
      headers: await _headers(),
      body: jsonEncode(body ?? {}),
    );
    return _decode(res);
  }

  static Future<dynamic> delete(String path) async {
    final res = await http.delete(Uri.parse('$baseUrl$path'), headers: await _headers());
    return _decode(res);
  }

  static dynamic _decode(http.Response res) {
    final body = res.body.isEmpty ? {} : jsonDecode(res.body);
    if (res.statusCode >= 200 && res.statusCode < 300 && body['success'] == true) {
      return body['data'];
    }
    throw ApiException(res.statusCode, body['message']?.toString() ?? 'Request failed');
  }

  /// If a 401 happens, call this to swap the access token before retrying.
  static Future<bool> tryRefresh() async {
    final r = await _refreshToken();
    if (r == null) return false;
    final res = await http.post(
      Uri.parse('$baseUrl/auth/refresh'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'refreshToken': r}),
    );
    if (res.statusCode != 200) return false;
    final tokens = jsonDecode(res.body)['data']['tokens'];
    await saveTokens(tokens['accessToken'], tokens['refreshToken']);
    return true;
  }
}
```

---

## 5. One repository class per feature

Drop `lib/api/auth_repo.dart`:

```dart
import 'api_client.dart';

class AuthRepo {
  static Future<Map<String, dynamic>> register({
    required String name, required String email, required String password, String? phone,
  }) async {
    final data = await ApiClient.post('/auth/register',
      auth: false,
      body: {'name': name, 'email': email, 'password': password, if (phone != null) 'phone': phone},
    );
    final tokens = data['tokens'];
    await ApiClient.saveTokens(tokens['accessToken'], tokens['refreshToken']);
    return Map<String, dynamic>.from(data['user']);
  }

  static Future<Map<String, dynamic>> login(String email, String password) async {
    final data = await ApiClient.post('/auth/login',
      auth: false, body: {'email': email, 'password': password});
    final tokens = data['tokens'];
    await ApiClient.saveTokens(tokens['accessToken'], tokens['refreshToken']);
    return Map<String, dynamic>.from(data['user']);
  }

  static Future<void> verifyOtp(String email, String code) =>
      ApiClient.post('/auth/verify-otp', auth: false, body: {'email': email, 'code': code});

  static Future<void> resendOtp(String email) =>
      ApiClient.post('/auth/resend-otp', auth: false, body: {'email': email});

  static Future<void> forgotPassword(String email) =>
      ApiClient.post('/auth/forgot-password', auth: false, body: {'email': email});

  static Future<Map<String, dynamic>> me() async =>
      Map<String, dynamic>.from(await ApiClient.get('/auth/me'));

  static Future<void> logout() async {
    try { await ApiClient.post('/auth/logout'); } catch (_) {}
    await ApiClient.clearTokens();
  }
}
```

`lib/api/destinations_repo.dart`:

```dart
import 'api_client.dart';

class DestinationsRepo {
  static Future<List<dynamic>> search({String? q, String? category, int limit = 30}) async {
    final data = await ApiClient.get('/destinations',
      auth: false, query: {'q': q, 'category': category, 'limit': limit}..removeWhere((k,v)=>v==null));
    return data['items'] as List;
  }

  static Future<List<dynamic>> trending() async =>
      List.from(await ApiClient.get('/destinations/trending', auth: false));

  static Future<List<dynamic>> nearby(double lat, double lng, {double radius = 25}) async {
    final data = await ApiClient.get('/destinations/nearby',
      auth: false, query: {'lat': lat, 'lng': lng, 'radius': radius});
    return data['items'] as List;
  }

  static Future<Map<String, dynamic>> detail(String id) async =>
      Map<String, dynamic>.from(await ApiClient.get('/destinations/$id', auth: false));

  static Future<List<dynamic>> hiddenGems({String? city}) async =>
      List.from(await ApiClient.get('/hidden-gems',
          auth: false, query: city != null ? {'city': city} : null));
}
```

`lib/api/trip_repo.dart`:

```dart
import 'api_client.dart';

class TripRepo {
  static Future<List<dynamic>> list() async => List.from(await ApiClient.get('/trips'));

  static Future<Map<String, dynamic>> create({
    required String title, String? destination, String? startDate, String? endDate,
    int travelers = 1, num? budget,
  }) async => Map<String, dynamic>.from(await ApiClient.post('/trips', body: {
    'title': title, 'destination': destination,
    'start_date': startDate, 'end_date': endDate,
    'travelers': travelers, 'budget': budget,
  }));

  static Future<List<dynamic>> generateItinerary(String tripId, {List<String> interests = const []}) async =>
      List.from(await ApiClient.post('/trips/$tripId/generate-itinerary', body: {'interests': interests}));

  /// Returns the URL the WebView/PDF viewer can stream from (with the JWT in the query)
  static Future<String> exportPdfUrl(String tripId) async {
    final t = await const FlutterSecureStorage().read(key: 'access');
    return '${ApiClient.baseUrl}/trips/$tripId/export-pdf?token=$t';
  }
}
```

`lib/api/ai_repo.dart`:

```dart
import 'api_client.dart';

class AiRepo {
  static Future<Map<String, dynamic>> chat(List<Map<String, String>> messages) async =>
      Map<String, dynamic>.from(await ApiClient.post('/ai/chat', body: {'messages': messages}));

  static Future<Map<String, dynamic>> generateAudioTour({
    String? destinationId, String? destinationName, String? city, String? country,
    int durationMinutes = 5, String language = 'en',
  }) async => Map<String, dynamic>.from(await ApiClient.post('/audio-tour', body: {
    'destination_id': destinationId, 'destinationName': destinationName,
    'city': city, 'country': country,
    'durationMinutes': durationMinutes, 'language': language,
  }));

  static Future<Map<String, dynamic>> translate(String text, {String target = 'en'}) async =>
      Map<String, dynamic>.from(await ApiClient.post('/translator', body: {'text': text, 'target': target}));

  static Future<Map<String, dynamic>> weather({String? city, double? lat, double? lng}) async =>
      Map<String, dynamic>.from(await ApiClient.get('/weather',
          query: {if (city != null) 'city': city, if (lat != null) 'lat': lat, if (lng != null) 'lng': lng}));

  static Future<Map<String, dynamic>> foodRecommend({String? city, double? lat, double? lng}) async =>
      Map<String, dynamic>.from(await ApiClient.post('/food/recommend', body: {
        if (city != null) 'city': city, if (lat != null) 'lat': lat, if (lng != null) 'lng': lng,
      }));
}
```

---

## 6. Wire it into your existing screens

### `login_screen.dart`

Replace `primaryTap: _goHome,` for the **SIGN IN** mode with a real call:

```dart
final emailCtrl = TextEditingController();
final passCtrl  = TextEditingController();

Future<void> _signIn() async {
  try {
    await AuthRepo.login(emailCtrl.text.trim(), passCtrl.text);
    if (mounted) Navigator.pushReplacementNamed(context, '/home');
  } on ApiException catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
  }
}
```

For **CREATE ACCOUNT**:
```dart
Future<void> _signUp() async {
  await AuthRepo.register(
    name: nameCtrl.text, email: emailCtrl.text, password: passCtrl.text,
  );
  setState(() => mode = AuthMode.otp);
}
```

For **VERIFY OTP**:
```dart
Future<void> _verifyOtp() async {
  await AuthRepo.verifyOtp(emailCtrl.text, otpCtrl.text);
  if (mounted) Navigator.pushReplacementNamed(context, '/home');
}
```

> In dev, the backend logs the OTP code to the console *and* returns it as `devOtp` in the response — so you don't need to wire up real email/SMS until production.

### `home_screen.dart` & `explore_screen.dart`

Pull trending, hidden gems, and weather on init:

```dart
late Future<List> _trending;
late Future<List> _hiddenGems;
late Future<Map> _weather;

@override
void initState() {
  super.initState();
  _trending   = DestinationsRepo.trending();
  _hiddenGems = DestinationsRepo.hiddenGems();
  _weather    = AiRepo.weather(city: 'Paris'); // or detect via geolocator + reverse-geocode
}

// in build():
FutureBuilder<List>(
  future: _trending,
  builder: (ctx, s) => s.hasData
    ? ListView(children: s.data!.map((d) => DestCard(d)).toList())
    : const CircularProgressIndicator(),
);
```

### `destination_detail_screen.dart`

```dart
final detail = await DestinationsRepo.detail(destinationId);
// detail['name'], detail['description'], detail['reviews'] (already joined)
```

Toggle favorite:
```dart
await ApiClient.post('/favorites', body: {'destination_id': destinationId});
```

### `trip_scheduler_screen.dart`

```dart
final trip = await TripRepo.create(
  title: titleCtrl.text,
  destination: destCtrl.text,
  startDate: '2026-06-10',
  endDate:   '2026-06-15',
  travelers: 2,
);

// Ask the AI for a day-by-day itinerary
final itinerary = await TripRepo.generateItinerary(trip['id'], interests: ['food', 'history']);

// Export as PDF (open in browser/WebView):
final url = await TripRepo.exportPdfUrl(trip['id']);
launchUrl(Uri.parse(url));
```

### `audio_tour_screen.dart`

```dart
final result = await AiRepo.generateAudioTour(
  destinationName: 'Eiffel Tower',
  city: 'Paris', country: 'France',
  durationMinutes: 5, language: 'en',
);

final transcript = result['tour']['transcript'];
final audioUrl   = result['audio']['dataUrl']; // base64 data URL — feed into just_audio
```

Use `just_audio` (Flutter package) to play the data URL directly.

### `ai_assist_screen.dart`

```dart
final reply = await AiRepo.chat([
  {'role': 'user', 'content': userMessage},
]);
print(reply['content']); // assistant reply text
```

### `translator_screen.dart`

```dart
final out = await AiRepo.translate(text, target: 'fr');
out['translated']; // translated string
```

For voice playback, hit `POST /translator/speak` and play `audioDataUrl` with `just_audio`.

### `food_screen.dart`

```dart
final out = await AiRepo.foodRecommend(city: 'Paris');
// out['weather'], out['hint'] ("hot soups, ramen, stews"), out['nearby'], out['ai']
```

### `hidden_gems_screen.dart`

```dart
final gems = await DestinationsRepo.hiddenGems();
```

### `game_screen.dart`

```dart
final me = await ApiClient.get('/game/me');
// me['xp'], me['level'], me['xp_to_next'], me['badges'], me['recent_xp']

final lb = await ApiClient.get('/game/leaderboard');

// award XP after an action
await ApiClient.post('/game/award', body: {'action': 'visited_place', 'points': 10});
```

### `profile_screen.dart`

```dart
// load profile
final me = await AuthRepo.me();

// update
await ApiClient.put('/users/me', body: {'name': nameCtrl.text, 'bio': bioCtrl.text});

// preferences (JSON merge)
await ApiClient.patch('/users/me/preferences', body: {'language': 'en', 'darkMode': true});

// logout
await AuthRepo.logout();
```

---

## 7. Auto-redirect on app start

In `splash_screen.dart`, decide where to send the user:

```dart
@override
void initState() {
  super.initState();
  _bootstrap();
}

Future<void> _bootstrap() async {
  await Future.delayed(const Duration(seconds: 1));
  try {
    await AuthRepo.me();           // valid token → straight to home
    if (mounted) Navigator.pushReplacementNamed(context, '/home');
  } catch (_) {
    if (mounted) Navigator.pushReplacementNamed(context, '/login');
  }
}
```

---

## 8. Handle expired tokens (one place)

Wrap your calls in a small helper that retries once after refreshing:

```dart
Future<T> withAutoRefresh<T>(Future<T> Function() call) async {
  try {
    return await call();
  } on ApiException catch (e) {
    if (e.status == 401 && await ApiClient.tryRefresh()) {
      return call();
    }
    rethrow;
  }
}
```

Use it for any sensitive call: `await withAutoRefresh(() => TripRepo.list());`

---

## 9. Optional: production hardening checklist

1. Set strong `JWT_SECRET` and `JWT_REFRESH_SECRET` in the backend `.env`.
2. Set real keys for `OPENAI_API_KEY`, `GOOGLE_MAPS_API_KEY`, `OPENWEATHER_API_KEY`, `GOOGLE_TRANSLATE_API_KEY`, `GOOGLE_TTS_API_KEY` to switch off mock fallbacks.
3. Provide Firebase Admin credentials so the `/auth/firebase` endpoint can validate phone-OTP ID tokens issued by your Flutter app.
4. Host PostgreSQL (Supabase / Railway / RDS) and set `DATABASE_URL` + `PG_SSL=true`.
5. Deploy the backend with `npm start` behind HTTPS (Nginx/Caddy/Cloud LB).
6. Update `ApiClient.baseUrl` in Flutter to the production HTTPS URL.

---

## 10. Quick smoke test from the Flutter device

Add a "Backend Ping" button anywhere temporarily:

```dart
ElevatedButton(
  onPressed: () async {
    try {
      final r = await ApiClient.get('/health', auth: false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Backend: ${r['status']}')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Backend unreachable: $e')),
      );
    }
  },
  child: const Text('Test Backend'),
)
```

If you see "Backend: healthy" — you're live. From there, every screen's repository calls listed above will work.
