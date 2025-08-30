import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:travio/models/place.dart';
import 'package:travio/utils/constants.dart';

class PlacesService {
  static const String _baseUrl = 'https://places.googleapis.com/v1';
  static const String _apiKey = kGooglePlacesApiKey;

  // Search for places using text query (New API)
  static Future<List<Place>> searchPlaces(String query) async {
    if (query.isEmpty) return [];

    final String url = '$_baseUrl/places:searchText';

    final Map<String, dynamic> requestBody = {
      'textQuery': query,
      'maxResultCount': 20,
    };

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'X-Goog-Api-Key': _apiKey,
          'X-Goog-FieldMask':
              'places.id,places.displayName,places.formattedAddress,places.location,places.rating,places.userRatingCount,places.types,places.photos,places.currentOpeningHours,places.internationalPhoneNumber,places.websiteUri,places.shortFormattedAddress',
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
              'id,displayName,formattedAddress,location,rating,userRatingCount,types,photos,currentOpeningHours,internationalPhoneNumber,websiteUri,shortFormattedAddress',
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

  // Get autocomplete suggestions (New API)
  static Future<List<PlaceSuggestion>> getAutocompleteSuggestions(
      String input) async {
    if (input.isEmpty) return [];

    final String url = '$_baseUrl/places:autocomplete';

    final Map<String, dynamic> requestBody = {
      'input': input,
      'includeQueryPredictions': true,
    };

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'X-Goog-Api-Key': _apiKey,
          'X-Goog-FieldMask':
              'suggestions.placePrediction.placeId,suggestions.placePrediction.text,suggestions.placePrediction.structuredFormat,suggestions.placePrediction.types,suggestions.queryPrediction.text',
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
          if (suggestion['queryPrediction'] != null) {
            placeSuggestions.add(PlaceSuggestion.fromQueryPrediction(
                suggestion['queryPrediction']));
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

  // Get nearby places (New API)
  static Future<List<Place>> getNearbyPlaces({
    required double latitude,
    required double longitude,
    int radius = 5000,
    String type = 'tourist_attraction',
  }) async {
    final String url = '$_baseUrl/places:searchNearby';

    final Map<String, dynamic> requestBody = {
      'locationRestriction': {
        'circle': {
          'center': {
            'latitude': latitude,
            'longitude': longitude,
          },
          'radius': radius.toDouble(),
        }
      },
      'includedTypes': [type],
      'maxResultCount': 20,
    };

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'X-Goog-Api-Key': _apiKey,
          'X-Goog-FieldMask':
              'places.id,places.displayName,places.formattedAddress,places.location,places.rating,places.userRatingCount,places.types,places.photos,places.currentOpeningHours,places.internationalPhoneNumber,places.websiteUri,places.shortFormattedAddress',
        },
        body: json.encode(requestBody),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List places = data['places'] ?? [];

        return places.map((json) => Place.fromJsonNew(json)).toList();
      } else {
        throw Exception(
            'Failed to get nearby places: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      throw Exception('Error getting nearby places: $e');
    }
  }
}
