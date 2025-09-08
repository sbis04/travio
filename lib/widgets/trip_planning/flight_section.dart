import 'dart:math';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:travio/models/document.dart';

class FlightSection extends StatefulWidget {
  const FlightSection({
    super.key,
    required this.flightInfo,
  });

  final List<FlightInformation> flightInfo;

  @override
  State<FlightSection> createState() => _FlightSectionState();
}

class _FlightSectionState extends State<FlightSection> {
  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: widget.flightInfo.length,
      separatorBuilder: (_, __) => const SizedBox(height: 16),
      itemBuilder: (_, index) {
        final flightInfo = widget.flightInfo[index];
        return _FlightInfoDisplay(flightInfo: flightInfo);
      },
    );
  }
}

/// Individual flight display matching the perfected mockup design
class _FlightInfoDisplay extends StatelessWidget {
  const _FlightInfoDisplay({
    required this.flightInfo,
  });

  final FlightInformation flightInfo;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline,
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              children: [
                // Flight header (airline and flight number)
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      flightInfo.airline ?? '',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withValues(alpha: 0.5),
                          ),
                    ),
                    SizedBox(
                      height: 16,
                      child: VerticalDivider(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.3),
                        thickness: 1,
                        width: 16,
                      ),
                    ),
                    if (flightInfo.flightNumber != null)
                      Text(
                        flightInfo.flightNumber!,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withValues(alpha: 0.5),
                            ),
                      ),
                  ],
                ),
                // Flight route with airplane icon
                Row(
                  children: [
                    Text(
                      flightInfo.originCode ?? '',
                      style:
                          Theme.of(context).textTheme.headlineLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                                fontSize: 36,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                    ),
                    Expanded(
                      child: Row(
                        children: [
                          Expanded(
                            child: Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 10),
                              child: Container(
                                width: double.infinity,
                                height: 1,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                          ),
                          Transform.rotate(
                            angle: pi / 2,
                            child: Icon(
                              Icons.flight_rounded,
                              size: 40,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                          Expanded(
                            child: Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 10),
                              child: Container(
                                width: double.infinity,
                                height: 1,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      flightInfo.destinationCode ?? '',
                      style:
                          Theme.of(context).textTheme.headlineLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                                fontSize: 36,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                    ),
                  ],
                ),
                // Origin and destination place names
                Row(
                  children: [
                    // Origin
                    Expanded(
                      child: Text(
                        flightInfo.originPlaceName ?? '',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withValues(alpha: 0.7),
                            ),
                      ),
                    ),
                    // Destination
                    Expanded(
                      child: Text(
                        flightInfo.destinationPlaceName ?? '',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withValues(alpha: 0.7),
                            ),
                        textAlign: TextAlign.end,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
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
                                    color:
                                        Theme.of(context).colorScheme.onSurface,
                                  ),
                            ),
                          if (flightInfo.departureTime != null)
                            Text(
                              _formatDate(flightInfo.departureTime!),
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurface
                                        .withValues(alpha: 0.7),
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
                            Text.rich(
                              TextSpan(
                                children: [
                                  TextSpan(
                                    text: _formatTime(flightInfo.arrivalTime!),
                                  ),
                                  if (_getDaysLater() != null)
                                    TextSpan(
                                      text: '⁺${_getDaysLater()}',
                                      style: TextStyle(
                                        fontWeight: FontWeight.normal,
                                        fontFeatures: [
                                          FontFeature.superscripts()
                                        ],
                                      ),
                                    ),
                                ],
                              ),
                              style: Theme.of(context)
                                  .textTheme
                                  .headlineSmall
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color:
                                        Theme.of(context).colorScheme.onSurface,
                                  ),
                            ),
                          if (flightInfo.arrivalTime != null)
                            Text(
                              _formatDate(flightInfo.arrivalTime!),
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
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
              ],
            ),
          ),

          // Additional flight details
          if (_hasAdditionalDetails()) ...[
            Divider(
              color: Theme.of(context).colorScheme.outline,
              thickness: 1.5,
              height: 1.5,
            ),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(12),
              ),
              child: _buildAdditionalDetails(context),
            ),
          ],
        ],
      ),
    );
  }

  int? _getDaysLater() {
    if (flightInfo.departureTime == null || flightInfo.arrivalTime == null) {
      return null;
    }

    final depDate = flightInfo.departureTime!.toUtc();
    final arrDate = flightInfo.arrivalTime!.toUtc();

    // Extract just the date parts (ignore time)
    final depDateOnly = DateTime(depDate.year, depDate.month, depDate.day);
    final arrDateOnly = DateTime(arrDate.year, arrDate.month, arrDate.day);

    // Calculate the difference in calendar days
    final daysDifference = arrDateOnly.difference(depDateOnly).inDays;

    // Return the number of days later if different calendar day, otherwise null
    return daysDifference > 0 ? daysDifference : null;
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
      'PNR': 'ABC12J',
      // 'PNR': flightInfo.confirmationNumber,
      'Passenger': 'SOUVIK BISWAS',
    };

    final nonEmptyDetails = details.entries
        .where((entry) => entry.value != null && entry.value!.isNotEmpty)
        .toList();

    return Wrap(
      spacing: 16,
      runSpacing: 8,
      alignment: WrapAlignment.spaceBetween,
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
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
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
    return formatter.format(dateTime.toUtc());
  }

  String _formatDate(DateTime dateTime) {
    final formatter = DateFormat('EEE, MMM dd');
    return formatter.format(dateTime.toUtc());
  }
}
