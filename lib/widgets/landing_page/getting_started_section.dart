import 'dart:async';
import 'dart:math';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:travio/models/place.dart';
import 'package:travio/models/trip.dart';
import 'package:travio/router/app_router.dart';
import 'package:travio/services/auth_service.dart';
import 'package:travio/services/trip_service.dart';
import 'package:travio/utils/utils.dart';
import 'package:travio/widgets/hoverable_image.dart';
import 'package:travio/widgets/place_search_field.dart';
import 'package:travio/widgets/landing_page/popular_destinations.dart';
import 'package:travio/widgets/landing_page/user_trips_section.dart';

class GettingStartedSection extends StatefulWidget {
  const GettingStartedSection({
    super.key,
    required this.landingScrollController,
  });

  final ScrollController landingScrollController;

  @override
  State<GettingStartedSection> createState() => _GettingStartedSectionState();
}

class _GettingStartedSectionState extends State<GettingStartedSection> {
  final TextEditingController _placeTextController = TextEditingController();
  final FocusNode _placeTextFocusNode = FocusNode();

  bool _isLoading = false;
  final List<Trip> _userTrips = [];
  StreamSubscription<User?>? _authSubscription;

  @override
  void initState() {
    super.initState();

    // Listener to the focus node to update the fill color
    _placeTextFocusNode.addListener(() {
      setState(() {});

      // scroll to show the top places view if the focus is gained
      if (_placeTextFocusNode.hasFocus) {
        widget.landingScrollController.animateTo(
          context.appHeight * 0.25,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
      // scroll back up if exactly at the scrolled position
      else if (widget.landingScrollController.position.pixels ==
          context.appHeight * 0.25) {
        widget.landingScrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    });

    // Listen to auth state changes to load user trips
    _authSubscription = AuthService.authStateChanges.listen((user) {
      _userTrips.clear();
      if (user != null) {
        _loadUserTrips();
      }
      setState(() {});
    });

    // Load trips if user is already signed in
    if (AuthService.isSignedIn) {
      _loadUserTrips();
    }
  }

  @override
  void dispose() {
    _placeTextController.dispose();
    _placeTextFocusNode.dispose();
    _authSubscription?.cancel();
    super.dispose();
  }

  Future<void> _loadUserTrips() async {
    try {
      logPrint('📱 Loading user trips...');

      final trips = await TripService.getCurrentUserTrips();

      if (mounted) {
        setState(() => _userTrips.addAll(trips));
        logPrint('✅ Loaded ${trips.length} user trip(s)');
      }
    } catch (e) {
      logPrint('❌ Error loading user trips: $e');
    }
  }

  Future<void> _onPlaceSelected(Place selectedPlace) async {
    logPrint('🎯 Place Selected: ${selectedPlace.name}');
    logPrint('   Place ID: ${selectedPlace.placeId}');
    logPrint('   Address: ${selectedPlace.displayAddress}');
    logPrint('   Types: ${selectedPlace.types.join(', ')}');
    if (selectedPlace.hasLocation) {
      logPrint(
          '   Location: ${selectedPlace.latitude}, ${selectedPlace.longitude}');
    }

    // Show loading state
    setState(() => _isLoading = true);

    try {
      // Create trip with anonymous authentication
      final tripId = await TripService.createTripWithPlace(selectedPlace);

      if (tripId != null) {
        // Navigate to trip planner with trip ID
        if (!mounted) return;
        context.goToTripDetails(tripId: tripId);
      } else {
        logPrint('❌ Failed to create trip');
      }
    } catch (e) {
      logPrint('❌ Error in place selection flow: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _onSearchSubmitted(String query) {
    if (query.isNotEmpty) {
      logPrint('🚀 Search Submitted: "$query"');
      // Handle manual search submission if needed
    }
  }

  void _onPlaceSelectedFromCarousel(Place selectedPlace) async {
    // Fill the search field with the selected place name
    _placeTextController.text = selectedPlace.name;
    // Unfocus the search field since we have a selection
    _placeTextFocusNode.unfocus();

    await _onPlaceSelected(selectedPlace);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: max(400.0,
                context.appHeight - kAppBarHeight - context.appHeight * 0.2),
            minHeight: 400.0,
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Row(
                mainAxisSize: MainAxisSize.max,
                children: [
                  Flexible(
                    child: HoverableImage(
                      translate: Offset(-60, -80),
                      scale: 1.4,
                      rotate: 0.05,
                      tilt: -0.5,
                      image: 'assets/images/ocean_boat.jpg',
                    ),
                  ),
                  ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: max(580, context.appWidth * 0.4),
                    ),
                    child: SizedBox(width: double.infinity),
                  ),
                  Flexible(
                    child: HoverableImage(
                      translate: Offset(60, -80),
                      scale: 1.3,
                      rotate: -0.05,
                      tilt: 0.5,
                      image: 'assets/images/red_rocks.jpg',
                    ),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: max(580, context.appWidth * 0.4),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Trips Made Simple',
                        style: Theme.of(context)
                            .textTheme
                            .displayMedium
                            ?.copyWith(
                              color: Theme.of(context).colorScheme.onSurface,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Discover amazing destinations, create detailed itineraries, and share your adventures with fellow travelers. Make every journey unforgettable with Travio.',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withValues(alpha: 0.8),
                              height: 1.5,
                            ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 40),
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 550),
                        child: PlaceSearchField(
                          controller: _placeTextController,
                          focusNode: _placeTextFocusNode,
                          isSearching: _isLoading,
                          onPlaceSelected: _onPlaceSelected,
                          onSubmitted: _onSearchSubmitted,
                          hintText: 'Where would you like to go? ✈️',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        // Show user's trips if signed in (including anonymous users)
        AnimatedSize(
          duration: 300.ms,
          curve: Curves.easeInOut,
          alignment: Alignment.topCenter,
          child: AuthService.isSignedIn && _userTrips.isNotEmpty
              ? Padding(
                  padding: const EdgeInsets.only(bottom: 100),
                  child: UserTripsSection(
                    trips: _userTrips,
                    onTripSelected: (trip) => trip.status == TripStatus.ready
                        ? context.goToTripPlanning(trip.id)
                        : context.goToTripDetails(tripId: trip.id),
                  ),
                )
              : SizedBox(width: double.infinity),
        ),

        PopularDestinations(
          scrollController: widget.landingScrollController,
          onPlaceSelected: _onPlaceSelectedFromCarousel,
          onLoading: (isLoading) => setState(() => _isLoading = isLoading),
        ),
      ],
    );
  }
}
