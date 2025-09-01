import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:travio/models/place.dart';
import 'package:travio/models/trip.dart';
import 'package:travio/utils/utils.dart';

class FirestoreService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _tripsCollection = 'trips';
  static const String _visitPlacesSubcollection = 'visit_places';

  // Create a new trip document
  static Future<String?> createTrip({
    required String userUid,
    required Place selectedPlace,
  }) async {
    try {
      logPrint('💾 Creating trip document for ${selectedPlace.name}...');

      // Create trip from place
      final trip = Trip.fromPlace(
        userUid: userUid,
        place: selectedPlace,
      );

      // Add to Firestore
      final docRef =
          await _firestore.collection(_tripsCollection).add(trip.toFirestore());

      logPrint('✅ Trip created successfully: ${docRef.id}');
      logPrint('   Place: ${selectedPlace.name}');
      logPrint('   User: $userUid');
      logPrint('   Document ID: ${docRef.id}');

      return docRef.id;
    } catch (e) {
      logPrint('❌ Error creating trip: $e');
      return null;
    }
  }

  // Get user's trips
  static Future<List<Trip>> getUserTrips(String userUid) async {
    try {
      final querySnapshot = await _firestore
          .collection(_tripsCollection)
          .where('userUid', isEqualTo: userUid)
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs.map((doc) => Trip.fromFirestore(doc)).toList();
    } catch (e) {
      logPrint('❌ Error getting user trips: $e');
      return [];
    }
  }

  // Get a specific trip
  static Future<Trip?> getTrip(String tripId) async {
    try {
      final doc =
          await _firestore.collection(_tripsCollection).doc(tripId).get();

      if (doc.exists) {
        return Trip.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      logPrint('❌ Error getting trip: $e');
      return null;
    }
  }

  // Update trip
  static Future<bool> updateTrip({
    required String tripId,
    required Map<String, dynamic> updates,
  }) async {
    try {
      await _firestore.collection(_tripsCollection).doc(tripId).update({
        ...updates,
        'updated_at': Timestamp.now(),
      });

      logPrint('✅ Trip updated successfully: $tripId');
      return true;
    } catch (e) {
      logPrint('❌ Error updating trip: $e');
      return false;
    }
  }

  // Update trip dates specifically
  static Future<bool> updateTripDates({
    required String tripId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final updates = <String, dynamic>{
        'updated_at': Timestamp.now(),
        'trip_duration': {
          'start_date':
              startDate != null ? Timestamp.fromDate(startDate) : null,
          'end_date': endDate != null ? Timestamp.fromDate(endDate) : null,
        },
      };

      await _firestore.collection(_tripsCollection).doc(tripId).update(updates);

      logPrint('✅ Trip dates updated successfully: $tripId');
      logPrint('   Start: ${startDate?.toString() ?? 'null'}');
      logPrint('   End: ${endDate?.toString() ?? 'null'}');
      return true;
    } catch (e) {
      logPrint('❌ Error updating trip dates: $e');
      return false;
    }
  }

  // Delete trip
  static Future<bool> deleteTrip(String tripId) async {
    try {
      await _firestore.collection(_tripsCollection).doc(tripId).delete();

      logPrint('✅ Trip deleted successfully: $tripId');
      return true;
    } catch (e) {
      logPrint('❌ Error deleting trip: $e');
      return false;
    }
  }

  // Listen to user's trips (real-time)
  static Stream<List<Trip>> watchUserTrips(String userUid) {
    return _firestore
        .collection(_tripsCollection)
        .where('userUid', isEqualTo: userUid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => Trip.fromFirestore(doc)).toList());
  }

  // Get trip statistics
  static Future<Map<String, int>> getTripStats(String userUid) async {
    try {
      final querySnapshot = await _firestore
          .collection(_tripsCollection)
          .where('userUid', isEqualTo: userUid)
          .get();

      final trips =
          querySnapshot.docs.map((doc) => Trip.fromFirestore(doc)).toList();

      return {
        'total': trips.length,
        'planning': trips.where((t) => t.status == TripStatus.planning).length,
        'active': trips.where((t) => t.status == TripStatus.active).length,
        'completed':
            trips.where((t) => t.status == TripStatus.completed).length,
      };
    } catch (e) {
      logPrint('❌ Error getting trip stats: $e');
      return {'total': 0, 'planning': 0, 'active': 0, 'completed': 0};
    }
  }

  // ========== VISIT PLACES SUBCOLLECTION METHODS ==========

  // Add a place to visit to the trip
  static Future<bool> addVisitPlace({
    required String tripId,
    required Place place,
  }) async {
    try {
      logPrint('💾 Adding visit place: ${place.name} to trip $tripId');

      // Convert Place to Map for Firestore storage
      final placeData = {
        'place_id': place.placeId,
        'name': place.name,
        'formatted_address': place.formattedAddress ?? place.address,
        'latitude': place.latitude,
        'longitude': place.longitude,
        'rating': place.rating,
        'user_ratings_total': place.userRatingsTotal,
        'types': place.types,
        'photo_urls': place.photoUrls,
        'added_at': Timestamp.now(),
      };

      // Use place_id as document ID to avoid duplicates
      await _firestore
          .collection(_tripsCollection)
          .doc(tripId)
          .collection(_visitPlacesSubcollection)
          .doc(place.placeId)
          .set(placeData);

      logPrint('✅ Visit place added successfully: ${place.name}');
      return true;
    } catch (e) {
      logPrint('❌ Error adding visit place: $e');
      return false;
    }
  }

  // Remove a place to visit from the trip
  static Future<bool> removeVisitPlace({
    required String tripId,
    required String placeId,
  }) async {
    try {
      logPrint('🗑️ Removing visit place: $placeId from trip $tripId');

      await _firestore
          .collection(_tripsCollection)
          .doc(tripId)
          .collection(_visitPlacesSubcollection)
          .doc(placeId)
          .delete();

      logPrint('✅ Visit place removed successfully: $placeId');
      return true;
    } catch (e) {
      logPrint('❌ Error removing visit place: $e');
      return false;
    }
  }

  // Get all visit places for a trip
  static Future<List<Place>> getVisitPlaces(String tripId) async {
    try {
      logPrint('📍 Getting visit places for trip: $tripId');

      final querySnapshot = await _firestore
          .collection(_tripsCollection)
          .doc(tripId)
          .collection(_visitPlacesSubcollection)
          .orderBy('added_at', descending: false)
          .get();

      final places = querySnapshot.docs.map((doc) {
        final data = doc.data();
        return Place(
          placeId: data['place_id'] ?? doc.id,
          name: data['name'] ?? '',
          formattedAddress: data['formatted_address'],
          latitude: data['latitude']?.toDouble(),
          longitude: data['longitude']?.toDouble(),
          rating: data['rating']?.toDouble(),
          userRatingsTotal: data['user_ratings_total']?.toInt(),
          types: List<String>.from(data['types'] ?? []),
          photoUrls: List<String>.from(data['photo_urls'] ?? []),
        );
      }).toList();

      logPrint('✅ Found ${places.length} visit places for trip $tripId');
      return places;
    } catch (e) {
      logPrint('❌ Error getting visit places: $e');
      return [];
    }
  }

  // Check if a place is already in visit places
  static Future<bool> isVisitPlace({
    required String tripId,
    required String placeId,
  }) async {
    try {
      final doc = await _firestore
          .collection(_tripsCollection)
          .doc(tripId)
          .collection(_visitPlacesSubcollection)
          .doc(placeId)
          .get();

      return doc.exists;
    } catch (e) {
      logPrint('❌ Error checking visit place: $e');
      return false;
    }
  }

  // Listen to visit places (real-time)
  static Stream<List<Place>> watchVisitPlaces(String tripId) {
    return _firestore
        .collection(_tripsCollection)
        .doc(tripId)
        .collection(_visitPlacesSubcollection)
        .orderBy('added_at', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) {
              final data = doc.data();
              return Place(
                placeId: data['place_id'] ?? doc.id,
                name: data['name'] ?? '',
                formattedAddress: data['formatted_address'],
                latitude: data['latitude']?.toDouble(),
                longitude: data['longitude']?.toDouble(),
                rating: data['rating']?.toDouble(),
                userRatingsTotal: data['user_ratings_total']?.toInt(),
                types: List<String>.from(data['types'] ?? []),
                photoUrls: List<String>.from(data['photo_urls'] ?? []),
              );
            }).toList());
  }

  // Batch update visit places (replace all)
  static Future<bool> updateVisitPlaces({
    required String tripId,
    required List<Place> places,
  }) async {
    try {
      logPrint('🔄 Batch updating visit places for trip: $tripId');

      final batch = _firestore.batch();
      final visitPlacesRef = _firestore
          .collection(_tripsCollection)
          .doc(tripId)
          .collection(_visitPlacesSubcollection);

      // First, get all existing visit places to delete them
      final existingPlaces = await visitPlacesRef.get();
      for (final doc in existingPlaces.docs) {
        batch.delete(doc.reference);
      }

      // Then, add all new places
      for (final place in places) {
        final placeData = {
          'place_id': place.placeId,
          'name': place.name,
          'formatted_address': place.formattedAddress ?? place.address,
          'latitude': place.latitude,
          'longitude': place.longitude,
          'rating': place.rating,
          'user_ratings_total': place.userRatingsTotal,
          'types': place.types,
          'photo_urls': place.photoUrls,
          'added_at': Timestamp.now(),
        };

        batch.set(visitPlacesRef.doc(place.placeId), placeData);
      }

      await batch.commit();

      logPrint(
          '✅ Batch updated ${places.length} visit places for trip $tripId');
      return true;
    } catch (e) {
      logPrint('❌ Error batch updating visit places: $e');
      return false;
    }
  }
}
