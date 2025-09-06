import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:travio/services/places_service.dart';
import 'package:travio/utils/utils.dart';

/// Service for caching place photos to reduce expensive Places API calls
class PlacePhotoCacheService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _placeCacheCollection = 'place_cache';

  /// Get place photos using cache-first approach
  static Future<List<String>> getPlacePhotos({
    required String placeId,
    int maxPhotos = 20,
    int maxWidth = 800,
  }) async {
    try {
      logPrint('📸 Getting place photos for: $placeId (cache-first)');

      // First, try to get from cache
      final cachedPhotos = await _getCachedPhotos(placeId, maxWidth);
      if (cachedPhotos.isNotEmpty) {
        logPrint(
            '📸 -> ✅ Found ${cachedPhotos.length} cached photos for: $placeId');
        return cachedPhotos.take(maxPhotos).toList();
      }

      // Cache miss - fetch from Places API
      logPrint('📸 -> 📡 Cache miss, fetching from Places API for: $placeId');
      final apiPhotos = await PlacesService.getPlacePhotosFromAPI(
        placeId: placeId,
        maxPhotos: maxPhotos,
        maxWidth: maxWidth,
      );

      // Cache the results for future use
      if (apiPhotos.isNotEmpty) {
        await _cachePhotos(placeId, apiPhotos, maxWidth);
        logPrint('📸 -> 💾 Cached ${apiPhotos.length} photos for future use');
      }

      return apiPhotos;
    } catch (e) {
      logPrint('📸 -> ❌ Error in getPlacePhotos cache service: $e');
      rethrow;
    }
  }

  /// Get cached photos from Firestore
  static Future<List<String>> _getCachedPhotos(
      String placeId, int maxWidth) async {
    try {
      // Query for cache entries with this placeId and maxWidth
      final cacheQuery = await _firestore
          .collection(_placeCacheCollection)
          .where('place_id', isEqualTo: placeId)
          .where('max_width', isEqualTo: maxWidth)
          .limit(1)
          .get();

      if (cacheQuery.docs.isEmpty) {
        logPrint(
            '📸 -> No cache entry found for place: $placeId (width: $maxWidth)');
        return [];
      }

      final cacheDoc = cacheQuery.docs.first;
      final cacheData = cacheDoc.data();
      final cachedAt = (cacheData['cached_at'] as Timestamp).toDate();
      final now = DateTime.now();

      // Check if cache is still valid (30 days for photos)
      const cacheValidityDays = 30;
      if (now.difference(cachedAt).inDays > cacheValidityDays) {
        logPrint(
            '📸 -> Photo cache expired for place: $placeId (${now.difference(cachedAt).inDays} days old)');
        // Delete expired cache
        await _deleteCachedPhotos(cacheDoc.id);
        return [];
      }

      final photoUrls = List<String>.from(cacheData['photo_urls'] ?? []);
      logPrint('📸 -> ✅ Retrieved ${photoUrls.length} photos from cache');
      return photoUrls;
    } catch (e) {
      logPrint('📸 -> ❌ Error getting cached photos: $e');
      return [];
    }
  }

  /// Cache photos in Firestore for future use
  static Future<void> _cachePhotos(
      String placeId, List<String> photoUrls, int maxWidth) async {
    try {
      logPrint(
          '📸 -> 💾 Caching ${photoUrls.length} photos for: $placeId (width: $maxWidth)');

      // Use auto-generated document ID for the cache entry
      await _firestore.collection(_placeCacheCollection).add({
        'place_id': placeId,
        'photo_urls': photoUrls,
        'max_width': maxWidth,
        'photo_count': photoUrls.length,
        'cached_at': FieldValue.serverTimestamp(),
        'last_accessed': FieldValue.serverTimestamp(),
        'access_count': 1,
      });

      logPrint('📸 -> ✅ Successfully cached ${photoUrls.length} photos');
    } catch (e) {
      logPrint('📸 -> ❌ Error caching photos: $e');
      // Don't rethrow - caching failure shouldn't break the flow
    }
  }

  /// Delete cached photos (when expired)
  static Future<void> _deleteCachedPhotos(String cacheDocId) async {
    try {
      logPrint('📸 -> 🗑️ Deleting expired photo cache: $cacheDocId');

      await _firestore
          .collection(_placeCacheCollection)
          .doc(cacheDocId)
          .delete();

      logPrint('📸 -> ✅ Deleted expired photo cache');
    } catch (e) {
      logPrint('📸 -> ❌ Error deleting cached photos: $e');
    }
  }

  /// Get cache statistics for a specific place
  static Future<Map<String, dynamic>> getCacheStats(String placeId) async {
    try {
      final cacheQuery = await _firestore
          .collection(_placeCacheCollection)
          .where('place_id', isEqualTo: placeId)
          .get();

      if (cacheQuery.docs.isEmpty) {
        return {
          'cached': false,
          'cache_entries': 0,
          'total_photos': 0,
        };
      }

      int totalPhotos = 0;
      int totalAccess = 0;
      DateTime? oldestCache;
      DateTime? newestCache;

      for (final doc in cacheQuery.docs) {
        final data = doc.data();
        totalPhotos += (data['photo_count'] as int? ?? 0);
        totalAccess += (data['access_count'] as int? ?? 0);

        final cachedAt = (data['cached_at'] as Timestamp).toDate();
        if (oldestCache == null || cachedAt.isBefore(oldestCache)) {
          oldestCache = cachedAt;
        }
        if (newestCache == null || cachedAt.isAfter(newestCache)) {
          newestCache = cachedAt;
        }
      }

      return {
        'cached': true,
        'cache_entries': cacheQuery.docs.length,
        'total_photos': totalPhotos,
        'total_access': totalAccess,
        'oldest_cache': oldestCache?.toIso8601String(),
        'newest_cache': newestCache?.toIso8601String(),
        'oldest_age_days': oldestCache != null
            ? DateTime.now().difference(oldestCache).inDays
            : null,
      };
    } catch (e) {
      logPrint('📸 -> ❌ Error getting photo cache stats: $e');
      return {'error': e.toString()};
    }
  }

  /// Manually refresh cache for a place (useful for admin/testing)
  static Future<List<String>> refreshPhotoCache({
    required String placeId,
    int maxPhotos = 20,
    int maxWidth = 800,
  }) async {
    try {
      logPrint('📸 -> Force refreshing photo cache for: $placeId');

      // Delete existing cache entries for this place and width
      await _clearCacheForPlace(placeId, maxWidth);

      // Fetch fresh data from API
      final apiPhotos = await PlacesService.getPlacePhotosFromAPI(
        placeId: placeId,
        maxPhotos: maxPhotos,
        maxWidth: maxWidth,
      );

      // Cache the fresh data
      if (apiPhotos.isNotEmpty) {
        await _cachePhotos(placeId, apiPhotos, maxWidth);
      }

      return apiPhotos;
    } catch (e) {
      logPrint('📸 -> ❌ Error refreshing photo cache: $e');
      rethrow;
    }
  }

  /// Clear cache entries for a specific place and width
  static Future<void> _clearCacheForPlace(String placeId, int maxWidth) async {
    try {
      final cacheQuery = await _firestore
          .collection(_placeCacheCollection)
          .where('place_id', isEqualTo: placeId)
          .where('max_width', isEqualTo: maxWidth)
          .get();

      final batch = _firestore.batch();
      for (final doc in cacheQuery.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
      logPrint('📸 -> ✅ Cleared cache entries for place: $placeId');
    } catch (e) {
      logPrint('📸 -> ❌ Error clearing cache for place: $e');
    }
  }

  /// Clear all expired photo cache entries (maintenance function)
  static Future<int> clearExpiredCache() async {
    try {
      logPrint('📸 -> 🗑️ Clearing expired photo cache entries...');

      final now = DateTime.now();
      const cacheValidityDays = 30;
      final expiredThreshold = now.subtract(Duration(days: cacheValidityDays));

      final expiredQuery = await _firestore
          .collection(_placeCacheCollection)
          .where('cached_at', isLessThan: Timestamp.fromDate(expiredThreshold))
          .get();

      if (expiredQuery.docs.isEmpty) {
        logPrint('📸 -> ✅ No expired cache entries found');
        return 0;
      }

      final batch = _firestore.batch();
      for (final doc in expiredQuery.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
      logPrint(
          '📸 -> ✅ Cleared ${expiredQuery.docs.length} expired cache entries');
      return expiredQuery.docs.length;
    } catch (e) {
      logPrint('📸 -> ❌ Error clearing expired cache: $e');
      return 0;
    }
  }

  /// Get total cache statistics (for monitoring)
  static Future<Map<String, dynamic>> getTotalCacheStats() async {
    try {
      final allCacheQuery =
          await _firestore.collection(_placeCacheCollection).get();

      int totalEntries = allCacheQuery.docs.length;
      int totalPhotos = 0;
      int totalAccess = 0;
      Set<String> uniquePlaces = {};

      for (final doc in allCacheQuery.docs) {
        final data = doc.data();
        totalPhotos += (data['photo_count'] as int? ?? 0);
        totalAccess += (data['access_count'] as int? ?? 0);
        uniquePlaces.add(data['place_id'] ?? '');
      }

      return {
        'total_cache_entries': totalEntries,
        'unique_places_cached': uniquePlaces.length,
        'total_photos_cached': totalPhotos,
        'total_api_calls_saved': totalAccess - uniquePlaces.length,
        'estimated_cost_savings':
            '\$${((totalAccess - uniquePlaces.length) * 0.004).toStringAsFixed(2)}',
      };
    } catch (e) {
      logPrint('📸 -> ❌ Error getting total cache stats: $e');
      return {'error': e.toString()};
    }
  }

  /// Clear all photo cache (for maintenance)
  static Future<int> clearAllPhotoCache() async {
    try {
      logPrint('📸 -> 🗑️ Clearing all photo cache...');

      final allCacheQuery =
          await _firestore.collection(_placeCacheCollection).get();

      if (allCacheQuery.docs.isEmpty) {
        logPrint('📸 -> ✅ No cache entries to clear');
        return 0;
      }

      final batch = _firestore.batch();
      for (final doc in allCacheQuery.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
      logPrint(
          '📸 -> ✅ Cleared ${allCacheQuery.docs.length} photo cache entries');
      return allCacheQuery.docs.length;
    } catch (e) {
      logPrint('📸 -> ❌ Error clearing all photo cache: $e');
      return 0;
    }
  }
}
