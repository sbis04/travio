import 'package:cloud_firestore/cloud_firestore.dart';

class Place {
  final String placeId;
  final String name;
  final String? address;
  final double? latitude;
  final double? longitude;
  final double? rating;
  final int? userRatingsTotal;
  final List<String> types;
  final String? photoReference;
  final List<String> photoUrls; // Store actual photo URLs
  final String? vicinity;
  final String? formattedAddress;
  final String? internationalPhoneNumber;
  final String? website;
  final PlaceOpeningHours? openingHours;

  Place({
    required this.placeId,
    required this.name,
    this.address,
    this.latitude,
    this.longitude,
    this.rating,
    this.userRatingsTotal,
    this.types = const [],
    this.photoReference,
    this.photoUrls = const [],
    this.vicinity,
    this.formattedAddress,
    this.internationalPhoneNumber,
    this.website,
    this.openingHours,
  });

  factory Place.fromJson(Map<String, dynamic> json) {
    final geometry = json['geometry'];
    final location = geometry?['location'];
    final photos = json['photos'] as List?;

    return Place(
      placeId: json['place_id'] ?? '',
      name: json['name'] ?? '',
      address: json['formatted_address'] ?? json['vicinity'],
      latitude: location?['lat']?.toDouble(),
      longitude: location?['lng']?.toDouble(),
      rating: json['rating']?.toDouble(),
      userRatingsTotal: json['user_ratings_total'],
      types: List<String>.from(json['types'] ?? []),
      photoReference:
          photos?.isNotEmpty == true ? photos!.first['photo_reference'] : null,
      vicinity: json['vicinity'],
      formattedAddress: json['formatted_address'],
      internationalPhoneNumber: json['international_phone_number'],
      website: json['website'],
      openingHours: json['opening_hours'] != null
          ? PlaceOpeningHours.fromJson(json['opening_hours'])
          : null,
    );
  }

  // New API response format
  factory Place.fromJsonNew(Map<String, dynamic> json) {
    final location = json['location'];
    final photos = json['photos'] as List?;

    return Place(
      placeId: json['id'] ?? '',
      name: json['displayName']?['text'] ?? '',
      address: json['formattedAddress'] ?? json['shortFormattedAddress'],
      latitude: location?['latitude']?.toDouble(),
      longitude: location?['longitude']?.toDouble(),
      rating: json['rating']?.toDouble(),
      userRatingsTotal: json['userRatingCount'],
      types: List<String>.from(json['types'] ?? []),
      photoReference: photos?.isNotEmpty == true ? photos!.first['name'] : null,
      photoUrls: List<String>.from(
          json['photoUrls'] ?? []), // Store photo URLs from Cloud Function
      vicinity: json['shortFormattedAddress'],
      formattedAddress: json['formattedAddress'],
      internationalPhoneNumber: json['internationalPhoneNumber'],
      website: json['websiteUri'],
      openingHours: json['currentOpeningHours'] != null
          ? PlaceOpeningHours.fromJsonNew(json['currentOpeningHours'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'placeId': placeId,
      'name': name,
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
      'rating': rating,
      'userRatingsTotal': userRatingsTotal,
      'types': types,
      'photoReference': photoReference,
      'vicinity': vicinity,
      'formattedAddress': formattedAddress,
      'internationalPhoneNumber': internationalPhoneNumber,
      'website': website,
      'openingHours': openingHours?.toJson(),
    };
  }

  // For Firebase Firestore
  factory Place.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Place(
      placeId: data['placeId'] ?? '',
      name: data['name'] ?? '',
      address: data['address'],
      latitude: data['latitude']?.toDouble(),
      longitude: data['longitude']?.toDouble(),
      rating: data['rating']?.toDouble(),
      userRatingsTotal: data['userRatingsTotal'],
      types: List<String>.from(data['types'] ?? []),
      photoReference: data['photoReference'],
      vicinity: data['vicinity'],
      formattedAddress: data['formattedAddress'],
      internationalPhoneNumber: data['internationalPhoneNumber'],
      website: data['website'],
      openingHours: data['openingHours'] != null
          ? PlaceOpeningHours.fromJson(data['openingHours'])
          : null,
    );
  }

  String getPhotoUrl({int maxWidth = 400}) {
    if (photoReference == null || photoReference!.isEmpty) return '';

    // Note: This method is deprecated when using Cloud Functions
    // Use PlacesService.getPlacePhotos() instead for secure photo fetching
    // Returning empty string to prevent direct API calls
    return '';
  }

  String get displayAddress => formattedAddress ?? vicinity ?? address ?? '';

  bool get hasLocation => latitude != null && longitude != null;
}

class PlaceOpeningHours {
  final bool openNow;
  final List<String> weekdayText;

  PlaceOpeningHours({
    required this.openNow,
    required this.weekdayText,
  });

  factory PlaceOpeningHours.fromJson(Map<String, dynamic> json) {
    return PlaceOpeningHours(
      openNow: json['open_now'] ?? false,
      weekdayText: List<String>.from(json['weekday_text'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'open_now': openNow,
      'weekday_text': weekdayText,
    };
  }

  // New API response format
  factory PlaceOpeningHours.fromJsonNew(Map<String, dynamic> json) {
    return PlaceOpeningHours(
      openNow: json['openNow'] ?? false,
      weekdayText: List<String>.from(json['weekdayDescriptions'] ?? []),
    );
  }
}

class PlaceSuggestion {
  final String placeId;
  final String description;
  final String mainText;
  final String secondaryText;
  final List<String> types;

  PlaceSuggestion({
    required this.placeId,
    required this.description,
    required this.mainText,
    required this.secondaryText,
    required this.types,
  });

  factory PlaceSuggestion.fromJson(Map<String, dynamic> json) {
    final structuredFormatting = json['structured_formatting'] ?? {};

    return PlaceSuggestion(
      placeId: json['place_id'] ?? '',
      description: json['description'] ?? '',
      mainText: structuredFormatting['main_text'] ?? '',
      secondaryText: structuredFormatting['secondary_text'] ?? '',
      types: List<String>.from(json['types'] ?? []),
    );
  }

  // New API response format for place predictions
  factory PlaceSuggestion.fromJsonNew(Map<String, dynamic> json) {
    final text = json['text'] ?? {};
    final structuredFormat = json['structuredFormat'] ?? {};
    final mainText = structuredFormat['mainText'] ?? {};
    final secondaryText = structuredFormat['secondaryText'] ?? {};

    return PlaceSuggestion(
      placeId: json['placeId'] ?? '',
      description: text['text'] ?? '',
      mainText: mainText['text'] ?? '',
      secondaryText: secondaryText['text'] ?? '',
      types: List<String>.from(json['types'] ?? []),
    );
  }

  // New API response format for query predictions
  factory PlaceSuggestion.fromQueryPrediction(Map<String, dynamic> json) {
    final text = json['text'] ?? {};

    return PlaceSuggestion(
      placeId: '', // Query predictions don't have place IDs
      description: text['text'] ?? '',
      mainText: text['text'] ?? '',
      secondaryText: 'Search query',
      types: ['query'],
    );
  }
}
