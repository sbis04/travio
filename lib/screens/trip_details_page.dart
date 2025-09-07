import 'package:flutter/material.dart';
import 'package:travio/widgets/app_header.dart';
import 'package:travio/widgets/trip_details/trip_info_section.dart';

class TripDetailsPage extends StatefulWidget {
  const TripDetailsPage({
    super.key,
    required this.tripId,
  });

  final String tripId;

  @override
  State<TripDetailsPage> createState() => _TripDetailsPageState();
}

class _TripDetailsPageState extends State<TripDetailsPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: Center(
        child: Stack(
          alignment: Alignment.topCenter,
          children: [
            TripInfoSection(tripId: widget.tripId),
            AppHeader(hideButtons: true),
          ],
        ),
      ),
    );
  }
}
