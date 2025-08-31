import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:travio/models/place.dart';
import 'package:travio/providers/theme_provider.dart';
import 'package:travio/router/app_router.dart';
import 'package:travio/widgets/app_header.dart';
import 'package:travio/widgets/trip_details/trip_info_section.dart';

class TripDetailsPage extends StatefulWidget {
  const TripDetailsPage({
    super.key,
    this.selectedPlace,
  });

  final Place? selectedPlace;

  @override
  State<TripDetailsPage> createState() => _TripDetailsPageState();
}

class _TripDetailsPageState extends State<TripDetailsPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Stack(
          alignment: Alignment.topCenter,
          children: [
            TripInfoSection(selectedPlace: widget.selectedPlace),
            AppHeader(hideButtons: true),
            // GettingStartedSection(
            //   landingScrollController: _landingScrollController,
            // ),
            // const FeaturesSection(),
            // const CTASection(),
            // const AppFooter(),
          ],
        ),
      ),
    );
  }
}
