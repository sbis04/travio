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

      // Trip planner route with trip ID
      GoRoute(
        path: '/trip/:tripId',
        name: 'trip',
        pageBuilder: (context, state) {
          final tripId = state.pathParameters['tripId'] ?? '';
          return _buildPageWithFadeTransition(
            child: TripDetailsPage(tripId: tripId),
            settings: state,
          );
        },
      ),

      // Legacy trip planner route (redirect to home if no trip ID)
      GoRoute(
        path: '/planner',
        name: 'trip-planner-legacy',
        pageBuilder: (context, state) {
          // Redirect to home since we need a trip ID
          WidgetsBinding.instance.addPostFrameCallback((_) {
            context.go('/');
          });
          return _buildPageWithFadeTransition(
            child: const Center(child: CircularProgressIndicator()),
            settings: state,
          );
        },
      ),

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

  void goToTrip(String tripId) {
    goNamed('trip', pathParameters: {'tripId': tripId});
  }

  void goToTripPlanner({String? tripId}) {
    if (tripId != null) {
      goToTrip(tripId);
    } else {
      go('/planner'); // Will redirect to home
    }
  }

  void goToAbout() => go('/about');
  void goToContact() => go('/contact');
}
