import 'package:flutter_test/flutter_test.dart';
import 'package:exploremate/models/trip_model.dart';

void main() {
  group('TripModel', () {
    // ── fromMap ──────────────────────────────────────────────────────────────
    group('fromMap', () {
      test('parses all fields correctly', () {
        final map = {
          'userId': 'user-001',
          'destination': 'Vizag',
          'startDate': '2026-04-14T00:00:00.000',
          'endDate': '2026-04-16T00:00:00.000',
          'createdAt': '2026-03-01T10:00:00.000',
        };

        final trip = TripModel.fromMap('t001', map);

        expect(trip.tripId, 't001');
        expect(trip.userId, 'user-001');
        expect(trip.destination, 'Vizag');
        expect(trip.startDate, DateTime(2026, 4, 14));
        expect(trip.endDate, DateTime(2026, 4, 16));
        expect(trip.createdAt, DateTime(2026, 3, 1, 10));
      });

      test('applies defaults for missing fields', () {
        final map = <String, dynamic>{};
        final trip = TripModel.fromMap('t-empty', map);

        expect(trip.userId, '');
        expect(trip.destination, '');
        expect(trip.stops, isEmpty);
      });

      test('handles invalid date strings with DateTime.now()', () {
        final before = DateTime.now().subtract(const Duration(seconds: 1));
        final map = {
          'userId': 'uid',
          'destination': 'X',
          'startDate': 'bad-date',
          'endDate': 'also-bad',
          'createdAt': 'nope',
        };
        final trip = TripModel.fromMap('t-bad', map);
        expect(trip.startDate.isAfter(before), isTrue);
      });
    });

    // ── toMap ────────────────────────────────────────────────────────────────
    group('toMap', () {
      test('serializes all fields', () {
        final trip = TripModel(
          tripId: 't001',
          userId: 'user-001',
          destination: 'Vizag',
          startDate: DateTime(2026, 4, 14),
          endDate: DateTime(2026, 4, 16),
          createdAt: DateTime(2026, 3, 1),
        );

        final map = trip.toMap();

        expect(map['userId'], 'user-001');
        expect(map['destination'], 'Vizag');
        expect(map['startDate'], '2026-04-14T00:00:00.000');
        expect(map['endDate'], '2026-04-16T00:00:00.000');
        expect(map['createdAt'], '2026-03-01T00:00:00.000');
      });
    });

    // ── totalDays ─────────────────────────────────────────────────────────────
    group('totalDays getter', () {
      test('same-day trip returns 1', () {
        final trip = TripModel(
          tripId: 't1',
          userId: 'u1',
          destination: 'X',
          startDate: DateTime(2026, 5, 1),
          endDate: DateTime(2026, 5, 1),
          createdAt: DateTime.now(),
        );
        expect(trip.totalDays, 1);
      });

      test('2-day trip returns 2', () {
        final trip = TripModel(
          tripId: 't2',
          userId: 'u1',
          destination: 'X',
          startDate: DateTime(2026, 5, 1),
          endDate: DateTime(2026, 5, 2),
          createdAt: DateTime.now(),
        );
        expect(trip.totalDays, 2);
      });

      test('3-day trip returns 3', () {
        final trip = TripModel(
          tripId: 't3',
          userId: 'u1',
          destination: 'Vizag',
          startDate: DateTime(2026, 4, 14),
          endDate: DateTime(2026, 4, 16),
          createdAt: DateTime.now(),
        );
        expect(trip.totalDays, 3);
      });
    });

    // ── round-trip ────────────────────────────────────────────────────────────
    test('fromMap → toMap round-trip preserves values', () {
      final original = {
        'userId': 'uid-xyz',
        'destination': 'Araku Valley',
        'startDate': '2026-06-01T00:00:00.000',
        'endDate': '2026-06-03T00:00:00.000',
        'createdAt': '2026-05-01T00:00:00.000',
      };

      final trip = TripModel.fromMap('t-araku', original);
      final restored = trip.toMap();

      expect(restored['userId'], original['userId']);
      expect(restored['destination'], original['destination']);
      expect(restored['startDate'], original['startDate']);
      expect(restored['endDate'], original['endDate']);
    });
  });

  // ── TripStopModel ──────────────────────────────────────────────────────────
  group('TripStopModel', () {
    group('fromMap', () {
      test('parses all fields correctly', () {
        final map = {
          'tripId': 't001',
          'placeId': 'p007',
          'placeName': 'RK Beach',
          'description': 'Scenic morning walk',
          'timeSlot': '9:00 AM',
          'durationLabel': '1.5 hrs',
          'dayIndex': 0,
          'order': 0,
        };

        final stop = TripStopModel.fromMap('s001', map);

        expect(stop.stopId, 's001');
        expect(stop.tripId, 't001');
        expect(stop.placeId, 'p007');
        expect(stop.placeName, 'RK Beach');
        expect(stop.description, 'Scenic morning walk');
        expect(stop.timeSlot, '9:00 AM');
        expect(stop.durationLabel, '1.5 hrs');
        expect(stop.dayIndex, 0);
        expect(stop.order, 0);
      });

      test('applies defaults for missing fields', () {
        final stop = TripStopModel.fromMap('s-empty', {});
        expect(stop.tripId, '');
        expect(stop.dayIndex, 0);
        expect(stop.order, 0);
      });
    });

    group('toMap', () {
      test('serializes all fields', () {
        const stop = TripStopModel(
          stopId: 's001',
          tripId: 't001',
          placeId: 'p007',
          placeName: 'RK Beach',
          description: 'Morning walk',
          timeSlot: '9:00 AM',
          durationLabel: '1.5 hrs',
          dayIndex: 0,
          order: 0,
        );

        final map = stop.toMap();

        expect(map['tripId'], 't001');
        expect(map['placeId'], 'p007');
        expect(map['placeName'], 'RK Beach');
        expect(map['timeSlot'], '9:00 AM');
        expect(map['dayIndex'], 0);
        expect(map['order'], 0);
      });
    });
  });
}
