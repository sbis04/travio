import 'package:travio/models/place.dart';
import 'package:travio/models/trip.dart';
import 'package:travio/services/auth_service.dart';
import 'package:travio/services/firestore_service.dart';
import 'package:travio/utils/utils.dart';

class TripService {
  // Complete flow: Sign in anonymously + Create trip + Return trip ID
  static Future<String?> createTripWithPlace(Place selectedPlace) async {
    try {
      logPrint('🚀 Starting trip creation flow for ${selectedPlace.name}...');

      // Step 1: Sign in anonymously
      final user = await AuthService.signInAnonymously();
      if (user == null) {
        logPrint('❌ Failed to sign in anonymously');
        return null;
      }

      // Step 2: Create trip document
      final tripId = await FirestoreService.createTrip(
        userUid: user.uid,
        selectedPlace: selectedPlace,
      );

      if (tripId != null) {
        logPrint('🎉 Trip creation flow completed successfully!');
        logPrint('   Trip ID: $tripId');
        logPrint('   User UID: ${user.uid}');
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
}
