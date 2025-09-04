import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:travio/models/place.dart';
import 'package:travio/services/places_service.dart';
import 'package:travio/utils/utils.dart';

/// Service for caching popular visit places to reduce Places API costs
class VisitPlacesCacheService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _visitPlacesCollection = 'visit_places';
  static const String _placeDetailsSubcollection = 'place_details';

  /// Get popular places for a location, using cache first, then Places API
  static Future<List<Place>> getPopularPlaces({
    required String placeId,
    int maxResults = 20,
  }) async {
    try {
      logPrint('🏛️ Getting popular places for: $placeId (cache-first)');

      // First, try to get from cache
      final cachedPlaces = await _getCachedPlaces(placeId);
      if (cachedPlaces.isNotEmpty) {
        logPrint('✅ Found ${cachedPlaces.length} cached places for: $placeId');
        return cachedPlaces;
      }

      // Cache miss - fetch from Places API
      logPrint('📡 Cache miss, fetching from Places API for: $placeId');
      final apiPlaces = await PlacesService.getPopularPlaces(
        placeId: placeId,
        maxResults: maxResults,
      );

      // Cache the results for future use
      if (apiPlaces.isNotEmpty) {
        await _cachePlaces(placeId, apiPlaces);
        logPrint('💾 Cached ${apiPlaces.length} places for future use');
      }

      return apiPlaces;
    } catch (e) {
      logPrint('❌ Error in getPopularPlaces: $e');
      rethrow;
    }
  }

  /// Get cached places from Firestore
  static Future<List<Place>> _getCachedPlaces(String placeId) async {
    try {
      // Check if we have cached data for this place
      final cacheDoc = await _firestore
          .collection(_visitPlacesCollection)
          .doc(placeId)
          .get();

      if (!cacheDoc.exists) {
        logPrint('🔍 No cache entry found for place: $placeId');
        return [];
      }

      final cacheData = cacheDoc.data()!;
      final cachedAt = (cacheData['cached_at'] as Timestamp).toDate();
      final now = DateTime.now();

      // Check if cache is still valid (7 days)
      const cacheValidityDays = 7;
      if (now.difference(cachedAt).inDays > cacheValidityDays) {
        logPrint(
            '⏰ Cache expired for place: $placeId (${now.difference(cachedAt).inDays} days old)');
        // Optionally delete expired cache
        await _deleteCachedPlaces(placeId);
        return [];
      }

      // Get place details from subcollection
      final placeDetailsSnapshot = await _firestore
          .collection(_visitPlacesCollection)
          .doc(placeId)
          .collection(_placeDetailsSubcollection)
          .get();

      final places = <Place>[];
      for (final doc in placeDetailsSnapshot.docs) {
        try {
          final place = Place.fromFirestore(doc);
          places.add(place);
        } catch (e) {
          logPrint('⚠️ Error parsing cached place ${doc.id}: $e');
          // Continue with other places
        }
      }

      logPrint('✅ Retrieved ${places.length} places from cache');
      return places;
    } catch (e) {
      logPrint('❌ Error getting cached places: $e');
      return [];
    }
  }

  /// Cache places in Firestore for future use
  static Future<void> _cachePlaces(String placeId, List<Place> places) async {
    try {
      logPrint('💾 Caching ${places.length} places for: $placeId');

      final batch = _firestore.batch();

      // Create or update the main cache document
      final cacheDocRef =
          _firestore.collection(_visitPlacesCollection).doc(placeId);

      batch.set(cacheDocRef, {
        'main_place_id': placeId,
        'cached_at': FieldValue.serverTimestamp(),
        'place_count': places.length,
        'last_updated': FieldValue.serverTimestamp(),
      });

      // Add each place to the subcollection
      for (final place in places) {
        final placeDocRef = cacheDocRef
            .collection(_placeDetailsSubcollection)
            .doc(place.placeId); // Use placeId as document ID

        batch.set(placeDocRef, place.toFirestore());
      }

      await batch.commit();
      logPrint('✅ Successfully cached ${places.length} places');
    } catch (e) {
      logPrint('❌ Error caching places: $e');
      // Don't rethrow - caching failure shouldn't break the flow
    }
  }

  /// Delete cached places (when expired or invalid)
  static Future<void> _deleteCachedPlaces(String placeId) async {
    try {
      logPrint('🗑️ Deleting expired cache for: $placeId');

      final batch = _firestore.batch();

      // Get all place details documents
      final placeDetailsSnapshot = await _firestore
          .collection(_visitPlacesCollection)
          .doc(placeId)
          .collection(_placeDetailsSubcollection)
          .get();

      // Delete all place details
      for (final doc in placeDetailsSnapshot.docs) {
        batch.delete(doc.reference);
      }

      // Delete the main cache document
      final cacheDocRef =
          _firestore.collection(_visitPlacesCollection).doc(placeId);
      batch.delete(cacheDocRef);

      await batch.commit();
      logPrint('✅ Deleted expired cache');
    } catch (e) {
      logPrint('❌ Error deleting cached places: $e');
    }
  }

  /// Manually refresh cache for a place (useful for admin/testing)
  static Future<List<Place>> refreshCache({
    required String placeId,
    int maxResults = 20,
  }) async {
    try {
      logPrint('🔄 Force refreshing cache for: $placeId');

      // Delete existing cache
      await _deleteCachedPlaces(placeId);

      // Fetch fresh data from API
      final apiPlaces = await PlacesService.getPopularPlaces(
        placeId: placeId,
        maxResults: maxResults,
      );

      // Cache the fresh data
      if (apiPlaces.isNotEmpty) {
        await _cachePlaces(placeId, apiPlaces);
      }

      return apiPlaces;
    } catch (e) {
      logPrint('❌ Error refreshing cache: $e');
      rethrow;
    }
  }

  /// Get cache statistics (for debugging/monitoring)
  static Future<Map<String, dynamic>> getCacheStats(String placeId) async {
    try {
      final cacheDoc = await _firestore
          .collection(_visitPlacesCollection)
          .doc(placeId)
          .get();

      if (!cacheDoc.exists) {
        return {
          'cached': false,
          'place_count': 0,
          'cached_at': null,
          'age_days': null,
        };
      }

      final data = cacheDoc.data()!;
      final cachedAt = (data['cached_at'] as Timestamp).toDate();
      final ageDays = DateTime.now().difference(cachedAt).inDays;

      return {
        'cached': true,
        'place_count': data['place_count'] ?? 0,
        'cached_at': cachedAt.toIso8601String(),
        'age_days': ageDays,
        'is_expired': ageDays > 7,
      };
    } catch (e) {
      logPrint('❌ Error getting cache stats: $e');
      return {
        'error': e.toString(),
      };
    }
  }

  /// Clear all cached places (useful for maintenance)
  static Future<void> clearAllCache() async {
    try {
      logPrint('🗑️ Clearing all visit places cache...');

      // Get all cache documents
      final cacheSnapshot =
          await _firestore.collection(_visitPlacesCollection).get();

      final batch = _firestore.batch();
      int deletedCount = 0;

      for (final cacheDoc in cacheSnapshot.docs) {
        // Delete subcollection documents
        final placeDetailsSnapshot = await cacheDoc.reference
            .collection(_placeDetailsSubcollection)
            .get();

        for (final placeDoc in placeDetailsSnapshot.docs) {
          batch.delete(placeDoc.reference);
          deletedCount++;
        }

        // Delete main cache document
        batch.delete(cacheDoc.reference);
        deletedCount++;
      }

      await batch.commit();
      logPrint('✅ Cleared cache: $deletedCount documents deleted');
    } catch (e) {
      logPrint('❌ Error clearing cache: $e');
      rethrow;
    }
  }
}
