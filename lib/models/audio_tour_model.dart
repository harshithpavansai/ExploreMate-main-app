/// Metadata for an AI-generated audio tour linked to a place.
class AudioTourModel {
  final String tourId;
  final String placeId;
  final String placeName;
  final String language;
  final int durationSec;
  final String audioUrl;       // Firebase Storage URL (or local asset path)
  final double rating;
  final int playCount;

  const AudioTourModel({
    required this.tourId,
    required this.placeId,
    required this.placeName,
    required this.language,
    required this.durationSec,
    required this.audioUrl,
    this.rating = 4.5,
    this.playCount = 0,
  });

  /// Duration formatted as "12 min".
  String get durationLabel {
    final m = durationSec ~/ 60;
    return '$m min';
  }

  factory AudioTourModel.fromMap(String id, Map<String, dynamic> map) {
    return AudioTourModel(
      tourId: id,
      placeId: map['placeId'] as String? ?? '',
      placeName: map['placeName'] as String? ?? '',
      language: map['language'] as String? ?? 'English',
      durationSec: (map['durationSec'] as num?)?.toInt() ?? 0,
      audioUrl: map['audioUrl'] as String? ?? '',
      rating: (map['rating'] as num?)?.toDouble() ?? 4.5,
      playCount: (map['playCount'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toMap() => {
        'placeId': placeId,
        'placeName': placeName,
        'language': language,
        'durationSec': durationSec,
        'audioUrl': audioUrl,
        'rating': rating,
        'playCount': playCount,
      };

  @override
  String toString() => 'AudioTourModel($tourId, $placeName, $language)';
}
