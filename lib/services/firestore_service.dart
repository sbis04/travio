import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:travio/models/place.dart';
import 'package:travio/models/trip.dart';
import 'package:travio/utils/utils.dart';

class FirestoreService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _tripsCollection = 'trips';

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
        'updatedAt': Timestamp.now(),
      });

      logPrint('✅ Trip updated successfully: $tripId');
      return true;
    } catch (e) {
      logPrint('❌ Error updating trip: $e');
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
}
