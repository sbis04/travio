import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:travio/models/place.dart';
import 'package:travio/providers/theme_provider.dart';
import 'package:travio/router/app_router.dart';
import 'package:travio/widgets/app_header.dart';

class TripPlannerPage extends StatefulWidget {
  const TripPlannerPage({
    super.key,
    this.selectedPlace,
  });

  final Place? selectedPlace;

  @override
  State<TripPlannerPage> createState() => _TripPlannerPageState();
}

class _TripPlannerPageState extends State<TripPlannerPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        // controller: _landingScrollController,
        child: Center(
          child: Column(
            children: [
              AppHeader(),
              // GettingStartedSection(
              //   landingScrollController: _landingScrollController,
              // ),
              // const FeaturesSection(),
              // const CTASection(),
              // const AppFooter(),
            ],
          ),
        ),
      ),
    );
  }
}
