import 'package:flutter/material.dart';
import 'package:travio/widgets/app_header.dart';
import 'package:travio/widgets/features_section.dart';
import 'package:travio/widgets/cta_section.dart';
import 'package:travio/widgets/app_footer.dart';
import 'package:travio/widgets/landing_page/getting_started_section.dart';

class LandingPage extends StatefulWidget {
  const LandingPage({
    super.key,
  });

  @override
  State<LandingPage> createState() => _LandingPageState();
}

class _LandingPageState extends State<LandingPage> {
  final _landingScrollController = ScrollController();

  @override
  void dispose() {
    super.dispose();
    _landingScrollController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        controller: _landingScrollController,
        child: Center(
          child: Column(
            children: [
              AppHeader(),
              GettingStartedSection(
                landingScrollController: _landingScrollController,
              ),
              // const FeaturesSection(),
              // const CTASection(),
              const AppFooter(),
            ],
          ),
        ),
      ),
    );
  }
}
