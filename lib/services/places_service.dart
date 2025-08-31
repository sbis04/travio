import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:travio/models/place.dart';
import 'package:travio/utils/utils.dart';

class PlacesService {
  static const String _baseUrl = 'https://places.googleapis.com/v1';
  static const String _apiKey = kGooglePlacesApiKey;

  // Search for travel destinations (simplified approach)
  static Future<List<Place>> searchPlaces(String query) async {
    if (query.isEmpty) return [];

    final String url = '$_baseUrl/places:searchText';

    final Map<String, dynamic> requestBody = {
      'textQuery': '$query city OR $query country OR $query destination',
      'maxResultCount': 15,
    };

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'X-Goog-Api-Key': _apiKey,
          'X-Goog-FieldMask':
              'places.id,places.displayName,places.formattedAddress,places.location,places.rating,places.userRatingCount,places.types,places.photos',
        },
        body: json.encode(requestBody),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List places = data['places'] ?? [];

        return places.map((json) => Place.fromJsonNew(json)).toList();
      } else {
        throw Exception(
            'Failed to search places: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      throw Exception('Error searching places: $e');
    }
  }

  // Get place details by place ID (New API)
  static Future<Place?> getPlaceDetails(String placeId) async {
    final String url = '$_baseUrl/places/$placeId';

    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'X-Goog-Api-Key': _apiKey,
          'X-Goog-FieldMask':
              'id,displayName,formattedAddress,location,rating,userRatingCount,types,photos',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return Place.fromJsonNew(data);
      }
      return null;
    } catch (e) {
      throw Exception('Error getting place details: $e');
    }
  }

  // Get autocomplete suggestions (New API) - Simplified approach
  static Future<List<PlaceSuggestion>> getAutocompleteSuggestions(
      String input) async {
    if (input.isEmpty) return [];

    final String url = '$_baseUrl/places:autocomplete';

    final Map<String, dynamic> requestBody = {
      'input': input,
      // Ask API to suggest only cities, countries and admin areas
      'includedPrimaryTypes': [
        'locality',
        'country',
        'administrative_area_level_1',
      ],
    };

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'X-Goog-Api-Key': _apiKey,
          // Request only fields needed to build destination results
          'X-Goog-FieldMask':
              'suggestions.placePrediction.placeId,suggestions.placePrediction.text,suggestions.placePrediction.structuredFormat',
        },
        body: json.encode(requestBody),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List suggestions = data['suggestions'] ?? [];

        List<PlaceSuggestion> placeSuggestions = [];

        for (var suggestion in suggestions) {
          if (suggestion['placePrediction'] != null) {
            placeSuggestions.add(
                PlaceSuggestion.fromJsonNew(suggestion['placePrediction']));
          }
        }

        return placeSuggestions;
      } else {
        throw Exception(
            'Failed to get autocomplete suggestions: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      throw Exception('Error getting autocomplete suggestions: $e');
    }
  }

  // Destination-only search: use Autocomplete (New) + Place Details
  static Future<List<Place>> searchDestinations(String input) async {
    final suggestions = await getAutocompleteSuggestions(input);
    if (suggestions.isEmpty) return [];

    // Fetch details for each prediction, dedupe by placeId
    final seen = <String>{};
    final results = <Place>[];
    for (final s in suggestions) {
      final id = s.placeId;
      if (id.isEmpty || seen.contains(id)) continue;
      seen.add(id);
      final details = await getPlaceDetails(id);
      if (details != null) {
        results.add(details);
      }
    }
    return results;
  }

  // Get place photos using Place Photos (New) API
  static Future<List<String>> getPlacePhotos({
    required String placeId,
    int maxPhotos = 20,
    int maxWidth = 800,
  }) async {
    try {
      // Get place details with expanded photo field mask
      final String url = '$_baseUrl/places/$placeId';

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'X-Goog-Api-Key': _apiKey,
          'X-Goog-FieldMask': 'photos',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List photos = data['photos'] ?? [];

        logPrint('📸 API returned ${photos.length} photos for place $placeId');

        List<String> photoUrls = [];

        // Process up to maxPhotos
        for (int i = 0; i < photos.length && i < maxPhotos; i++) {
          final photoName = photos[i]['name'];
          if (photoName != null) {
            final photoUrl = getPhotoUrlFromName(
              photoName: photoName,
              maxWidth: maxWidth,
            );
            photoUrls.add(photoUrl);
          }
        }

        logPrint('📸 Generated ${photoUrls.length} photo URLs');
        // If we have fewer photos than requested, try to get more from nearby search
        if (photoUrls.length < maxPhotos) {
          logPrint(
              '📸 Only ${photoUrls.length} photos found, trying to get more...');
          final additionalPhotos = await _getAdditionalPlacePhotos(
            placeId: placeId,
            existingCount: photoUrls.length,
            maxAdditional: maxPhotos - photoUrls.length,
            maxWidth: maxWidth,
          );
          photoUrls.addAll(additionalPhotos);
          logPrint(
              '📸 Total photos after additional search: ${photoUrls.length}');
        }

        return photoUrls;
      } else {
        throw Exception(
            'Failed to get place photos: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      throw Exception('Error getting place photos: $e');
    }
  }

  // Try to get additional photos by searching for similar places nearby
  static Future<List<String>> _getAdditionalPlacePhotos({
    required String placeId,
    required int existingCount,
    required int maxAdditional,
    required int maxWidth,
  }) async {
    try {
      // Get the main place details first
      final mainPlace = await getPlaceDetails(placeId);
      if (mainPlace == null || !mainPlace.hasLocation) {
        return [];
      }

      // Search for tourist attractions near this place
      final String url = '$_baseUrl/places:searchNearby';

      final Map<String, dynamic> requestBody = {
        'locationRestriction': {
          'circle': {
            'center': {
              'latitude': mainPlace.latitude,
              'longitude': mainPlace.longitude,
            },
            'radius': 1000.0, // 1km radius
          }
        },
        'includedTypes': ['tourist_attraction'],
        'maxResultCount': 5,
      };

      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'X-Goog-Api-Key': _apiKey,
          'X-Goog-FieldMask': 'places.photos',
        },
        body: json.encode(requestBody),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List places = data['places'] ?? [];

        List<String> additionalPhotoUrls = [];

        for (var place in places) {
          final List photos = place['photos'] ?? [];
          for (var photo in photos) {
            if (additionalPhotoUrls.length >= maxAdditional) break;

            final photoName = photo['name'];
            if (photoName != null) {
              final photoUrl = getPhotoUrlFromName(
                photoName: photoName,
                maxWidth: maxWidth,
              );
              additionalPhotoUrls.add(photoUrl);
            }
          }
          if (additionalPhotoUrls.length >= maxAdditional) break;
        }

        return additionalPhotoUrls;
      }

      return [];
    } catch (e) {
      logPrint('❌ Error getting additional photos: $e');
      return [];
    }
  }

  // Get place photo URL using photo name (for New API)
  static String getPhotoUrlFromName({
    required String photoName,
    int maxWidth = 800,
    int maxHeight = 600,
  }) {
    return 'https://places.googleapis.com/v1/$photoName/media?maxWidthPx=$maxWidth&maxHeightPx=$maxHeight&key=$_apiKey';
  }

  // Search for place with more photo details
  static Future<Place?> getPlaceWithPhotos(String placeId) async {
    final String url = '$_baseUrl/places/$placeId';

    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'X-Goog-Api-Key': _apiKey,
          'X-Goog-FieldMask':
              'id,displayName,formattedAddress,location,rating,userRatingCount,types,photos',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return Place.fromJsonNew(data);
      }
      return null;
    } catch (e) {
      throw Exception('Error getting place with photos: $e');
    }
  }
}
