import 'dart:async';
import 'dart:math';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:pointer_interceptor/pointer_interceptor.dart';
import 'package:travio/router/app_router.dart';
import 'package:travio/screens/trip_planning_page.dart';
import 'package:travio/services/auth_service.dart';
import 'package:travio/utils/utils.dart';
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
  late final StreamSubscription<User?> authSubscription;
  int _currentStep = 1;
  bool _shouldShowTripPlanning = false;
  bool _isHovering = false;
  bool get _isAuthenticated =>
      AuthService.currentUser != null && !AuthService.currentUser!.isAnonymous;

  @override
  void initState() {
    super.initState();

    // Listen to auth state changes
    authSubscription = AuthService.authStateChanges.listen(
      (user) {
        safeSetState(() {});

        if (_isAuthenticated) {
          Future.delayed(
            4.5.seconds,
            () => safeSetState(() => _shouldShowTripPlanning = true),
          );
        }
      },
    );
  }

  @override
  void dispose() {
    authSubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.sizeOf(context);
    final screenWidth = screenSize.width;
    final screenHeight = screenSize.height;
    return Scaffold(
      body: Center(
        child: Stack(
          alignment: Alignment.topCenter,
          children: [
            TripInfoSection(
              tripId: widget.tripId,
              onStepChange: (step) => safeSetState(() {
                _currentStep = step;
                _shouldShowTripPlanning = step == 5 && _isAuthenticated;
              }),
            ),
            AppHeader(hideButtons: true),
            AnimatedPositioned(
              duration: 600.ms,
              curve: Curves.easeInOut,
              top: _shouldShowTripPlanning ? 340 : screenHeight,
              child: AnimatedOpacity(
                opacity: _currentStep == 5 && _isAuthenticated ? 1.0 : 0.0,
                duration: 1.seconds,
                curve: Curves.easeInOut,
                child: Card(
                  elevation: 40,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(40),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(40),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: min(screenWidth * 0.8, 1200),
                        maxHeight: 800,
                      ),
                      child: InkWell(
                        hoverColor: Colors.transparent,
                        highlightColor: Colors.transparent,
                        splashColor: Colors.transparent,
                        focusColor: Colors.transparent,
                        onHover: (value) => safeSetState(
                          () => _isHovering = value,
                        ),
                        onTap: () => context.goToTripPlanning(widget.tripId),
                        child: Stack(
                          alignment: Alignment.topCenter,
                          children: [
                            IgnorePointer(
                              child: TripPlanningSection(
                                tripId: widget.tripId,
                              ),
                            ),
                            AnimatedOpacity(
                              opacity: _isHovering ? 1.0 : 0.0,
                              duration: 500.ms,
                              curve: Curves.easeInOut,
                              child: PointerInterceptor(
                                child: Container(
                                  height: double.infinity,
                                  width: double.infinity,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                      colors: [
                                        Theme.of(context).colorScheme.primary,
                                        Theme.of(context)
                                            .colorScheme
                                            .primary
                                            .withValues(alpha: 0.0),
                                      ],
                                    ),
                                  ),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    children: [
                                      SizedBox(height: 36),
                                      Text(
                                        'View Trip',
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleLarge
                                            ?.copyWith(
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .onPrimary,
                                              fontWeight: FontWeight.bold,
                                            ),
                                      ),
                                      SizedBox(height: 8),
                                      Opacity(
                                        opacity: 0.6,
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              Icons.ads_click_rounded,
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .onPrimary,
                                            ),
                                            SizedBox(width: 8),
                                            Text(
                                              'Click to go the trip planning page',
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .bodyLarge
                                                  ?.copyWith(
                                                    color: Theme.of(context)
                                                        .colorScheme
                                                        .onPrimary,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
