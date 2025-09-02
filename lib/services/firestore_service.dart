import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:travio/models/place.dart';
import 'package:travio/models/trip.dart';
import 'package:travio/models/document.dart';
import 'package:travio/utils/utils.dart';

class FirestoreService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _tripsCollection = 'trips';
  static const String _visitPlacesSubcollection = 'visit_places';
  static const String _documentsSubcollection = 'documents';

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

      // Check if place already exists to prevent duplicates
      final existingPlace =
          await isVisitPlace(tripId: tripId, placeId: place.placeId);
      if (existingPlace) {
        logPrint('⚠️ Visit place already exists: ${place.name}');
        return true; // Return true since the place is already there
      }

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

      // Let Firebase auto-generate document ID
      await _firestore
          .collection(_tripsCollection)
          .doc(tripId)
          .collection(_visitPlacesSubcollection)
          .add(placeData);

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

      // Find the document with matching place_id and delete it
      final querySnapshot = await _firestore
          .collection(_tripsCollection)
          .doc(tripId)
          .collection(_visitPlacesSubcollection)
          .where('place_id', isEqualTo: placeId)
          .get();

      // Delete all matching documents (should typically be just one)
      final batch = _firestore.batch();
      for (final doc in querySnapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();

      logPrint(
          '✅ Visit place removed successfully: $placeId (${querySnapshot.docs.length} docs deleted)');
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
      final querySnapshot = await _firestore
          .collection(_tripsCollection)
          .doc(tripId)
          .collection(_visitPlacesSubcollection)
          .where('place_id', isEqualTo: placeId)
          .limit(1)
          .get();

      return querySnapshot.docs.isNotEmpty;
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

      // Then, add all new places with auto-generated IDs
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

        // Use auto-generated document ID
        final newDocRef = visitPlacesRef.doc();
        batch.set(newDocRef, placeData);
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

  // ========== DOCUMENTS SUBCOLLECTION METHODS ==========

  // Add a document to the trip
  static Future<String?> addDocument({
    required String tripId,
    required TripDocument document,
  }) async {
    try {
      logPrint('📄 Adding document: ${document.fileName} to trip $tripId');

      final docRef = await _firestore
          .collection(_tripsCollection)
          .doc(tripId)
          .collection(_documentsSubcollection)
          .add(document.toFirestore());

      logPrint(
          '✅ Document added successfully: ${document.fileName} (${docRef.id})');
      return docRef.id;
    } catch (e) {
      logPrint('❌ Error adding document: $e');
      return null;
    }
  }

  // Remove a document from the trip
  static Future<bool> removeDocument({
    required String tripId,
    required String documentId,
  }) async {
    try {
      logPrint('🗑️ Removing document: $documentId from trip $tripId');

      await _firestore
          .collection(_tripsCollection)
          .doc(tripId)
          .collection(_documentsSubcollection)
          .doc(documentId)
          .delete();

      logPrint('✅ Document removed successfully: $documentId');
      return true;
    } catch (e) {
      logPrint('❌ Error removing document: $e');
      return false;
    }
  }

  // Get all documents for a trip
  static Future<List<TripDocument>> getDocuments(String tripId) async {
    try {
      logPrint('📄 Getting documents for trip: $tripId');

      final querySnapshot = await _firestore
          .collection(_tripsCollection)
          .doc(tripId)
          .collection(_documentsSubcollection)
          .orderBy('uploaded_at', descending: true)
          .get();

      final documents = querySnapshot.docs
          .map((doc) => TripDocument.fromFirestore(doc))
          .toList();

      logPrint('✅ Found ${documents.length} documents for trip $tripId');
      return documents;
    } catch (e) {
      logPrint('❌ Error getting documents: $e');
      return [];
    }
  }

  // Get a specific document
  static Future<TripDocument?> getDocument({
    required String tripId,
    required String documentId,
  }) async {
    try {
      final doc = await _firestore
          .collection(_tripsCollection)
          .doc(tripId)
          .collection(_documentsSubcollection)
          .doc(documentId)
          .get();

      if (doc.exists) {
        return TripDocument.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      logPrint('❌ Error getting document: $e');
      return null;
    }
  }

  // Update document metadata
  static Future<bool> updateDocument({
    required String tripId,
    required String documentId,
    required Map<String, dynamic> updates,
  }) async {
    try {
      await _firestore
          .collection(_tripsCollection)
          .doc(tripId)
          .collection(_documentsSubcollection)
          .doc(documentId)
          .update(updates);

      logPrint('✅ Document updated successfully: $documentId');
      return true;
    } catch (e) {
      logPrint('❌ Error updating document: $e');
      return false;
    }
  }

  // Listen to documents (real-time)
  static Stream<List<TripDocument>> watchDocuments(String tripId) {
    return _firestore
        .collection(_tripsCollection)
        .doc(tripId)
        .collection(_documentsSubcollection)
        .orderBy('uploaded_at', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => TripDocument.fromFirestore(doc))
            .toList());
  }

  // Get documents by type
  static Future<List<TripDocument>> getDocumentsByType({
    required String tripId,
    required DocumentType type,
  }) async {
    try {
      logPrint('📄 Getting ${type.name} documents for trip: $tripId');

      final querySnapshot = await _firestore
          .collection(_tripsCollection)
          .doc(tripId)
          .collection(_documentsSubcollection)
          .where('type', isEqualTo: type.name)
          .orderBy('uploaded_at', descending: true)
          .get();

      final documents = querySnapshot.docs
          .map((doc) => TripDocument.fromFirestore(doc))
          .toList();

      logPrint('✅ Found ${documents.length} ${type.name} documents');
      return documents;
    } catch (e) {
      logPrint('❌ Error getting documents by type: $e');
      return [];
    }
  }

  // Get document count for a trip
  static Future<int> getDocumentCount(String tripId) async {
    try {
      final querySnapshot = await _firestore
          .collection(_tripsCollection)
          .doc(tripId)
          .collection(_documentsSubcollection)
          .count()
          .get();

      return querySnapshot.count ?? 0;
    } catch (e) {
      logPrint('❌ Error getting document count: $e');
      return 0;
    }
  }
}
