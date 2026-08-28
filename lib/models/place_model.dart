import 'package:flutter/material.dart';

/// A point-of-interest / place in the app.
class PlaceModel {
  final String placeId;
  final String name;
  final String type;        // e.g. "Hidden gem", "Cultural", "Scenic"
  final String tag;         // e.g. "Gem", "Popular", "Must-see"
  final double distKm;
  final double lat;
  final double lng;
  final bool isHiddenGem;
  final IconData icon;
  final String? description;
  final double rating;

  const PlaceModel({
    required this.placeId,
    required this.name,
    required this.type,
    required this.tag,
    required this.distKm,
    required this.lat,
    required this.lng,
    this.isHiddenGem = false,
    this.icon = Icons.place_rounded,
    this.description,
    this.rating = 4.5,
  });

  factory PlaceModel.fromMap(String id, Map<String, dynamic> map) {
    return PlaceModel(
      placeId: id,
      name: map['name'] as String? ?? '',
      type: map['type'] as String? ?? '',
      tag: map['tag'] as String? ?? '',
      distKm: (map['distKm'] as num?)?.toDouble() ?? 0.0,
      lat: (map['lat'] as num?)?.toDouble() ?? 0.0,
      lng: (map['lng'] as num?)?.toDouble() ?? 0.0,
      isHiddenGem: map['isHiddenGem'] as bool? ?? false,
      description: map['description'] as String?,
      rating: (map['rating'] as num?)?.toDouble() ?? 4.5,
    );
  }

  /// Map a raw Node.js/PostgreSQL (Prisma) response to a [PlaceModel].
  factory PlaceModel.fromBackend(Map<String, dynamic> map) {
    return PlaceModel(
      placeId: map['id']?.toString() ?? '',
      name: map['name'] as String? ?? '',
      type: map['category'] as String? ?? map['type'] as String? ?? 'Place',
      tag: map['tag'] as String? ??
          (map['isHiddenGem'] == true ? 'Gem' : 'Popular'),
      distKm: (map['distKm'] as num?)?.toDouble() ?? 0.0,
      lat: (map['lat'] as num?)?.toDouble() ?? 0.0,
      lng: (map['lng'] as num?)?.toDouble() ?? 0.0,
      isHiddenGem: map['isHiddenGem'] as bool? ?? false,
      description: map['description'] as String?,
      rating: (map['rating'] as num?)?.toDouble() ?? 4.5,
    );
  }

  Map<String, dynamic> toMap() => {
        'name': name,
        'type': type,
        'tag': tag,
        'distKm': distKm,
        'lat': lat,
        'lng': lng,
        'isHiddenGem': isHiddenGem,
        'description': description,
        'rating': rating,
      };

  @override
  String toString() => 'PlaceModel($placeId, $name)';
}
