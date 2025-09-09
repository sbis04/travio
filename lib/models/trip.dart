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
  final DateTime? startDate;
  final DateTime? endDate;
  final DateTime createdAt;
  final DateTime updatedAt;
  final TripStatus status;
  final TripDocumentInfo documentInfo;
  // true if created by anonymous user, false if authenticated
  final bool isPublic;

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
    this.startDate,
    this.endDate,
    required this.createdAt,
    required this.updatedAt,
    this.status = TripStatus.planning,
    this.documentInfo = const TripDocumentInfo(),
    this.isPublic = true, // Default to public
  });

  // Create Trip from Place
  factory Trip.fromPlace({
    required String userUid,
    required Place place,
    String? customId,
    bool? isPublic,
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
      isPublic: isPublic ?? true, // Default to public
    );
  }

  // Convert to Firestore document (using snake_case)
  Map<String, dynamic> toFirestore() {
    return {
      'user_uid': userUid,
      'place_id': placeId,
      'place_name': placeName,
      'place_address': placeAddress,
      'latitude': latitude,
      'longitude': longitude,
      'rating': rating,
      'place_types': placeTypes,
      'trip_duration': {
        'start_date': startDate != null ? Timestamp.fromDate(startDate!) : null,
        'end_date': endDate != null ? Timestamp.fromDate(endDate!) : null,
      },
      'document_info': documentInfo.toFirestore(),
      'is_public': isPublic,
      'created_at': Timestamp.fromDate(createdAt),
      'updated_at': Timestamp.fromDate(updatedAt),
      'status': status.name,
    };
  }

  // Create from Firestore document (using snake_case)
  factory Trip.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Trip(
      id: doc.id,
      userUid: data['user_uid'] ?? '',
      placeId: data['place_id'] ?? '',
      placeName: data['place_name'] ?? '',
      placeAddress: data['place_address'],
      latitude: data['latitude']?.toDouble(),
      longitude: data['longitude']?.toDouble(),
      rating: data['rating']?.toDouble(),
      placeTypes: List<String>.from(data['place_types'] ?? []),
      startDate: data['trip_duration']?['start_date'] != null
          ? (data['trip_duration']['start_date'] as Timestamp).toDate()
          : null,
      endDate: data['trip_duration']?['end_date'] != null
          ? (data['trip_duration']['end_date'] as Timestamp).toDate()
          : null,
      createdAt: (data['created_at'] as Timestamp).toDate(),
      updatedAt: (data['updated_at'] as Timestamp).toDate(),
      status: TripStatus.values.firstWhere(
        (status) => status.name == data['status'],
        orElse: () => TripStatus.planning,
      ),
      documentInfo: data['document_info'] != null
          ? TripDocumentInfo.fromFirestore(data['document_info'])
          : const TripDocumentInfo(),
      // Default to public for backward compatibility
      isPublic: data['is_public'] ?? true,
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
    DateTime? startDate,
    DateTime? endDate,
    DateTime? updatedAt,
    TripStatus? status,
    TripDocumentInfo? documentInfo,
    bool? isPublic,
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
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
      status: status ?? this.status,
      documentInfo: documentInfo ?? this.documentInfo,
      isPublic: isPublic ?? this.isPublic,
    );
  }

  // Helper methods for trip visibility
  bool get isPrivate => !isPublic;

  // Helper method to get visibility as string
  String get visibilityString => isPublic ? 'Public' : 'Private';

  @override
  String toString() {
    return 'Trip(id: $id, destination: $placeName, status: $status, visibility: $visibilityString)';
  }
}

enum TripStatus {
  planning,
  ready,
  active,
  completed,
  cancelled,
}

/// Document information tracking for a trip
class TripDocumentInfo {
  final bool hasFlightInfo;
  final bool hasHotelInfo;
  final DateTime? updatedAt;

  const TripDocumentInfo({
    this.hasFlightInfo = false,
    this.hasHotelInfo = false,
    this.updatedAt,
  });

  // Convert to Firestore (using snake_case)
  Map<String, dynamic> toFirestore() {
    return {
      'has_flight_info': hasFlightInfo,
      'has_hotel_info': hasHotelInfo,
      'updated_at': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
    };
  }

  // Create from Firestore (using snake_case)
  factory TripDocumentInfo.fromFirestore(Map<String, dynamic> data) {
    return TripDocumentInfo(
      hasFlightInfo: data['has_flight_info'] ?? false,
      hasHotelInfo: data['has_hotel_info'] ?? false,
      updatedAt: data['updated_at'] != null
          ? (data['updated_at'] as Timestamp).toDate()
          : null,
    );
  }

  // Copy with updated fields
  TripDocumentInfo copyWith({
    bool? hasFlightInfo,
    bool? hasHotelInfo,
    DateTime? updatedAt,
  }) {
    return TripDocumentInfo(
      hasFlightInfo: hasFlightInfo ?? this.hasFlightInfo,
      hasHotelInfo: hasHotelInfo ?? this.hasHotelInfo,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'TripDocumentInfo(hasFlightInfo: $hasFlightInfo, hasHotelInfo: $hasHotelInfo)';
  }
}
