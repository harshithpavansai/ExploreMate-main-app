import 'package:flutter_test/flutter_test.dart';
import 'package:exploremate/models/place_model.dart';

void main() {
  group('PlaceModel', () {
    // ── fromMap ──────────────────────────────────────────────────────────────
    group('fromMap', () {
      test('parses all fields correctly', () {
        final map = {
          'name': 'Borra Caves',
          'type': 'Nature',
          'tag': 'Gem',
          'distKm': 92.0,
          'lat': 18.0756,
          'lng': 83.1403,
          'isHiddenGem': true,
          'description': 'Ancient limestone caves.',
          'rating': 4.7,
        };

        final place = PlaceModel.fromMap('p004', map);

        expect(place.placeId, 'p004');
        expect(place.name, 'Borra Caves');
        expect(place.type, 'Nature');
        expect(place.tag, 'Gem');
        expect(place.distKm, 92.0);
        expect(place.lat, 18.0756);
        expect(place.lng, 83.1403);
        expect(place.isHiddenGem, isTrue);
        expect(place.description, 'Ancient limestone caves.');
        expect(place.rating, 4.7);
      });

      test('uses defaults for missing fields', () {
        final map = {'name': 'Test Place'};
        final place = PlaceModel.fromMap('p-test', map);

        expect(place.type, '');
        expect(place.tag, '');
        expect(place.distKm, 0.0);
        expect(place.lat, 0.0);
        expect(place.lng, 0.0);
        expect(place.isHiddenGem, isFalse);
        expect(place.description, isNull);
        expect(place.rating, 4.5);
      });

      test('coerces int lat/lng to double', () {
        final map = {'name': 'X', 'lat': 17, 'lng': 83};
        final place = PlaceModel.fromMap('px', map);
        expect(place.lat, 17.0);
        expect(place.lng, 83.0);
      });
    });

    // ── fromBackend ───────────────────────────────────────────────────────────
    group('fromBackend', () {
      test('maps PostgreSQL field names to PlaceModel fields', () {
        final backendData = {
          'id': 'dest-001',
          'name': 'Yarada Beach',
          'category': 'Beach',
          'isHiddenGem': true,
          'lat': 17.61,
          'lng': 83.23,
          'rating': 4.6,
          'description': 'Secluded beach.',
        };

        final place = PlaceModel.fromBackend(backendData);

        expect(place.placeId, 'dest-001');
        expect(place.name, 'Yarada Beach');
        expect(place.type, 'Beach');
        expect(place.tag, 'Gem'); // derived from isHiddenGem
        expect(place.isHiddenGem, isTrue);
        expect(place.rating, 4.6);
      });

      test('uses "Popular" tag when isHiddenGem is false', () {
        final place = PlaceModel.fromBackend({
          'id': 'd2',
          'name': 'RK Beach',
          'isHiddenGem': false,
        });
        expect(place.tag, 'Popular');
      });
    });

    // ── toMap ────────────────────────────────────────────────────────────────
    group('toMap', () {
      test('serializes all fields', () {
        const place = PlaceModel(
          placeId: 'p001',
          name: 'Lotus Lake',
          type: 'Hidden gem',
          tag: 'Gem',
          distKm: 2.3,
          lat: 17.69,
          lng: 83.21,
          isHiddenGem: true,
          description: 'Beautiful lake.',
          rating: 4.8,
        );

        final map = place.toMap();

        expect(map['name'], 'Lotus Lake');
        expect(map['type'], 'Hidden gem');
        expect(map['tag'], 'Gem');
        expect(map['distKm'], 2.3);
        expect(map['lat'], 17.69);
        expect(map['lng'], 83.21);
        expect(map['isHiddenGem'], isTrue);
        expect(map['description'], 'Beautiful lake.');
        expect(map['rating'], 4.8);
      });

      test('includes description as null when not set', () {
        const place = PlaceModel(
          placeId: 'p-x',
          name: 'X',
          type: 'Type',
          tag: 'Tag',
          distKm: 0,
          lat: 0,
          lng: 0,
        );
        expect(place.toMap()['description'], isNull);
      });
    });

    // ── round-trip ────────────────────────────────────────────────────────────
    test('fromMap → toMap round-trip preserves values', () {
      final original = {
        'name': 'Submarine Museum',
        'type': 'Museum',
        'tag': 'Must-see',
        'distKm': 4.5,
        'lat': 17.71,
        'lng': 83.31,
        'isHiddenGem': false,
        'description': 'A real submarine.',
        'rating': 4.4,
      };

      final place = PlaceModel.fromMap('p006', original);
      final restored = place.toMap();

      expect(restored['name'], original['name']);
      expect(restored['rating'], original['rating']);
      expect(restored['isHiddenGem'], original['isHiddenGem']);
    });

    // ── toString ─────────────────────────────────────────────────────────────
    test('toString includes placeId and name', () {
      const place = PlaceModel(
        placeId: 'p001',
        name: 'Lotus Lake',
        type: 'X',
        tag: 'X',
        distKm: 0,
        lat: 0,
        lng: 0,
      );
      expect(place.toString(), contains('p001'));
      expect(place.toString(), contains('Lotus Lake'));
    });
  });
}
