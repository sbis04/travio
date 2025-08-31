import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:travio/models/place.dart';
import 'package:travio/providers/theme_provider.dart';
import 'package:travio/screens/about_page.dart';
import 'package:travio/screens/contact_page.dart';
import 'package:travio/screens/landing_page.dart';
import 'package:travio/screens/trip_details_page.dart';

class AppRouter {
  static final GoRouter _router = GoRouter(
    initialLocation: '/',
    debugLogDiagnostics: true,
    routes: [
      // Landing page route
      GoRoute(
        path: '/',
        name: 'home',
        pageBuilder: (context, state) => _buildPageWithFadeTransition(
          child: LandingPage(),
          settings: state,
        ),
      ),

      // Trip planner route with destination parameter
      GoRoute(
        path: '/planner',
        name: 'trip-planner',
        pageBuilder: (context, state) {
          final placeData = state.extra as Place?;
          return _buildPageWithFadeTransition(
            child: TripDetailsPage(selectedPlace: placeData),
            settings: state,
          );
        },
      ),

      // Trip planner with destination in URL
      // GoRoute(
      //   path: '/planner/:destination',
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
        pageBuilder: (context, state) => _buildPageWithFadeTransition(
          child: const AboutPage(),
          settings: state,
        ),
      ),

      // Contact page
      GoRoute(
        path: '/contact',
        name: 'contact',
        pageBuilder: (context, state) => _buildPageWithFadeTransition(
          child: const ContactPage(),
          settings: state,
        ),
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

  // Custom fade transition for all pages
  static Page<dynamic> _buildPageWithFadeTransition({
    required Widget child,
    required GoRouterState settings,
  }) {
    return CustomTransitionPage<void>(
      key: settings.pageKey,
      child: child,
      transitionDuration: const Duration(milliseconds: 200),
      reverseTransitionDuration: const Duration(milliseconds: 200),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(
          opacity: CurveTween(curve: Curves.easeInOut).animate(animation),
          child: child,
        );
      },
    );
  }
}

// Navigation helper methods
extension AppNavigation on BuildContext {
  void goHome() => go('/');

  void goToTripPlanner({Place? selectedPlace}) {
    if (selectedPlace != null) {
      goNamed('trip-planner', extra: selectedPlace);
    } else {
      go('/planner');
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
