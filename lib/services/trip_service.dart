import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/trip_model.dart';

/// Trip / itinerary service backed by Firestore.
/// Collections:
///   trips/{tripId}          — trip metadata
///   trips/{tripId}/stops/{stopId}  — individual stops
class TripService {
  TripService._();
  static final TripService instance = TripService._();

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ── Trips ─────────────────────────────────────────────────────────────────

  /// Fetch all trips for [userId] ordered by creation time (newest first).
  Future<List<TripModel>> getTrips(String userId) async {
    try {
      final snap = await _db
          .collection('trips')
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .get();

      final trips = <TripModel>[];
      for (final doc in snap.docs) {
        final trip = TripModel.fromMap(doc.id, doc.data());
        final stops = await _getStops(doc.id);
        trips.add(TripModel(
          tripId: trip.tripId,
          userId: trip.userId,
          destination: trip.destination,
          startDate: trip.startDate,
          endDate: trip.endDate,
          createdAt: trip.createdAt,
          stops: stops,
        ));
      }
      return trips;
    } catch (e) {
      debugPrint('TripService.getTrips error: $e');
      return [];
    }
  }

  /// Fetch a single trip by ID including its stops.
  Future<TripModel?> getTripById(String tripId) async {
    try {
      final doc = await _db.collection('trips').doc(tripId).get();
      if (!doc.exists || doc.data() == null) return null;
      final trip = TripModel.fromMap(doc.id, doc.data()!);
      final stops = await _getStops(tripId);
      return TripModel(
        tripId: trip.tripId,
        userId: trip.userId,
        destination: trip.destination,
        startDate: trip.startDate,
        endDate: trip.endDate,
        createdAt: trip.createdAt,
        stops: stops,
      );
    } catch (e) {
      debugPrint('TripService.getTripById error: $e');
      return null;
    }
  }

  /// Create a new trip and persist it in Firestore.
  Future<TripModel> createTrip({
    required String userId,
    required String destination,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final tripData = {
      'userId': userId,
      'destination': destination,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'createdAt': DateTime.now().toIso8601String(),
    };

    final ref = await _db.collection('trips').add(tripData);
    return TripModel(
      tripId: ref.id,
      userId: userId,
      destination: destination,
      startDate: startDate,
      endDate: endDate,
      createdAt: DateTime.now(),
    );
  }

  /// Delete a trip and all its stops.
  Future<void> deleteTrip(String tripId) async {
    try {
      final stopsSnap =
          await _db.collection('trips').doc(tripId).collection('stops').get();
      for (final d in stopsSnap.docs) {
        await d.reference.delete();
      }
      await _db.collection('trips').doc(tripId).delete();
    } catch (e) {
      debugPrint('TripService.deleteTrip error: $e');
    }
  }

  // ── Stops ─────────────────────────────────────────────────────────────────

  /// Add a stop to an existing trip in Firestore.
  Future<void> addStop(TripStopModel stop) async {
    try {
      await _db
          .collection('trips')
          .doc(stop.tripId)
          .collection('stops')
          .doc(stop.stopId)
          .set(stop.toMap());
    } catch (e) {
      debugPrint('TripService.addStop error: $e');
    }
  }

  /// Delete a single stop from Firestore.
  Future<void> deleteStop(String tripId, String stopId) async {
    try {
      await _db
          .collection('trips')
          .doc(tripId)
          .collection('stops')
          .doc(stopId)
          .delete();
    } catch (e) {
      debugPrint('TripService.deleteStop error: $e');
    }
  }

  // ── Private helpers ───────────────────────────────────────────────────────

  Future<List<TripStopModel>> _getStops(String tripId) async {
    try {
      final snap = await _db
          .collection('trips')
          .doc(tripId)
          .collection('stops')
          .orderBy('dayIndex')
          .orderBy('order')
          .get();
      return snap.docs
          .map((d) => TripStopModel.fromMap(d.id, d.data()))
          .toList();
    } catch (e) {
      debugPrint('TripService._getStops error: $e');
      return [];
    }
  }
}
