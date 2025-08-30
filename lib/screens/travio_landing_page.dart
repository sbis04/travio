import 'package:flutter/material.dart';
import 'package:travio/widgets/app_header.dart';
import 'package:travio/widgets/features_section.dart';
import 'package:travio/widgets/cta_section.dart';
import 'package:travio/widgets/app_footer.dart';
import 'package:travio/widgets/landing_page/getting_started_section.dart';

class TravioLandingPage extends StatefulWidget {
  final VoidCallback onThemeToggle;

  const TravioLandingPage({
    super.key,
    required this.onThemeToggle,
  });

  @override
  State<TravioLandingPage> createState() => _TravioLandingPageState();
}

class _TravioLandingPageState extends State<TravioLandingPage> {
  final _landingScrollController = ScrollController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        controller: _landingScrollController,
        child: Center(
          child: Column(
            children: [
              AppHeader(onThemeToggle: widget.onThemeToggle),
              GettingStartedSection(
                landingScrollController: _landingScrollController,
              ),
              const FeaturesSection(),
              const CTASection(),
              const AppFooter(),
            ],
          ),
        ),
      ),
    );
  }
}
