import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:travio/models/airport_place.dart';
import 'package:travio/models/document.dart';
import 'package:travio/services/airport_service.dart';

/// Widget to display extracted flight information in a card format
class FlightInfoCard extends StatelessWidget {
  const FlightInfoCard({
    super.key,
    required this.flightInfo,
    this.isCompact = false,
    this.tripId,
    this.documentId,
    this.showDetailedPlaces = false,
  });

  final FlightInformation flightInfo;
  final bool isCompact;
  final String? tripId;
  final String? documentId;
  final bool showDetailedPlaces;

  @override
  Widget build(BuildContext context) {
    if (isCompact) {
      return _buildCompactView(context);
    }

    // If we should show detailed places and have the required IDs, use FutureBuilder
    if (showDetailedPlaces && tripId != null && documentId != null) {
      return _buildDetailedViewWithPlaces(context);
    }

    return _buildDetailedView(context);
  }

  Widget _buildCompactView(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context)
            .colorScheme
            .primaryContainer
            .withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(
                Icons.flight_takeoff,
                size: 16,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _buildFlightSummary(),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          if (flightInfo.departureTime != null) ...[
            const SizedBox(height: 4),
            Text(
              _formatDateTime(flightInfo.departureTime!),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.7),
                  ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDetailedView(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with flight number and airline
            Row(
              children: [
                Icon(
                  Icons.flight_takeoff,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _buildFlightSummary(),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Flight route
            _buildRouteSection(context),

            const SizedBox(height: 16),

            // Flight times
            if (flightInfo.departureTime != null ||
                flightInfo.arrivalTime != null)
              _buildTimeSection(context),

            const SizedBox(height: 16),

            // Additional details
            _buildDetailsSection(context),
          ],
        ),
      ),
    );
  }

  Widget _buildRouteSection(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'From',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.6),
                    ),
              ),
              Text(
                flightInfo.originCode ?? 'Unknown',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              if (flightInfo.originPlaceName != null)
                Text(
                  flightInfo.originPlaceName!,
                  style: Theme.of(context).textTheme.bodySmall,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Icon(
            Icons.arrow_forward,
            color:
                Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
          ),
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'To',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.6),
                    ),
              ),
              Text(
                flightInfo.destinationCode ?? 'Unknown',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              if (flightInfo.destinationPlaceName != null)
                Text(
                  flightInfo.destinationPlaceName!,
                  style: Theme.of(context).textTheme.bodySmall,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.end,
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTimeSection(BuildContext context) {
    return Row(
      children: [
        if (flightInfo.departureTime != null)
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Departure',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.6),
                      ),
                ),
                Text(
                  _formatDateTime(flightInfo.departureTime!),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                ),
              ],
            ),
          ),
        if (flightInfo.arrivalTime != null)
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'Arrival',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.6),
                      ),
                ),
                Text(
                  _formatDateTime(flightInfo.arrivalTime!),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildDetailsSection(BuildContext context) {
    final details = <String, String?>{
      'Seat': flightInfo.seat,
      'Gate': flightInfo.gate,
      'Terminal': flightInfo.terminal,
      'Class': flightInfo.classOfService,
      'Confirmation': flightInfo.confirmationNumber,
      'Passenger': flightInfo.passengerName,
      'Status': flightInfo.status,
    };

    final nonEmptyDetails = details.entries
        .where((entry) => entry.value != null && entry.value!.isNotEmpty)
        .toList();

    if (nonEmptyDetails.isEmpty) {
      return const SizedBox.shrink();
    }

    return Wrap(
      spacing: 16,
      runSpacing: 8,
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
                  ),
            ),
            Text(
              entry.value!,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
            ),
          ],
        );
      }).toList(),
    );
  }

  String _buildFlightSummary() {
    final parts = <String>[];

    if (flightInfo.airline != null) {
      parts.add(flightInfo.airline!);
    }

    if (flightInfo.flightNumber != null) {
      parts.add(flightInfo.flightNumber!);
    }

    if (parts.isEmpty) {
      return 'Flight Information';
    }

    return parts.join(' ');
  }

  String _formatDateTime(DateTime dateTime) {
    final formatter = DateFormat('MMM dd, yyyy • HH:mm');
    return formatter.format(dateTime);
  }

  Widget _buildDetailedViewWithPlaces(BuildContext context) {
    return FutureBuilder<({AirportPlace? origin, AirportPlace? destination})>(
      future: AirportService.getFlightPlaces(
        tripId: tripId!,
        documentId: documentId!,
      ),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildFlightHeader(context),
                  const SizedBox(height: 16),
                  const Center(child: CircularProgressIndicator()),
                ],
              ),
            ),
          );
        }

        final places = snapshot.data;
        return _buildDetailedViewWithPlaceData(context, places);
      },
    );
  }

  Widget _buildDetailedViewWithPlaceData(
    BuildContext context,
    ({AirportPlace? origin, AirportPlace? destination})? places,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with flight number and airline
            _buildFlightHeader(context),

            const SizedBox(height: 16),

            // Enhanced flight route with detailed place info
            _buildEnhancedRouteSection(context, places),

            const SizedBox(height: 16),

            // Flight times
            if (flightInfo.departureTime != null ||
                flightInfo.arrivalTime != null)
              _buildTimeSection(context),

            const SizedBox(height: 16),

            // Additional details
            _buildDetailsSection(context),
          ],
        ),
      ),
    );
  }

  Widget _buildFlightHeader(BuildContext context) {
    return Row(
      children: [
        Icon(
          Icons.flight_takeoff,
          color: Theme.of(context).colorScheme.primary,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            _buildFlightSummary(),
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.primary,
                ),
          ),
        ),
      ],
    );
  }

  Widget _buildEnhancedRouteSection(
    BuildContext context,
    ({AirportPlace? origin, AirportPlace? destination})? places,
  ) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'From',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.6),
                    ),
              ),
              Text(
                flightInfo.originCode ?? 'Unknown',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              // Use detailed place info if available, otherwise use flight info
              Text(
                places?.origin?.name ?? flightInfo.originPlaceName ?? 'Airport',
                style: Theme.of(context).textTheme.bodySmall,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              if (places?.origin?.formattedAddress != null)
                Text(
                  places!.origin!.formattedAddress!,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.5),
                      ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Icon(
            Icons.arrow_forward,
            color:
                Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
          ),
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'To',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.6),
                    ),
              ),
              Text(
                flightInfo.destinationCode ?? 'Unknown',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              // Use detailed place info if available, otherwise use flight info
              Text(
                places?.destination?.name ??
                    flightInfo.destinationPlaceName ??
                    'Airport',
                style: Theme.of(context).textTheme.bodySmall,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.end,
              ),
              if (places?.destination?.formattedAddress != null)
                Text(
                  places!.destination!.formattedAddress!,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.5),
                      ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.end,
                ),
            ],
          ),
        ),
      ],
    );
  }
}
