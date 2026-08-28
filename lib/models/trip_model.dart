import 'package:flutter/material.dart';

/// A user-created trip itinerary.
class TripModel {
  final String tripId;
  final String userId;
  final String destination;
  final DateTime startDate;
  final DateTime endDate;
  final DateTime createdAt;
  final List<TripStopModel> stops;

  const TripModel({
    required this.tripId,
    required this.userId,
    required this.destination,
    required this.startDate,
    required this.endDate,
    required this.createdAt,
    this.stops = const [],
  });

  int get totalDays => endDate.difference(startDate).inDays + 1;

  factory TripModel.fromMap(String id, Map<String, dynamic> map) {
    return TripModel(
      tripId: id,
      userId: map['userId'] as String? ?? '',
      destination: map['destination'] as String? ?? '',
      startDate:
          DateTime.tryParse(map['startDate'] as String? ?? '') ?? DateTime.now(),
      endDate:
          DateTime.tryParse(map['endDate'] as String? ?? '') ?? DateTime.now(),
      createdAt:
          DateTime.tryParse(map['createdAt'] as String? ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
        'userId': userId,
        'destination': destination,
        'startDate': startDate.toIso8601String(),
        'endDate': endDate.toIso8601String(),
        'createdAt': createdAt.toIso8601String(),
      };
}

/// A single stop within a trip (one timeline entry).
class TripStopModel {
  final String stopId;
  final String tripId;
  final String placeId;
  final String placeName;
  final String description;
  final String timeSlot;      // e.g. "9:00 AM"
  final String durationLabel; // e.g. "2 hrs"
  final int dayIndex;         // 0-based day
  final int order;            // display order within the day
  final IconData icon;

  const TripStopModel({
    required this.stopId,
    required this.tripId,
    required this.placeId,
    required this.placeName,
    required this.description,
    required this.timeSlot,
    required this.durationLabel,
    required this.dayIndex,
    required this.order,
    this.icon = Icons.place_rounded,
  });

  factory TripStopModel.fromMap(String id, Map<String, dynamic> map) {
    return TripStopModel(
      stopId: id,
      tripId: map['tripId'] as String? ?? '',
      placeId: map['placeId'] as String? ?? '',
      placeName: map['placeName'] as String? ?? '',
      description: map['description'] as String? ?? '',
      timeSlot: map['timeSlot'] as String? ?? '',
      durationLabel: map['durationLabel'] as String? ?? '',
      dayIndex: (map['dayIndex'] as num?)?.toInt() ?? 0,
      order: (map['order'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toMap() => {
        'tripId': tripId,
        'placeId': placeId,
        'placeName': placeName,
        'description': description,
        'timeSlot': timeSlot,
        'durationLabel': durationLabel,
        'dayIndex': dayIndex,
        'order': order,
      };
}
