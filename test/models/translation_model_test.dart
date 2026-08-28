import 'package:flutter_test/flutter_test.dart';
import 'package:exploremate/models/translation_model.dart';

void main() {
  group('TranslationModel', () {
    // ── fromMap ──────────────────────────────────────────────────────────────
    group('fromMap', () {
      test('parses all fields correctly', () {
        final map = {
          'userId': 'uid-001',
          'sourceText': 'Hello',
          'translatedText': 'నమస్కారం',
          'fromLang': 'English',
          'toLang': 'Telugu',
          'savedAt': '2026-05-01T10:00:00.000',
        };

        final t = TranslationModel.fromMap('tr001', map);

        expect(t.id, 'tr001');
        expect(t.userId, 'uid-001');
        expect(t.sourceText, 'Hello');
        expect(t.translatedText, 'నమస్కారం');
        expect(t.fromLang, 'English');
        expect(t.toLang, 'Telugu');
        expect(t.savedAt, DateTime(2026, 5, 1, 10));
      });

      test('applies defaults for missing fields', () {
        final t = TranslationModel.fromMap('tr-empty', {});
        expect(t.userId, '');
        expect(t.sourceText, '');
        expect(t.translatedText, '');
        expect(t.fromLang, 'English');
        expect(t.toLang, 'Hindi');
      });

      test('handles invalid savedAt with DateTime.now()', () {
        final before = DateTime.now().subtract(const Duration(seconds: 1));
        final map = {
          'userId': 'uid',
          'sourceText': 'Hi',
          'translatedText': 'नमस्ते',
          'fromLang': 'English',
          'toLang': 'Hindi',
          'savedAt': 'not-a-date',
        };
        final t = TranslationModel.fromMap('tr-bad', map);
        expect(t.savedAt.isAfter(before), isTrue);
      });
    });

    // ── toMap ────────────────────────────────────────────────────────────────
    group('toMap', () {
      test('serializes all fields', () {
        final t = TranslationModel(
          id: 'tr001',
          userId: 'uid-001',
          sourceText: 'Thank you',
          translatedText: 'ధన్యవాదాలు',
          fromLang: 'English',
          toLang: 'Telugu',
          savedAt: DateTime(2026, 5, 1),
        );

        final map = t.toMap();

        expect(map['userId'], 'uid-001');
        expect(map['sourceText'], 'Thank you');
        expect(map['translatedText'], 'ధన్యవాదాలు');
        expect(map['fromLang'], 'English');
        expect(map['toLang'], 'Telugu');
        expect(map['savedAt'], '2026-05-01T00:00:00.000');
      });
    });

    // ── round-trip ────────────────────────────────────────────────────────────
    test('fromMap → toMap round-trip preserves values', () {
      final original = {
        'userId': 'uid-xyz',
        'sourceText': 'Where is the station?',
        'translatedText': 'స్టేషన్ ఎక్కడ ఉంది?',
        'fromLang': 'English',
        'toLang': 'Telugu',
        'savedAt': '2026-04-15T08:30:00.000',
      };

      final t = TranslationModel.fromMap('tr-xyz', original);
      final restored = t.toMap();

      expect(restored['sourceText'], original['sourceText']);
      expect(restored['translatedText'], original['translatedText']);
      expect(restored['toLang'], original['toLang']);
      expect(restored['savedAt'], original['savedAt']);
    });

    // ── toString ─────────────────────────────────────────────────────────────
    test('toString includes language pair and source text', () {
      final t = TranslationModel(
        id: 'tr001',
        userId: 'uid',
        sourceText: 'Hello',
        translatedText: 'నమస్కారం',
        fromLang: 'English',
        toLang: 'Telugu',
        savedAt: DateTime.now(),
      );
      final str = t.toString();
      expect(str, contains('English'));
      expect(str, contains('Telugu'));
      expect(str, contains('Hello'));
    });
  });
}
