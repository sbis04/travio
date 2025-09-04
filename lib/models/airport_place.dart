import 'package:cloud_firestore/cloud_firestore.dart';

/// Represents airport/place information stored in subcollections
class AirportPlace {
  final String placeId;
  final String name;
  final String? formattedAddress;
  final GeoPoint? location;
  final String placeType; // "airport", "hotel", "restaurant", etc.
  final DateTime createdAt;

  AirportPlace({
    required this.placeId,
    required this.name,
    this.formattedAddress,
    this.location,
    required this.placeType,
    required this.createdAt,
  });

  factory AirportPlace.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AirportPlace(
      placeId: data['place_id'] ?? '',
      name: data['name'] ?? '',
      formattedAddress: data['formatted_address'],
      location: data['location'] as GeoPoint?,
      placeType: data['place_type'] ?? 'unknown',
      createdAt: (data['created_at'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'place_id': placeId,
      'name': name,
      'formatted_address': formattedAddress,
      'location': location,
      'place_type': placeType,
      'created_at': Timestamp.fromDate(createdAt),
    };
  }

  AirportPlace copyWith({
    String? placeId,
    String? name,
    String? formattedAddress,
    GeoPoint? location,
    String? placeType,
    DateTime? createdAt,
  }) {
    return AirportPlace(
      placeId: placeId ?? this.placeId,
      name: name ?? this.name,
      formattedAddress: formattedAddress ?? this.formattedAddress,
      location: location ?? this.location,
      placeType: placeType ?? this.placeType,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  // Get latitude from GeoPoint
  double? get latitude => location?.latitude;

  // Get longitude from GeoPoint
  double? get longitude => location?.longitude;

  // Check if location is available
  bool get hasLocation => location != null;

  @override
  String toString() {
    return 'AirportPlace(name: $name, type: $placeType, placeId: $placeId)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AirportPlace && other.placeId == placeId;
  }

  @override
  int get hashCode => placeId.hashCode;
}
