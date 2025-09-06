import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:travio/models/document.dart';
import 'package:travio/services/document_service.dart';
import 'package:travio/utils/utils.dart';

/// Comprehensive flight details card showing all flights for a trip
class FlightDetailsCard extends StatefulWidget {
  const FlightDetailsCard({
    super.key,
    required this.tripId,
  });

  final String tripId;

  @override
  State<FlightDetailsCard> createState() => _FlightDetailsCardState();
}

class _FlightDetailsCardState extends State<FlightDetailsCard> {
  List<TripDocument> _flightDocuments = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFlightDocuments();
  }

  Future<void> _loadFlightDocuments() async {
    try {
      logPrint('✈️ Loading flight documents for trip: ${widget.tripId}');

      final documents = await DocumentService.getDocumentsByType(
        tripId: widget.tripId,
        type: DocumentType.flight,
      );

      if (mounted) {
        setState(() {
          _flightDocuments = documents;
          _isLoading = false;
        });
        logPrint('✅ Loaded ${documents.length} flight document(s)');
      }
    } catch (e) {
      logPrint('❌ Error loading flight documents: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Icon(
                Icons.flight_takeoff,
                color: Theme.of(context).colorScheme.primary,
                size: 28,
              ),
              const SizedBox(width: 12),
              Text(
                'Flight Details',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.primary,
                    ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Content
          if (_isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(32.0),
                child: CircularProgressIndicator(),
              ),
            )
          else if (_flightDocuments.isEmpty)
            _buildEmptyState(context)
          else
            _buildFlightsList(context),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.flight_takeoff,
              size: 48,
              color: Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'No flight documents uploaded yet',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.7),
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Upload boarding passes or flight tickets to see details here',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.5),
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFlightsList(BuildContext context) {
    return Column(
      children: _flightDocuments.asMap().entries.map((entry) {
        final index = entry.key;
        final document = entry.value;

        return Column(
          children: [
            if (index > 0) const SizedBox(height: 24),
            _FlightDocumentCard(
              document: document,
              tripId: widget.tripId,
            ),
          ],
        );
      }).toList(),
    );
  }
}

/// Card for individual flight document with all its flights
class _FlightDocumentCard extends StatelessWidget {
  const _FlightDocumentCard({
    required this.document,
    required this.tripId,
  });

  final TripDocument document;
  final String tripId;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Document header
            Row(
              children: [
                Icon(
                  Icons.description,
                  size: 20,
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.7),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    document.originalFileName,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    document.typeDisplayName,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color:
                              Theme.of(context).colorScheme.onPrimaryContainer,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Flights from subcollection
            _FlightInfoSubcollectionLoader(
              tripId: tripId,
              documentId: document.id,
            ),
          ],
        ),
      ),
    );
  }
}

/// Loads and displays flights from the flight_info subcollection
class _FlightInfoSubcollectionLoader extends StatefulWidget {
  const _FlightInfoSubcollectionLoader({
    required this.tripId,
    required this.documentId,
  });

  final String tripId;
  final String documentId;

  @override
  State<_FlightInfoSubcollectionLoader> createState() =>
      _FlightInfoSubcollectionLoaderState();
}

class _FlightInfoSubcollectionLoaderState
    extends State<_FlightInfoSubcollectionLoader> {
  List<({String flightId, FlightInformation flightInfo})> _flights = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFlights();
  }

  Future<void> _loadFlights() async {
    try {
      logPrint('🛫 Loading flights for document: ${widget.documentId}');

      // Get all flight documents from subcollection
      final flightCollection = await DocumentService.firestore
          .collection('trips')
          .doc(widget.tripId)
          .collection('documents')
          .doc(widget.documentId)
          .collection('flight_info')
          .orderBy('flight_index')
          .get();

      final flights = <({String flightId, FlightInformation flightInfo})>[];

      for (final doc in flightCollection.docs) {
        try {
          final flightInfo = FlightInformation.fromFirestore(doc.data());
          flights.add((flightId: doc.id, flightInfo: flightInfo));
        } catch (e) {
          logPrint('⚠️ Error parsing flight ${doc.id}: $e');
        }
      }

      if (mounted) {
        setState(() {
          _flights = flights;
          _isLoading = false;
        });
        logPrint('✅ Loaded ${flights.length} flight(s)');
      }
    } catch (e) {
      logPrint('❌ Error loading flights: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(20.0),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_flights.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(20.0),
        child: Text(
          'Flight information is being processed...',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.6),
              ),
        ),
      );
    }

    return Column(
      children: _flights.asMap().entries.map((entry) {
        final index = entry.key;
        final flight = entry.value;

        return Column(
          children: [
            if (index > 0) ...[
              const SizedBox(height: 16),
              Divider(
                  color: Theme.of(context)
                      .colorScheme
                      .outline
                      .withValues(alpha: 0.3)),
              const SizedBox(height: 16),
            ],
            _FlightCard(
              flightInfo: flight.flightInfo,
              flightId: flight.flightId,
              tripId: widget.tripId,
              documentId: widget.documentId,
              flightIndex: index,
            ),
          ],
        );
      }).toList(),
    );
  }
}

/// Individual flight card matching the mockup design
class _FlightCard extends StatelessWidget {
  const _FlightCard({
    required this.flightInfo,
    required this.flightId,
    required this.tripId,
    required this.documentId,
    required this.flightIndex,
  });

  final FlightInformation flightInfo;
  final String flightId;
  final String tripId;
  final String documentId;
  final int flightIndex;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
          width: 1.5,
        ),
      ),
      child: Column(
        children: [
          // Flight header (airline and flight number)
          Row(
            children: [
              Text(
                flightInfo.airline ?? 'Airline',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: Colors.green, // Matching mockup color
                    ),
              ),
              const Spacer(),
              if (flightInfo.flightNumber != null)
                Text(
                  flightInfo.flightNumber!,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: Colors.green, // Matching mockup color
                      ),
                ),
            ],
          ),

          const SizedBox(height: 20),

          // Flight route with airplane icon
          Row(
            children: [
              // Origin
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      flightInfo.originCode ?? 'CCU',
                      style:
                          Theme.of(context).textTheme.headlineMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Airport name', // Will be populated from subcollection
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withValues(alpha: 0.7),
                          ),
                    ),
                  ],
                ),
              ),

              // Airplane icon
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Icon(
                  Icons.flight_takeoff,
                  size: 32,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),

              // Destination
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      flightInfo.destinationCode ?? 'BLR',
                      style:
                          Theme.of(context).textTheme.headlineMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Airport Name', // Will be populated from subcollection
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withValues(alpha: 0.7),
                          ),
                      textAlign: TextAlign.end,
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Flight times
          Row(
            children: [
              // Departure time
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (flightInfo.departureTime != null)
                      Text(
                        _formatTime(flightInfo.departureTime!),
                        style: Theme.of(context)
                            .textTheme
                            .headlineSmall
                            ?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                      ),
                    const SizedBox(height: 4),
                    if (flightInfo.departureTime != null)
                      Text(
                        _formatDate(flightInfo.departureTime!),
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withValues(alpha: 0.7),
                            ),
                      ),
                  ],
                ),
              ),

              // Next day indicator (if applicable)
              if (_isNextDay())
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '+1',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.green,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        Icons.arrow_forward,
                        size: 16,
                        color: Colors.green,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Next day',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.green,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ],
                  ),
                ),

              // Arrival time
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if (flightInfo.arrivalTime != null)
                      Text(
                        _formatTime(flightInfo.arrivalTime!),
                        style: Theme.of(context)
                            .textTheme
                            .headlineSmall
                            ?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                      ),
                    const SizedBox(height: 4),
                    if (flightInfo.arrivalTime != null)
                      Text(
                        _formatDate(flightInfo.arrivalTime!),
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withValues(alpha: 0.7),
                            ),
                        textAlign: TextAlign.end,
                      ),
                  ],
                ),
              ),
            ],
          ),

          // Additional flight details
          if (_hasAdditionalDetails()) ...[
            const SizedBox(height: 20),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
              ),
              child: _buildAdditionalDetails(context),
            ),
          ],
        ],
      ),
    );
  }

  bool _isNextDay() {
    if (flightInfo.departureTime == null || flightInfo.arrivalTime == null) {
      return false;
    }

    final depDate = flightInfo.departureTime!;
    final arrDate = flightInfo.arrivalTime!;

    return arrDate.day != depDate.day || arrDate.month != depDate.month;
  }

  bool _hasAdditionalDetails() {
    return flightInfo.seat != null ||
        flightInfo.gate != null ||
        flightInfo.terminal != null ||
        flightInfo.confirmationNumber != null ||
        flightInfo.passengerName != null ||
        flightInfo.classOfService != null;
  }

  Widget _buildAdditionalDetails(BuildContext context) {
    final details = <String, String?>{
      'Seat': flightInfo.seat,
      'Gate': flightInfo.gate,
      'Terminal': flightInfo.terminal,
      'Class': flightInfo.classOfService,
      'PNR': flightInfo.confirmationNumber,
      'Passenger': flightInfo.passengerName,
    };

    final nonEmptyDetails = details.entries
        .where((entry) => entry.value != null && entry.value!.isNotEmpty)
        .toList();

    return Wrap(
      spacing: 20,
      runSpacing: 12,
      children: nonEmptyDetails.map((entry) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              entry.key,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.6),
                    fontWeight: FontWeight.w500,
                  ),
            ),
            const SizedBox(height: 2),
            Text(
              entry.value!,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ],
        );
      }).toList(),
    );
  }

  String _formatTime(DateTime dateTime) {
    final formatter = DateFormat('h:mm a');
    return formatter.format(dateTime);
  }

  String _formatDate(DateTime dateTime) {
    final formatter = DateFormat('EEE, MMM dd');
    return formatter.format(dateTime);
  }
}
