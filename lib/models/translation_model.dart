/// A saved translation from the Translator screen.
class TranslationModel {
  final String id;
  final String userId;
  final String sourceText;
  final String translatedText;
  final String fromLang;
  final String toLang;
  final DateTime savedAt;

  const TranslationModel({
    required this.id,
    required this.userId,
    required this.sourceText,
    required this.translatedText,
    required this.fromLang,
    required this.toLang,
    required this.savedAt,
  });

  factory TranslationModel.fromMap(String id, Map<String, dynamic> map) {
    return TranslationModel(
      id: id,
      userId: map['userId'] as String? ?? '',
      sourceText: map['sourceText'] as String? ?? '',
      translatedText: map['translatedText'] as String? ?? '',
      fromLang: map['fromLang'] as String? ?? 'English',
      toLang: map['toLang'] as String? ?? 'Hindi',
      savedAt: DateTime.tryParse(map['savedAt'] as String? ?? '') ??
          DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
        'userId': userId,
        'sourceText': sourceText,
        'translatedText': translatedText,
        'fromLang': fromLang,
        'toLang': toLang,
        'savedAt': savedAt.toIso8601String(),
      };

  @override
  String toString() =>
      'TranslationModel($fromLang→$toLang: "$sourceText")';
}
