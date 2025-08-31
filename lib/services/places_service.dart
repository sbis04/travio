import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:travio/models/place.dart';
import 'package:travio/utils/constants.dart';

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
}
