import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:travio/models/document.dart';
import 'package:travio/services/document_service.dart';
import 'package:travio/utils/utils.dart';

class FlightSection extends StatefulWidget {
  const FlightSection({
    super.key,
    required this.tripId,
  });

  final String tripId;

  @override
  State<FlightSection> createState() => _FlightSectionState();
}

class _FlightSectionState extends State<FlightSection> {
  List<FlightInformation> _flightInfo = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFlightData();
  }

  Future<void> _loadFlightData() async {
    try {
      logPrint('✈️ Loading flight data for trip: ${widget.tripId}');

      // Get all documents for this trip
      final documents = await DocumentService.getDocuments(widget.tripId);
      final flightDocuments =
          documents.where((doc) => doc.type == DocumentType.flight).toList();

      // Load flight info from subcollections
      await _loadAllFlightInfo(flightDocuments);

      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        logPrint('✅ Loaded ${flightDocuments.length} flight document(s)');
        logPrint('✈️ Total flights: ${_flightInfo.length}');
      }
    } catch (e) {
      logPrint('❌ Error loading flight data: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _loadAllFlightInfo(List<TripDocument> flightDocuments) async {
    try {
      final List<FlightInformation> allFlights = [];

      for (final document in flightDocuments) {
        try {
          final flightCollection = await DocumentService.firestore
              .collection('trips')
              .doc(widget.tripId)
              .collection('documents')
              .doc(document.id)
              .collection('flight_info')
              .orderBy('flight_index')
              .get();

          for (final doc in flightCollection.docs) {
            try {
              final flightInfo = FlightInformation.fromFirestore(doc.data());
              allFlights.add(flightInfo);
            } catch (e) {
              logPrint('⚠️ Error parsing flight ${doc.id}: $e');
            }
          }
        } catch (e) {
          logPrint('❌ Error loading flights from document ${document.id}: $e');
        }
      }

      if (mounted) {
        setState(() => _flightInfo = allFlights);
      }
    } catch (e) {
      logPrint('❌ Error in batch flight info loading: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_flightInfo.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Icon(
              Icons.flight_takeoff_outlined,
              size: 48,
              color: Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withValues(alpha: 0.3),
            ),
            const SizedBox(height: 16),
            Text(
              'No flight information available',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.6),
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Upload flight tickets to see flight details here',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.5),
                  ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        for (int i = 0; i < _flightInfo.length; i++) ...[
          _FlightCard(flight: _flightInfo[i]),
          if (i < _flightInfo.length - 1) const SizedBox(height: 12),
        ],
      ],
    );
  }
}

class _FlightCard extends StatelessWidget {
  const _FlightCard({required this.flight});

  final FlightInformation flight;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Flight header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  flight.flightNumber ?? 'Unknown',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                      ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                flight.airline ?? '',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
              ),
              const Spacer(),
              if (flight.classOfService != null)
                Text(
                  flight.classOfService!,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.7),
                      ),
                ),
            ],
          ),

          const SizedBox(height: 16),

          // Flight route
          Row(
            children: [
              // Origin
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      flight.originCode ?? '',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    if (flight.originPlaceName != null)
                      Text(
                        flight.originPlaceName!,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withValues(alpha: 0.7),
                            ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    if (flight.departureTime != null)
                      Text(
                        _formatTime(flight.departureTime!),
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w500,
                            ),
                      ),
                  ],
                ),
              ),

              // Arrow
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                child: Icon(
                  Icons.arrow_forward,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),

              // Destination
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      flight.destinationCode ?? '',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    if (flight.destinationPlaceName != null)
                      Text(
                        flight.destinationPlaceName!,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withValues(alpha: 0.7),
                            ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.end,
                      ),
                    if (flight.arrivalTime != null)
                      Text(
                        _formatTime(flight.arrivalTime!),
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w500,
                            ),
                      ),
                  ],
                ),
              ),
            ],
          ),

          // Additional details
          if (flight.seat != null ||
              flight.gate != null ||
              flight.terminal != null) ...[
            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 8),
            Wrap(
              spacing: 16,
              runSpacing: 8,
              children: [
                if (flight.seat != null)
                  _DetailChip(
                    icon: Icons.airline_seat_recline_normal,
                    label: 'Seat ${flight.seat}',
                  ),
                if (flight.gate != null)
                  _DetailChip(
                    icon: Icons.door_front_door,
                    label: 'Gate ${flight.gate}',
                  ),
                if (flight.terminal != null)
                  _DetailChip(
                    icon: Icons.business,
                    label: 'Terminal ${flight.terminal}',
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  String _formatTime(DateTime time) {
    return DateFormat('MMM dd, HH:mm').format(time);
  }
}

class _DetailChip extends StatelessWidget {
  const _DetailChip({
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color:
                Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.8),
                ),
          ),
        ],
      ),
    );
  }
}
