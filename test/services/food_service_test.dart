import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:exploremate/models/food_model.dart';
import 'package:exploremate/services/food_service.dart';

class OfflineHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    throw const SocketException('Simulated offline mode for tests');
  }
}

/// Tests for the pure filtering & search logic in [FoodService].
/// These test the local seed / offline fallback behaviour without
/// making any real network calls.
void main() {
  setUpAll(() {
    HttpOverrides.global = OfflineHttpOverrides();
  });

  group('FoodService — offline seed & filter logic', () {
    // We test the *behaviour* of the service's filtering via the
    // searchFood() method which hits the seed when the network is absent.
    // Since tests run with no network, the service always falls back to seed.

    // ── getVegItems ───────────────────────────────────────────────────────────
    group('getVegItems()', () {
      test('returns only vegetarian items', () async {
        final items = await FoodService.instance.getVegItems();
        expect(items, isNotEmpty);
        for (final item in items) {
          expect(item.isVeg, isTrue,
              reason: '${item.name} should be vegetarian');
        }
      });

      test('does not include non-veg items', () async {
        final items = await FoodService.instance.getVegItems();
        final hasNonVeg = items.any((f) => !f.isVeg);
        expect(hasNonVeg, isFalse);
      });
    });

    // ── searchFood ────────────────────────────────────────────────────────────
    group('searchFood()', () {
      test('finds items by name (case insensitive)', () async {
        final results = await FoodService.instance.searchFood('pesarattu');
        expect(results.any((f) => f.name.toLowerCase().contains('pesarattu')),
            isTrue);
      });

      test('finds items by cuisine', () async {
        final results = await FoodService.instance.searchFood('andhra');
        expect(
          results.any((f) => f.cuisine.toLowerCase().contains('andhra')),
          isTrue,
        );
      });

      test('finds items by category', () async {
        final results = await FoodService.instance.searchFood('seafood');
        expect(
          results.any((f) => f.category.toLowerCase().contains('seafood')),
          isTrue,
        );
      });

      test('returns empty list for unknown query', () async {
        final results =
            await FoodService.instance.searchFood('xyzzy-nonexistent-food');
        expect(results, isEmpty);
      });

      test('empty query returns all seed items', () async {
        final results = await FoodService.instance.searchFood('');
        expect(results.length, greaterThanOrEqualTo(6));
      });
    });

    // ── FoodItemModel seed data integrity ─────────────────────────────────────
    group('seed data integrity', () {
      test('all seed items have non-empty names', () async {
        final items = await FoodService.instance.getVegItems();
        for (final item in items) {
          expect(item.name, isNotEmpty);
        }
      });

      test('all seed items have valid ratings between 0 and 5', () async {
        final items = await FoodService.instance.searchFood('');
        for (final item in items) {
          expect(item.rating, inInclusiveRange(0.0, 5.0),
              reason: '${item.name} has invalid rating ${item.rating}');
        }
      });
    });

    // ── fromNominatim edge cases ───────────────────────────────────────────────
    group('FoodItemModel.fromNominatim edge cases', () {
      test('single-segment display_name is used as-is', () {
        final item = FoodItemModel.fromNominatim(
            'x', {'display_name': 'TasteOfIndia'});
        expect(item.name, 'TasteOfIndia');
      });

      test('multi-segment display_name uses first segment only', () {
        final item = FoodItemModel.fromNominatim('x', {
          'display_name': 'Pizza Palace, MG Road, Bangalore',
        });
        expect(item.name, 'Pizza Palace');
      });

      test('place_id is used as placeId string', () {
        final item =
            FoodItemModel.fromNominatim('osm_5', {'place_id': 99999});
        expect(item.placeId, '99999');
      });

      test('missing place_id uses foodId as placeId', () {
        final item = FoodItemModel.fromNominatim('osm_7', {});
        expect(item.placeId, 'osm_7');
      });
    });
  });
}
