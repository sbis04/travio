import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:travio/models/document.dart';

class AccommodationSection extends StatefulWidget {
  const AccommodationSection({
    super.key,
    required this.accommodationInfo,
  });

  final List<AccommodationInformation> accommodationInfo;

  @override
  State<AccommodationSection> createState() => _AccommodationSectionState();
}

class _AccommodationSectionState extends State<AccommodationSection> {
  @override
  Widget build(BuildContext context) {
    if (widget.accommodationInfo.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Icon(
              Icons.hotel_outlined,
              size: 48,
              color: Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withValues(alpha: 0.3),
            ),
            const SizedBox(height: 16),
            Text(
              'No accommodation information available',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.6),
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Upload hotel bookings to see accommodation details here',
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
        for (int i = 0; i < widget.accommodationInfo.length; i++) ...[
          _AccommodationCard(accommodation: widget.accommodationInfo[i]),
          if (i < widget.accommodationInfo.length - 1)
            const SizedBox(height: 12),
        ],
      ],
    );
  }
}

class _AccommodationCard extends StatelessWidget {
  const _AccommodationCard({required this.accommodation});

  final AccommodationInformation accommodation;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Hotel header
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      accommodation.hotelName ?? 'Unknown Hotel',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    if (accommodation.address != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        accommodation.address!,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withValues(alpha: 0.7),
                            ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              if (accommodation.rating != null) ...[
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.star_rounded,
                        size: 14,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        accommodation.rating!.toStringAsFixed(1),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),

          const SizedBox(height: 16),

          // Check-in/out dates
          if (accommodation.checkInDate != null ||
              accommodation.checkOutDate != null)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Check-in
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Check-in',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        accommodation.checkInDate != null
                            ? _formatDate(accommodation.checkInDate!)
                            : 'Not specified',
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                      ),
                    ],
                  ),
                ),

                // Divider
                Container(
                  height: 40,
                  width: 1,
                  color: Theme.of(context)
                      .colorScheme
                      .outline
                      .withValues(alpha: 0.3),
                ),

                // Check-out
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'Check-out',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        accommodation.checkOutDate != null
                            ? _formatDate(accommodation.checkOutDate!)
                            : 'Not specified',
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

          // Additional details
          if (accommodation.roomType != null ||
              accommodation.numberOfGuests != null ||
              accommodation.numberOfNights != null) ...[
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              spacing: 12,
              children: [
                if (accommodation.roomType != null)
                  _DetailChip(
                    icon: Icons.bed,
                    label: accommodation.roomType!,
                  ),
                if (accommodation.numberOfGuests != null)
                  _DetailChip(
                    icon: Icons.person,
                    label:
                        '${accommodation.numberOfGuests} guest${accommodation.numberOfGuests! > 1 ? 's' : ''}',
                  ),
                if (accommodation.numberOfNights != null)
                  _DetailChip(
                    icon: Icons.nights_stay,
                    label:
                        '${accommodation.numberOfNights} night${accommodation.numberOfNights! > 1 ? 's' : ''}',
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return DateFormat('MMM dd, yyyy').format(date);
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
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 14,
          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
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
    );
  }
}
