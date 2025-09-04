import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:travio/models/airport_place.dart';
import 'package:travio/models/document.dart';
import 'package:travio/utils/utils.dart';

/// Service for managing airport/place subcollections in flight documents
class AirportService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Get flight information details from subcollection
  static Future<FlightInformation?> getFlightInfo({
    required String tripId,
    required String documentId,
  }) async {
    try {
      logPrint('✈️ Getting flight info for document: $documentId');

      final doc = await _firestore
          .collection('trips')
          .doc(tripId)
          .collection('documents')
          .doc(documentId)
          .collection('flight_info')
          .doc('details')
          .get();

      if (!doc.exists) {
        logPrint('✈️ No flight info found');
        return null;
      }

      final flightInfo = FlightInformation.fromFirestore(doc.data()!);
      logPrint('✅ Flight info loaded: ${flightInfo.flightNumber}');
      return flightInfo;
    } catch (e) {
      logPrint('❌ Error getting flight info: $e');
      return null;
    }
  }

  /// Get origin place details for a flight document
  static Future<AirportPlace?> getOriginPlace({
    required String tripId,
    required String documentId,
  }) async {
    try {
      logPrint('📍 Getting origin place for document: $documentId');

      final doc = await _firestore
          .collection('trips')
          .doc(tripId)
          .collection('documents')
          .doc(documentId)
          .collection('flight_info')
          .doc('origin_place')
          .get();

      if (!doc.exists) {
        logPrint('📍 No origin place found');
        return null;
      }

      final airportPlace = AirportPlace.fromFirestore(doc);
      logPrint('✅ Origin place loaded: ${airportPlace.name}');
      return airportPlace;
    } catch (e) {
      logPrint('❌ Error getting origin place: $e');
      return null;
    }
  }

  /// Get destination place details for a flight document
  static Future<AirportPlace?> getDestinationPlace({
    required String tripId,
    required String documentId,
  }) async {
    try {
      logPrint('📍 Getting destination place for document: $documentId');

      final doc = await _firestore
          .collection('trips')
          .doc(tripId)
          .collection('documents')
          .doc(documentId)
          .collection('flight_info')
          .doc('destination_place')
          .get();

      if (!doc.exists) {
        logPrint('📍 No destination place found');
        return null;
      }

      final airportPlace = AirportPlace.fromFirestore(doc);
      logPrint('✅ Destination place loaded: ${airportPlace.name}');
      return airportPlace;
    } catch (e) {
      logPrint('❌ Error getting destination place: $e');
      return null;
    }
  }

  /// Get both origin and destination places for a flight document
  static Future<({AirportPlace? origin, AirportPlace? destination})>
      getFlightPlaces({
    required String tripId,
    required String documentId,
  }) async {
    try {
      logPrint('🛫 Getting flight places for document: $documentId');

      // Get both places in parallel
      final results = await Future.wait([
        getOriginPlace(tripId: tripId, documentId: documentId),
        getDestinationPlace(tripId: tripId, documentId: documentId),
      ]);

      final origin = results[0];
      final destination = results[1];

      logPrint(
          '✅ Flight places loaded - Origin: ${origin?.name}, Destination: ${destination?.name}');

      return (origin: origin, destination: destination);
    } catch (e) {
      logPrint('❌ Error getting flight places: $e');
      return (origin: null, destination: null);
    }
  }

  /// Watch for changes to origin place
  static Stream<AirportPlace?> watchOriginPlace({
    required String tripId,
    required String documentId,
  }) {
    return _firestore
        .collection('trips')
        .doc(tripId)
        .collection('documents')
        .doc(documentId)
        .collection('flight_info')
        .doc('origin_place')
        .snapshots()
        .map((doc) {
      if (!doc.exists) return null;
      try {
        return AirportPlace.fromFirestore(doc);
      } catch (e) {
        logPrint('❌ Error parsing origin place: $e');
        return null;
      }
    });
  }

  /// Watch for changes to destination place
  static Stream<AirportPlace?> watchDestinationPlace({
    required String tripId,
    required String documentId,
  }) {
    return _firestore
        .collection('trips')
        .doc(tripId)
        .collection('documents')
        .doc(documentId)
        .collection('flight_info')
        .doc('destination_place')
        .snapshots()
        .map((doc) {
      if (!doc.exists) return null;
      try {
        return AirportPlace.fromFirestore(doc);
      } catch (e) {
        logPrint('❌ Error parsing destination place: $e');
        return null;
      }
    });
  }

  /// Watch for changes to flight information
  static Stream<FlightInformation?> watchFlightInfo({
    required String tripId,
    required String documentId,
  }) {
    return _firestore
        .collection('trips')
        .doc(tripId)
        .collection('documents')
        .doc(documentId)
        .collection('flight_info')
        .doc('details')
        .snapshots()
        .map((doc) {
      if (!doc.exists) return null;
      try {
        return FlightInformation.fromFirestore(doc.data()!);
      } catch (e) {
        logPrint('❌ Error parsing flight info: $e');
        return null;
      }
    });
  }

  /// Watch for changes to both origin and destination places
  static Stream<({AirportPlace? origin, AirportPlace? destination})>
      watchFlightPlaces({
    required String tripId,
    required String documentId,
  }) {
    // Combine both streams
    return watchOriginPlace(tripId: tripId, documentId: documentId)
        .asyncExpand((origin) {
      return watchDestinationPlace(tripId: tripId, documentId: documentId)
          .map((destination) => (origin: origin, destination: destination));
    });
  }

  /// Manually store origin place (for testing/admin purposes)
  static Future<bool> storeOriginPlace({
    required String tripId,
    required String documentId,
    required AirportPlace airportPlace,
  }) async {
    try {
      logPrint('📍 Storing origin place: ${airportPlace.name}');

      await _firestore
          .collection('trips')
          .doc(tripId)
          .collection('documents')
          .doc(documentId)
          .collection('flight_info')
          .doc('origin_place')
          .set(airportPlace.toFirestore());

      logPrint('✅ Origin place stored successfully');
      return true;
    } catch (e) {
      logPrint('❌ Error storing origin place: $e');
      return false;
    }
  }

  /// Manually store destination place (for testing/admin purposes)
  static Future<bool> storeDestinationPlace({
    required String tripId,
    required String documentId,
    required AirportPlace airportPlace,
  }) async {
    try {
      logPrint('📍 Storing destination place: ${airportPlace.name}');

      await _firestore
          .collection('trips')
          .doc(tripId)
          .collection('documents')
          .doc(documentId)
          .collection('flight_info')
          .doc('destination_place')
          .set(airportPlace.toFirestore());

      logPrint('✅ Destination place stored successfully');
      return true;
    } catch (e) {
      logPrint('❌ Error storing destination place: $e');
      return false;
    }
  }

  /// Delete origin place subcollection
  static Future<bool> deleteOriginPlace({
    required String tripId,
    required String documentId,
  }) async {
    try {
      await _firestore
          .collection('trips')
          .doc(tripId)
          .collection('documents')
          .doc(documentId)
          .collection('flight_info')
          .doc('origin_place')
          .delete();

      logPrint('✅ Origin place deleted');
      return true;
    } catch (e) {
      logPrint('❌ Error deleting origin place: $e');
      return false;
    }
  }

  /// Delete destination place subcollection
  static Future<bool> deleteDestinationPlace({
    required String tripId,
    required String documentId,
  }) async {
    try {
      await _firestore
          .collection('trips')
          .doc(tripId)
          .collection('documents')
          .doc(documentId)
          .collection('flight_info')
          .doc('destination_place')
          .delete();

      logPrint('✅ Destination place deleted');
      return true;
    } catch (e) {
      logPrint('❌ Error deleting destination place: $e');
      return false;
    }
  }

  /// Get all flight documents with their places for a trip (for analytics/overview)
  static Future<
      List<
          ({
            String documentId,
            AirportPlace? origin,
            AirportPlace? destination
          })>> getTripFlightPlaces({
    required String tripId,
  }) async {
    try {
      logPrint('🛫 Getting all flight places for trip: $tripId');

      // Get all flight documents
      final documentsSnapshot = await _firestore
          .collection('trips')
          .doc(tripId)
          .collection('documents')
          .where('type', isEqualTo: 'flight')
          .get();

      final results = <({
        String documentId,
        AirportPlace? origin,
        AirportPlace? destination
      })>[];

      for (final doc in documentsSnapshot.docs) {
        final places =
            await getFlightPlaces(tripId: tripId, documentId: doc.id);
        results.add((
          documentId: doc.id,
          origin: places.origin,
          destination: places.destination,
        ));
      }

      logPrint('✅ Retrieved flight places for ${results.length} documents');
      return results;
    } catch (e) {
      logPrint('❌ Error getting trip flight places: $e');
      return [];
    }
  }
}
