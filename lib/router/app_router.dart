import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:travio/screens/about_page.dart';
import 'package:travio/screens/contact_page.dart';
import 'package:travio/screens/landing_page.dart';
import 'package:travio/screens/page_not_found_view.dart';
import 'package:travio/screens/trip_details_page.dart';
import 'package:travio/screens/trip_planning_page.dart';

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

      // Trip planning page route
      GoRoute(
        path: '/trip/:tripId/plan',
        name: 'trip-planning',
        pageBuilder: (context, state) {
          final tripId = state.pathParameters['tripId'] ?? '';
          return _buildPageWithFadeTransition(
            child: TripPlanningPage(tripId: tripId),
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
    errorBuilder: (_, __) => PageNotFoundView(),
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

  void goToTripDetails({String? tripId}) {
    if (tripId != null) {
      goToTrip(tripId);
    } else {
      go('/');
    }
  }

  void goToTripPlanning(String tripId) {
    goNamed('trip-planning', pathParameters: {'tripId': tripId});
  }

  void goToAbout() => go('/about');
  void goToContact() => go('/contact');
}
