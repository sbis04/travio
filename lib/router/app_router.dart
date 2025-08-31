import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:travio/models/place.dart';
import 'package:travio/providers/theme_provider.dart';
import 'package:travio/screens/about_page.dart';
import 'package:travio/screens/contact_page.dart';
import 'package:travio/screens/travio_landing_page.dart';
import 'package:travio/screens/trip_planner_page.dart';

class AppRouter {
  static final GoRouter _router = GoRouter(
    initialLocation: '/',
    debugLogDiagnostics: true,
    routes: [
      // Landing page route
      GoRoute(
        path: '/',
        name: 'home',
        builder: (context, state) => TravioLandingPage(),
      ),

      // Trip planner route with destination parameter
      GoRoute(
        path: '/plan',
        name: 'trip-planner',
        builder: (context, state) {
          final placeData = state.extra as Place?;
          return TripPlannerPage(selectedPlace: placeData);
        },
      ),

      // Trip planner with destination in URL
      // GoRoute(
      //   path: '/plan/:destination',
      //   name: 'trip-planner-destination',
      //   builder: (context, state) {
      //     final placeData = state.extra as Place?;
      //     return TripPlannerPage(
      //       selectedPlace: placeData,
      //     );
      //   },
      // ),

      // About page
      GoRoute(
        path: '/about',
        name: 'about',
        builder: (context, state) => const AboutPage(),
      ),

      // Contact page
      GoRoute(
        path: '/contact',
        name: 'contact',
        builder: (context, state) => const ContactPage(),
      ),
    ],

    // Error page for unknown routes
    errorBuilder: (context, state) => Scaffold(
      appBar: AppBar(
        title: const Text('Page Not Found'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              '404 - Page Not Found',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'The page "${state.uri}" could not be found.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => context.go('/'),
              child: const Text('Go Home'),
            ),
          ],
        ),
      ),
    ),
  );

  static GoRouter get router => _router;
}

// Navigation helper methods
extension AppNavigation on BuildContext {
  void goHome() => go('/');

  void goToTripPlanner({Place? selectedPlace}) {
    if (selectedPlace != null) {
      goNamed('trip-planner', extra: selectedPlace);
    } else {
      go('/plan');
    }
  }

  void goToDestination(String destination, {Place? placeData}) {
    goNamed(
      'trip-planner-destination',
      pathParameters: {
        'destination': destination.toLowerCase().replaceAll(' ', '-')
      },
      extra: placeData,
    );
  }

  void goToAbout() => go('/about');
  void goToContact() => go('/contact');
}
