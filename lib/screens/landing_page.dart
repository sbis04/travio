import 'package:flutter/material.dart';
import 'package:travio/widgets/app_header.dart';
import 'package:travio/widgets/hero_section.dart';
import 'package:travio/widgets/features_section.dart';
import 'package:travio/widgets/cta_section.dart';
import 'package:travio/widgets/app_footer.dart';

class LandingPage extends StatelessWidget {
  const LandingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Center(
          child: Column(
            children: const [
              AppHeader(),
              HeroSection(),
              FeaturesSection(),
              CTASection(),
              AppFooter(),
            ],
          ),
        ),
      ),
    );
  }
}
