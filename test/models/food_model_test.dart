import 'package:flutter_test/flutter_test.dart';
import 'package:exploremate/models/food_model.dart';

void main() {
  group('FoodItemModel', () {
    // ── fromMap ──────────────────────────────────────────────────────────────
    group('fromMap', () {
      test('parses all fields correctly', () {
        final map = {
          'name': 'Pesarattu',
          'category': 'Street Food',
          'cuisine': 'South Indian',
          'rating': 4.7,
          'priceRange': '₹',
          'placeId': 'p009',
          'description': 'Crispy green moong dal crepes.',
          'isVeg': true,
        };

        final item = FoodItemModel.fromMap('f001', map);

        expect(item.foodId, 'f001');
        expect(item.name, 'Pesarattu');
        expect(item.category, 'Street Food');
        expect(item.cuisine, 'South Indian');
        expect(item.rating, 4.7);
        expect(item.priceRange, '₹');
        expect(item.placeId, 'p009');
        expect(item.description, 'Crispy green moong dal crepes.');
        expect(item.isVeg, isTrue);
      });

      test('applies defaults for missing fields', () {
        final map = {'name': 'Mystery Food', 'placeId': 'p-x'};
        final item = FoodItemModel.fromMap('f-x', map);

        expect(item.category, '');
        expect(item.cuisine, '');
        expect(item.rating, 4.0);
        expect(item.priceRange, '₹₹');
        expect(item.isVeg, isFalse);
        expect(item.description, isNull);
      });

      test('coerces int rating to double', () {
        final map = {'name': 'X', 'placeId': 'p', 'rating': 4};
        final item = FoodItemModel.fromMap('fx', map);
        expect(item.rating, 4.0);
        expect(item.rating, isA<double>());
      });
    });

    // ── fromNominatim ─────────────────────────────────────────────────────────
    group('fromNominatim', () {
      test('extracts short name from display_name', () {
        final nominatim = {
          'display_name': 'Pepper House, Beach Road, Visakhapatnam, Andhra Pradesh, India',
          'place_id': 12345,
        };

        final item = FoodItemModel.fromNominatim('osm_0', nominatim);

        expect(item.name, 'Pepper House');
        expect(item.placeId, '12345');
        expect(item.category, 'Restaurant');
        expect(item.cuisine, 'Local');
      });

      test('handles missing display_name gracefully', () {
        final item = FoodItemModel.fromNominatim('osm_1', {});
        expect(item.name, 'Unknown Place');
      });
    });

    // ── toMap ────────────────────────────────────────────────────────────────
    group('toMap', () {
      test('serializes all fields', () {
        const item = FoodItemModel(
          foodId: 'f001',
          name: 'Pesarattu',
          category: 'Street Food',
          cuisine: 'South Indian',
          rating: 4.7,
          priceRange: '₹',
          placeId: 'p009',
          description: 'Crispy crepes.',
          isVeg: true,
        );

        final map = item.toMap();

        expect(map['name'], 'Pesarattu');
        expect(map['category'], 'Street Food');
        expect(map['cuisine'], 'South Indian');
        expect(map['rating'], 4.7);
        expect(map['priceRange'], '₹');
        expect(map['placeId'], 'p009');
        expect(map['description'], 'Crispy crepes.');
        expect(map['isVeg'], isTrue);
      });

      test('omits description when null', () {
        const item = FoodItemModel(
          foodId: 'f-x',
          name: 'X',
          category: 'C',
          cuisine: 'Cu',
          placeId: 'p-x',
        );
        expect(item.toMap().containsKey('description'), isFalse);
      });
    });

    // ── round-trip ────────────────────────────────────────────────────────────
    test('fromMap → toMap round-trip preserves values', () {
      final original = {
        'name': 'Bamboo Chicken',
        'category': 'Restaurant',
        'cuisine': 'Tribal / Araku',
        'rating': 4.8,
        'priceRange': '₹₹',
        'placeId': 'p010',
        'description': 'Cooked inside bamboo.',
        'isVeg': false,
      };

      final item = FoodItemModel.fromMap('f002', original);
      final restored = item.toMap();

      expect(restored['name'], original['name']);
      expect(restored['rating'], original['rating']);
      expect(restored['isVeg'], original['isVeg']);
    });

    // ── toString ─────────────────────────────────────────────────────────────
    test('toString includes foodId, name, and cuisine', () {
      const item = FoodItemModel(
        foodId: 'f001',
        name: 'Pesarattu',
        category: 'Street Food',
        cuisine: 'South Indian',
        placeId: 'p009',
      );
      expect(item.toString(), contains('f001'));
      expect(item.toString(), contains('Pesarattu'));
      expect(item.toString(), contains('South Indian'));
    });
  });
}
