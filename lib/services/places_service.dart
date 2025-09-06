import 'package:cloud_functions/cloud_functions.dart';
import 'package:travio/models/place.dart';
import 'package:travio/services/place_photo_cache_service.dart';
import 'package:travio/utils/utils.dart';

class PlacesService {
  static final FirebaseFunctions _functions = FirebaseFunctions.instance;

  // Search for destinations using Firebase Cloud Function
  static Future<List<Place>> searchDestinations(String input) async {
    try {
      logPrint('🔍 Searching destinations via Cloud Function: $input');

      final HttpsCallable callable =
          _functions.httpsCallable('searchDestinations');
      final result = await callable.call({'input': input});

      final List places = result.data['places'] ?? [];
      final destinations =
          places.map((json) => Place.fromJsonNew(json)).toList();

      logPrint('✅ Cloud Function returned ${destinations.length} destinations');
      return destinations;
    } catch (e) {
      logPrint('❌ Error in searchDestinations Cloud Function: $e');
      throw Exception('Error searching destinations: $e');
    }
  }

  // Get place photos using cache-first approach
  static Future<List<String>> getPlacePhotos({
    required String placeId,
    int maxPhotos = 20,
    int maxWidth = 800,
  }) async {
    try {
      // Use cache service for cost optimization
      return await PlacePhotoCacheService.getPlacePhotos(
        placeId: placeId,
        maxPhotos: maxPhotos,
        maxWidth: maxWidth,
      );
    } catch (e) {
      logPrint('❌ Error in cached getPlacePhotos: $e');
      throw Exception('Error getting place photos: $e');
    }
  }

  // Get place photos directly from API (internal use by cache service)
  static Future<List<String>> getPlacePhotosFromAPI({
    required String placeId,
    int maxPhotos = 20,
    int maxWidth = 800,
  }) async {
    try {
      logPrint('📸 Getting place photos via Cloud Function: $placeId');

      final HttpsCallable callable = _functions.httpsCallable('getPlacePhotos');
      final result = await callable.call({
        'placeId': placeId,
        'maxPhotos': maxPhotos,
        'maxWidth': maxWidth,
      });

      final List photos = result.data['photos'] ?? [];
      final photoUrls = List<String>.from(photos);

      logPrint('✅ Cloud Function returned ${photoUrls.length} photos');
      return photoUrls;
    } catch (e) {
      logPrint('❌ Error in getPlacePhotos Cloud Function: $e');
      throw Exception('Error getting place photos: $e');
    }
  }

  // Get place details using Firebase Cloud Function
  static Future<Place?> getPlaceDetails(String placeId) async {
    try {
      logPrint('📍 Getting place details via Cloud Function: $placeId');

      final HttpsCallable callable =
          _functions.httpsCallable('getPlaceDetails');
      final result = await callable.call({'placeId': placeId});

      final placeData = result.data['place'];
      if (placeData != null) {
        final place = Place.fromJsonNew(placeData);
        logPrint('✅ Cloud Function returned place details: ${place.name}');
        return place;
      }

      return null;
    } catch (e) {
      logPrint('❌ Error in getPlaceDetails Cloud Function: $e');
      throw Exception('Error getting place details: $e');
    }
  }

  // Get autocomplete suggestions using Firebase Cloud Function
  static Future<List<PlaceSuggestion>> getAutocompleteSuggestions(
      String input) async {
    try {
      logPrint('🔍 Getting autocomplete via Cloud Function: $input');

      final HttpsCallable callable =
          _functions.httpsCallable('getAutocompleteSuggestions');
      final result = await callable.call({'input': input});

      final List suggestions = result.data['suggestions'] ?? [];
      final placeSuggestions = <PlaceSuggestion>[];

      for (var suggestion in suggestions) {
        if (suggestion['placePrediction'] != null) {
          placeSuggestions
              .add(PlaceSuggestion.fromJsonNew(suggestion['placePrediction']));
        }
      }

      logPrint(
          '✅ Cloud Function returned ${placeSuggestions.length} suggestions');
      return placeSuggestions;
    } catch (e) {
      logPrint('❌ Error in getAutocompleteSuggestions Cloud Function: $e');
      throw Exception('Error getting autocomplete suggestions: $e');
    }
  }

  // Get popular places for a destination using Firebase Cloud Function
  static Future<List<Place>> getPopularPlaces({
    required String placeId,
    int maxResults = 20,
  }) async {
    try {
      logPrint('🏛️ Getting popular places via Cloud Function: $placeId');

      final HttpsCallable callable =
          _functions.httpsCallable('getPopularPlaces');
      final result = await callable.call({
        'placeId': placeId,
        'maxResults': maxResults,
      });

      final List places = result.data['places'] ?? [];
      final popularPlaces =
          places.map((json) => Place.fromJsonNew(json)).toList();

      logPrint(
          '✅ Cloud Function returned ${popularPlaces.length} popular places');
      return popularPlaces;
    } catch (e) {
      logPrint('❌ Error in getPopularPlaces Cloud Function: $e');
      throw Exception('Error getting popular places: $e');
    }
  }

  // Legacy methods for backward compatibility (now use Cloud Functions)
  static Future<List<Place>> searchPlaces(String query) async {
    return searchDestinations(query);
  }
}
