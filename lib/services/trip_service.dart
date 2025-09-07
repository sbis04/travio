import 'package:firebase_auth/firebase_auth.dart';
import 'package:travio/models/place.dart';
import 'package:travio/models/trip.dart';
import 'package:travio/services/auth_service.dart';
import 'package:travio/services/firestore_service.dart';
import 'package:travio/utils/utils.dart';

class TripService {
  // Complete flow: Ensure user auth + Create trip + Return trip ID
  static Future<String?> createTripWithPlace(Place selectedPlace) async {
    try {
      logPrint('🚀 Starting trip creation flow for ${selectedPlace.name}...');

      // Step 1: Ensure user is authenticated (anonymous or otherwise)
      User? user = AuthService.currentUser;

      if (user == null) {
        // No user signed in - sign in anonymously
        logPrint('👤 No user signed in, creating anonymous user...');
        user = await AuthService.signInAnonymously();
        if (user == null) {
          logPrint('❌ Failed to sign in anonymously');
          return null;
        }
      } else {
        logPrint(
            '👤 Using existing user: ${user.uid} (anonymous: ${user.isAnonymous})');
      }

      // Step 2: Create trip document
      // Set as public if user is anonymous, private if authenticated
      final isPublic = user.isAnonymous;

      final tripId = await FirestoreService.createTrip(
        userUid: user.uid,
        selectedPlace: selectedPlace,
        isPublic: isPublic,
      );

      if (tripId != null) {
        logPrint('🎉 Trip creation flow completed successfully!');
        logPrint('   Trip ID: $tripId');
        logPrint('   User UID: ${user.uid}');
        logPrint(
            '   User Type: ${user.isAnonymous ? 'Anonymous' : 'Authenticated'}');
        logPrint('   Trip Visibility: ${isPublic ? 'Public' : 'Private'}');
        logPrint('   Destination: ${selectedPlace.name}');

        // Log user info for debugging
        AuthService.logUserInfo();

        return tripId;
      } else {
        logPrint('❌ Failed to create trip document');
        return null;
      }
    } catch (e) {
      logPrint('❌ Error in trip creation flow: $e');
      return null;
    }
  }

  // Get current user's trips
  static Future<List<Trip>> getCurrentUserTrips() async {
    final userUid = AuthService.currentUserUid;
    if (userUid == null) {
      logPrint('❌ No user signed in');
      return [];
    }

    return await FirestoreService.getUserTrips(userUid);
  }

  // Get specific trip
  static Future<Trip?> getTrip(String tripId) async {
    return await FirestoreService.getTrip(tripId);
  }

  // Update trip
  static Future<bool> updateTrip({
    required String tripId,
    required Map<String, dynamic> updates,
  }) async {
    return await FirestoreService.updateTrip(
      tripId: tripId,
      updates: updates,
    );
  }

  // Update trip dates
  static Future<bool> updateTripDates({
    required String tripId,
    DateTime? startDate,
    DateTime? endDate,
  }) =>
      FirestoreService.updateTripDates(
        tripId: tripId,
        startDate: startDate,
        endDate: endDate,
      );

  // Delete trip
  static Future<bool> deleteTrip(String tripId) async {
    return await FirestoreService.deleteTrip(tripId);
  }

  // Get trip statistics for current user
  static Future<Map<String, int>> getCurrentUserTripStats() async {
    final userUid = AuthService.currentUserUid;
    if (userUid == null) {
      return {'total': 0, 'planning': 0, 'active': 0, 'completed': 0};
    }

    return await FirestoreService.getTripStats(userUid);
  }

  // Watch current user's trips (real-time)
  static Stream<List<Trip>> watchCurrentUserTrips() {
    final userUid = AuthService.currentUserUid;
    if (userUid == null) {
      return Stream.value([]);
    }

    return FirestoreService.watchUserTrips(userUid);
  }

  // ========== VISIT PLACES MANAGEMENT ==========

  // Add a place to visit to the trip
  static Future<bool> addVisitPlace({
    required String tripId,
    required Place place,
  }) async {
    return await FirestoreService.addVisitPlace(
      tripId: tripId,
      place: place,
    );
  }

  // Remove a place to visit from the trip
  static Future<bool> removeVisitPlace({
    required String tripId,
    required String placeId,
  }) async {
    return await FirestoreService.removeVisitPlace(
      tripId: tripId,
      placeId: placeId,
    );
  }

  // Get all visit places for a trip
  static Future<List<Place>> getVisitPlaces(String tripId) async {
    return await FirestoreService.getVisitPlaces(tripId);
  }

  // Check if a place is already in visit places
  static Future<bool> isVisitPlace({
    required String tripId,
    required String placeId,
  }) async {
    return await FirestoreService.isVisitPlace(
      tripId: tripId,
      placeId: placeId,
    );
  }

  // Listen to visit places (real-time)
  static Stream<List<Place>> watchVisitPlaces(String tripId) {
    return FirestoreService.watchVisitPlaces(tripId);
  }

  // Batch update visit places (optimized for UI state changes)
  static Future<bool> updateVisitPlaces({
    required String tripId,
    required List<Place> places,
  }) async {
    return await FirestoreService.updateVisitPlaces(
      tripId: tripId,
      places: places,
    );
  }

  // Handle individual place selection/deselection efficiently
  static Future<bool> toggleVisitPlace({
    required String tripId,
    required Place place,
    required bool isSelected,
  }) async {
    if (isSelected) {
      return await addVisitPlace(tripId: tripId, place: place);
    } else {
      return await removeVisitPlace(tripId: tripId, placeId: place.placeId);
    }
  }

  // ========== TRIP OWNERSHIP MANAGEMENT ==========

  // Link trip to authenticated user (convert from anonymous to authenticated)
  static Future<bool> linkTripToCurrentUser(String tripId) async {
    try {
      final currentUser = AuthService.currentUser;
      if (currentUser == null) {
        logPrint('❌ No user signed in to link trip to');
        return false;
      }

      if (currentUser.isAnonymous) {
        logPrint('❌ Cannot link trip to anonymous user');
        return false;
      }

      logPrint(
          '🔗 Linking trip $tripId to current authenticated user: ${currentUser.uid}');

      return await FirestoreService.linkTripToUser(
        tripId: tripId,
        newUserUid: currentUser.uid,
      );
    } catch (e) {
      logPrint('❌ Error linking trip to current user: $e');
      return false;
    }
  }

  // Link trip to specific user with ownership verification
  static Future<bool> linkTripToUser({
    required String tripId,
    required String newUserUid,
    String? oldUserUid,
  }) async {
    return await FirestoreService.linkTripToUser(
      tripId: tripId,
      newUserUid: newUserUid,
      oldUserUid: oldUserUid,
    );
  }
}
