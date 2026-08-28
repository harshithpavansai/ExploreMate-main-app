import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../models/place_model.dart';

import '../config/api_config.dart';

/// Places / POI service.
///
/// Priority chain:
///   1. Node.js/PostgreSQL backend (`GET /api/destinations`)
///   2. Firestore `places` collection (populated by admin tool)
///   3. Local seed data (offline safety net)
class PlaceService {
  PlaceService._();
  static final PlaceService instance = PlaceService._();

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ── Public API ─────────────────────────────────────────────────────────────

  /// Fetch all places, optionally filtered to hidden gems only.
  Future<List<PlaceModel>> getPlaces({bool gemsOnly = false}) async {
    // 1️⃣  Try local backend first, then Render
    for (int i = 0; i < 2; i++) {
      try {
        final response = await http
            .get(ApiConfig.getUri('/destinations'))
            .timeout(const Duration(seconds: 8));

        if (response.statusCode == 200) {
          final List<dynamic> data = jsonDecode(response.body);
          final places = data
              .map((d) => PlaceModel.fromBackend(d as Map<String, dynamic>))
              .toList();
          return gemsOnly ? places.where((p) => p.isHiddenGem).toList() : places;
        }
      } catch (e) {
        debugPrint('PlaceService failed → $e');
        if (i == 0) ApiConfig.useBackupUrl();
      }
    }

    // 2️⃣  Firestore fallback
    return _getFromFirestore(gemsOnly: gemsOnly);
  }

  /// Simple text search against name, type, and tag.
  Future<List<PlaceModel>> searchPlaces(String query) async {
    final all = await getPlaces();
    final q = query.toLowerCase();
    return all
        .where((p) =>
            p.name.toLowerCase().contains(q) ||
            p.type.toLowerCase().contains(q) ||
            p.tag.toLowerCase().contains(q))
        .toList();
  }

  /// Fetch a single place by ID.
  Future<PlaceModel?> getPlaceById(String id) async {
    // Try local backend then Render
    for (int i = 0; i < 2; i++) {
      try {
        final response = await http
            .get(ApiConfig.getUri('/destinations/$id'))
            .timeout(const Duration(seconds: 6));
        if (response.statusCode == 200) {
          return PlaceModel.fromBackend(
              jsonDecode(response.body) as Map<String, dynamic>);
        }
      } catch (_) {
        if (i == 0) ApiConfig.useBackupUrl();
      }
    }

    // Firestore fallback
    try {
      final doc = await _db.collection('places').doc(id).get();
      if (doc.exists && doc.data() != null) {
        return PlaceModel.fromMap(doc.id, doc.data()!);
      }
    } catch (_) {}

    // Local seed fallback
    try {
      return _seedData.firstWhere((p) => p.placeId == id);
    } catch (_) {
      return null;
    }
  }

  /// Mark a place as visited and award XP via Firestore.
  Future<void> markVisited(String placeId, String userId) async {
    try {
      await _db
          .collection('userProgress')
          .doc('${userId}_$placeId')
          .set({
        'userId': userId,
        'placeId': placeId,
        'visitedAt': DateTime.now().toIso8601String(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('PlaceService.markVisited error: $e');
    }
  }

  Future<void> addPlace(PlaceModel place) async {
    try {
      await _db.collection('places').add(place.toMap());
    } catch (e) {
      debugPrint('PlaceService.addPlace error: $e');
      rethrow;
    }
  }

  Future<void> deletePlace(String id) async {
    try {
      await _db.collection('places').doc(id).delete();
    } catch (e) {
      debugPrint('PlaceService.deletePlace error: $e');
      rethrow;
    }
  }

  // ── Private helpers ────────────────────────────────────────────────────────

  Future<List<PlaceModel>> _getFromFirestore({bool gemsOnly = false}) async {
    try {
      Query q = _db.collection('places');
      if (gemsOnly) q = q.where('isHiddenGem', isEqualTo: true);
      final snap = await q.get();
      if (snap.docs.isNotEmpty) {
        return snap.docs
            .map((d) => PlaceModel.fromMap(d.id, d.data() as Map<String, dynamic>))
            .toList();
      }
    } catch (e) {
      debugPrint('PlaceService: Firestore failed → using seed data: $e');
    }
    return gemsOnly
        ? _seedData.where((p) => p.isHiddenGem).toList()
        : List.of(_seedData);
  }

  // ── Offline seed data (safety net) ────────────────────────────────────────
  static final List<PlaceModel> _seedData = [
    const PlaceModel(
      placeId: 'p001',
      name: 'Lotus Lake Viewpoint',
      type: 'Hidden gem',
      tag: 'Gem',
      distKm: 2.3,
      lat: 17.6900,
      lng: 83.2100,
      isHiddenGem: true,
      icon: Icons.water_rounded,
      description:
          'A serene lotus lake surrounded by hills. Best visited at sunrise.',
      rating: 4.8,
    ),
    const PlaceModel(
      placeId: 'p002',
      name: 'Old Quarter Market',
      type: 'Cultural',
      tag: 'Popular',
      distKm: 3.7,
      lat: 17.7150,
      lng: 83.2950,
      isHiddenGem: false,
      icon: Icons.store_rounded,
      description: 'Vibrant street market with handmade crafts and local food.',
      rating: 4.3,
    ),
    const PlaceModel(
      placeId: 'p003',
      name: 'Sunset Cliffside',
      type: 'Scenic',
      tag: 'Must-see',
      distKm: 6.1,
      lat: 17.6750,
      lng: 83.3200,
      isHiddenGem: false,
      icon: Icons.landscape_rounded,
      description: 'Dramatic cliff overlooking the Bay of Bengal.',
      rating: 4.9,
    ),
    const PlaceModel(
      placeId: 'p004',
      name: 'Borra Caves',
      type: 'Nature',
      tag: 'Gem',
      distKm: 92.0,
      lat: 18.0756,
      lng: 83.1403,
      isHiddenGem: true,
      icon: Icons.terrain_rounded,
      description: 'Ancient limestone caves with million-year-old formations.',
      rating: 4.7,
    ),
    const PlaceModel(
      placeId: 'p005',
      name: 'Yarada Beach',
      type: 'Beach',
      tag: 'Gem',
      distKm: 15.0,
      lat: 17.6100,
      lng: 83.2300,
      isHiddenGem: true,
      icon: Icons.beach_access_rounded,
      description: 'Secluded beach nestled between hills — rarely crowded.',
      rating: 4.6,
    ),
    const PlaceModel(
      placeId: 'p006',
      name: 'Submarine Museum',
      type: 'Museum',
      tag: 'Must-see',
      distKm: 4.5,
      lat: 17.7100,
      lng: 83.3100,
      isHiddenGem: false,
      icon: Icons.water_rounded,
      description: 'A decommissioned INS Kursura submarine now a museum.',
      rating: 4.4,
    ),
  ];
}
