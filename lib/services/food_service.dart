import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/food_model.dart';
import '../config/api_config.dart';


/// Food / restaurant discovery service.
///
/// Calls the backend `/api/free/places` endpoint which proxies
/// OpenStreetMap Nominatim — no API key required.
/// Falls back to a curated local seed if the network is unavailable.
class FoodService {
  FoodService._();
  static final FoodService instance = FoodService._();

  // ── Public API ─────────────────────────────────────────────────────────────


  /// Search for food places matching [query] in [city].
  /// Tries local backend → Render → offline seed fallback.
  Future<List<FoodItemModel>> searchFoodPlaces({
    String query = 'restaurant',
    String city = 'Visakhapatnam',
  }) async {
    for (int i = 0; i < 2; i++) {
      try {
        final response = await http
            .get(ApiConfig.getUri('/free/places?query=$query&city=$city'))
            .timeout(const Duration(seconds: 10));

        if (response.statusCode == 200) {
          final List<dynamic> data =
              (jsonDecode(response.body)['places'] as List?) ?? [];
          if (data.isNotEmpty) {
            return data
                .asMap()
                .entries
                .map((e) => FoodItemModel.fromNominatim(
                      'osm_${e.key}',
                      e.value as Map<String, dynamic>,
                    ))
                .toList();
          }
        }
      } catch (e) {
        debugPrint('FoodService failed — $e');
        if (i == 0) ApiConfig.useBackupUrl();
      }
    }

    // Offline seed fallback
    return _filterSeed(query: query);
  }

  /// Fetch all food items (uses seed categories for offline mode).
  Future<List<FoodItemModel>> getFoodItems({String? category}) async {
    // Try live search first
    final query = category?.isNotEmpty == true ? category! : 'food';
    final live = await searchFoodPlaces(query: query);
    if (live.isNotEmpty) return live;

    // Seed fallback with optional category filter
    return _filterSeed(category: category);
  }

  /// Get only vegetarian items from the seed list.
  Future<List<FoodItemModel>> getVegItems() async {
    return _seedItems.where((f) => f.isVeg).toList();
  }

  /// Text search over name / cuisine / category in the seed list.
  Future<List<FoodItemModel>> searchFood(String query) async {
    final live = await searchFoodPlaces(query: query);
    if (live.isNotEmpty) return live;
    return _filterSeed(query: query);
  }

  // ── Private helpers ────────────────────────────────────────────────────────

  List<FoodItemModel> _filterSeed({String? query, String? category}) {
    final q = (query ?? '').toLowerCase();
    final c = (category ?? '').toLowerCase();
    return _seedItems.where((f) {
      final matchQuery = q.isEmpty ||
          f.name.toLowerCase().contains(q) ||
          f.cuisine.toLowerCase().contains(q) ||
          f.category.toLowerCase().contains(q);
      final matchCat =
          c.isEmpty || f.category.toLowerCase() == c;
      return matchQuery && matchCat;
    }).toList();
  }

  // ── Curated offline seed ───────────────────────────────────────────────────
  static const List<FoodItemModel> _seedItems = [
    FoodItemModel(
      foodId: 'f001',
      name: 'Pesarattu',
      category: 'Street Food',
      cuisine: 'South Indian',
      rating: 4.7,
      priceRange: '₹',
      placeId: 'p009',
      description: 'Crispy green moong dal crepes served with ginger chutney.',
      isVeg: true,
    ),
    FoodItemModel(
      foodId: 'f002',
      name: 'Bamboo Chicken',
      category: 'Restaurant',
      cuisine: 'Tribal / Araku',
      rating: 4.8,
      priceRange: '₹₹',
      placeId: 'p010',
      description:
          'Chicken marinated in spices and cooked inside bamboo over fire.',
      isVeg: false,
    ),
    FoodItemModel(
      foodId: 'f003',
      name: 'Bobbatlu',
      category: 'Sweet',
      cuisine: 'Andhra',
      rating: 4.5,
      priceRange: '₹',
      placeId: 'p002',
      description: 'Sweet flatbread stuffed with lentils and jaggery.',
      isVeg: true,
    ),
    FoodItemModel(
      foodId: 'f004',
      name: 'Prawn Fry',
      category: 'Seafood',
      cuisine: 'Coastal Andhra',
      rating: 4.9,
      priceRange: '₹₹₹',
      placeId: 'p003',
      description: 'Fresh tiger prawns tossed in coastal spice blend.',
      isVeg: false,
    ),
    FoodItemModel(
      foodId: 'f005',
      name: 'Araku Coffee',
      category: 'Cafe',
      cuisine: 'Beverages',
      rating: 4.6,
      priceRange: '₹₹',
      placeId: 'p010',
      description: 'Premium single-origin tribal coffee from Araku valley.',
      isVeg: true,
    ),
    FoodItemModel(
      foodId: 'f006',
      name: 'Gongura Mutton',
      category: 'Restaurant',
      cuisine: 'Andhra',
      rating: 4.8,
      priceRange: '₹₹',
      placeId: 'p002',
      description:
          "Andhra's signature dish — mutton slow-cooked with sorrel leaves.",
      isVeg: false,
    ),
  ];
}
