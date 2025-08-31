import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:travio/models/place.dart';

class Trip {
  final String id;
  final String userUid;
  final String placeId;
  final String placeName;
  final String? placeAddress;
  final double? latitude;
  final double? longitude;
  final double? rating;
  final List<String> placeTypes;
  final DateTime createdAt;
  final DateTime updatedAt;
  final TripStatus status;

  Trip({
    required this.id,
    required this.userUid,
    required this.placeId,
    required this.placeName,
    this.placeAddress,
    this.latitude,
    this.longitude,
    this.rating,
    this.placeTypes = const [],
    required this.createdAt,
    required this.updatedAt,
    this.status = TripStatus.planning,
  });

  // Create Trip from Place
  factory Trip.fromPlace({
    required String userUid,
    required Place place,
    String? customId,
  }) {
    final now = DateTime.now();
    return Trip(
      id: customId ?? '', // Will be set by Firestore
      userUid: userUid,
      placeId: place.placeId,
      placeName: place.name,
      placeAddress: place.displayAddress,
      latitude: place.latitude,
      longitude: place.longitude,
      rating: place.rating,
      placeTypes: place.types,
      createdAt: now,
      updatedAt: now,
      status: TripStatus.planning,
    );
  }

  // Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'userUid': userUid,
      'placeId': placeId,
      'placeName': placeName,
      'placeAddress': placeAddress,
      'latitude': latitude,
      'longitude': longitude,
      'rating': rating,
      'placeTypes': placeTypes,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'status': status.name,
    };
  }

  // Create from Firestore document
  factory Trip.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Trip(
      id: doc.id,
      userUid: data['userUid'] ?? '',
      placeId: data['placeId'] ?? '',
      placeName: data['placeName'] ?? '',
      placeAddress: data['placeAddress'],
      latitude: data['latitude']?.toDouble(),
      longitude: data['longitude']?.toDouble(),
      rating: data['rating']?.toDouble(),
      placeTypes: List<String>.from(data['placeTypes'] ?? []),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
      status: TripStatus.values.firstWhere(
        (status) => status.name == data['status'],
        orElse: () => TripStatus.planning,
      ),
    );
  }

  // Copy with updated fields
  Trip copyWith({
    String? userUid,
    String? placeId,
    String? placeName,
    String? placeAddress,
    double? latitude,
    double? longitude,
    double? rating,
    List<String>? placeTypes,
    DateTime? updatedAt,
    TripStatus? status,
  }) {
    return Trip(
      id: id,
      userUid: userUid ?? this.userUid,
      placeId: placeId ?? this.placeId,
      placeName: placeName ?? this.placeName,
      placeAddress: placeAddress ?? this.placeAddress,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      rating: rating ?? this.rating,
      placeTypes: placeTypes ?? this.placeTypes,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
      status: status ?? this.status,
    );
  }
}

enum TripStatus {
  planning,
  active,
  completed,
  cancelled,
}
