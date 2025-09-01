import 'dart:math';

import 'package:easy_debounce/easy_debounce.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:travio/models/trip.dart';
import 'package:travio/services/trip_service.dart';
import 'package:travio/utils/utils.dart';
import 'package:travio/widgets/page_loading_indicator.dart';
import 'package:travio/widgets/trip_details/trip_info_views/trip_info_views.dart';

const _sectionTitleHeight = 50.0;
const _titleGap = 16.0 * 2;

class TripInfoSection extends StatefulWidget {
  const TripInfoSection({
    super.key,
    required this.tripId,
  });

  final String tripId;

  @override
  State<TripInfoSection> createState() => _TripInfoSectionState();
}

class _TripInfoSectionState extends State<TripInfoSection> {
  final _scrollController = ScrollController();
  final _placeTextController = TextEditingController();
  final _placeTextFocusNode = FocusNode();
  int _currentStep = 1;
  int _currentScrollStep = 1;
  CurrentDateRange? _currentDateRange;

  Trip? _trip;
  bool _isLoading = true;
  String? _error;

  bool get _isDateRangeSet =>
      _currentDateRange?.start != null && _currentDateRange?.end != null;

  Future<void> _loadTripData() async {
    try {
      logPrint('📱 Loading trip data for ID: ${widget.tripId}');

      final trip = await TripService.getTrip(widget.tripId);

      if (!mounted) return;
      setState(() {
        _trip = trip;
        _isLoading = false;
        _placeTextController.text = trip?.placeName ?? '';
        _error = trip == null ? 'Trip not found' : null;
        _currentDateRange = (
          start: trip?.startDate,
          end: trip?.endDate,
        );
      });

      if (trip != null) {
        logPrint('✅ Trip loaded successfully: ${trip.placeName}');
      } else {
        logPrint('❌ Trip not found: ${widget.tripId}');
      }
    } catch (e) {
      logPrint('❌ Error loading trip: $e');
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = 'Error loading trip: $e';
      });
    }
  }

  Future<void> _maybeScrollToCurrentStep({
    double animationDuration = 300.0,
  }) async {
    logPrint('🔄 Current step: $_currentStep');

    if (_currentStep != _currentScrollStep) {
      final isForward = _currentStep > _currentScrollStep;
      final double scrollDistance;

      if (_currentStep == 1) {
        scrollDistance = 0;
      } else {
        // final topPadding = _currentStep == 1 ? context.appHeight * 0.1 : 0;

        scrollDistance = max(
                400.0,
                (context.appHeight -
                    kAppBarHeight -
                    _sectionTitleHeight -
                    _titleGap)) *
            (isForward ? _currentStep - 1 : _currentStep - 1);
      }

      _currentScrollStep = _currentStep;
      // scroll to the current step
      await _scrollController.animateTo(
        scrollDistance,
        duration: animationDuration.ms,
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _onDateRangeChanged(CurrentDateRange? dateRange) async {
    setState(() => _currentDateRange = dateRange);

    EasyDebounce.debounce(
      'update-trip-dates',
      300.ms,
      () async {
        // Save dates to Firestore
        if (_trip != null && dateRange != null) {
          try {
            logPrint('📅 Updating trip dates...');
            logPrint('   Start: ${dateRange.start}');
            logPrint('   End: ${dateRange.end}');

            final success = await TripService.updateTripDates(
              tripId: _trip!.id,
              startDate: dateRange.start,
              endDate: dateRange.end,
            );

            if (success) {
              logPrint('✅ Trip dates saved to Firestore');
            } else {
              logPrint('❌ Failed to save trip dates');
            }
          } catch (e) {
            logPrint('❌ Error saving trip dates: $e');
          }

          // scroll to next step if both dates are set
          if (dateRange.start != null && dateRange.end != null) {
            setState(() => _currentStep = 3);
            _maybeScrollToCurrentStep(animationDuration: 1000.0);
          }
        }
      },
    );
  }

  // void _onPlaceSelected(Place selectedPlace) {
  //   setState(() => _selectedPlace = selectedPlace);

  //   logPrint('🎯 Place Selected: ${selectedPlace.name}');
  //   logPrint('   Address: ${selectedPlace.displayAddress}');
  //   logPrint('   Types: ${selectedPlace.types.join(', ')}');
  //   if (selectedPlace.hasLocation) {
  //     logPrint(
  //         '   Location: ${selectedPlace.latitude}, ${selectedPlace.longitude}');
  //   }

  //   // Navigate to trip planner with selected place
  //   context.goToTripPlanner(selectedPlace: selectedPlace);
  // }

  // void _onSearchSubmitted(String query) {
  //   if (query.isNotEmpty) {
  //     logPrint('🚀 Search Submitted: "$query"');
  //     // Handle manual search submission if needed
  //   }
  // }

  @override
  void initState() {
    super.initState();
    _loadTripData();
  }

  @override
  void dispose() {
    _placeTextController.dispose();
    _placeTextFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PageLoadingIndicator(
      isLoading: _isLoading,
      child: SingleChildScrollView(
        controller: _scrollController,
        padding: EdgeInsets.only(top: context.appHeight * 0.1),
        physics: const NeverScrollableScrollPhysics(),
        child: SizedBox(
          width: double.infinity,
          child: Column(
            children: [
              TripInfoSectionView(
                step: 1,
                isCurrentStep: _currentStep == 1,
                title: 'Select a destination',
                subtitle: 'Search for the country or city you want to visit.',
                child: SelectDestinationView(
                  controller: _placeTextController,
                  focusNode: _placeTextFocusNode,
                  isSearching: false,
                  trip: _trip,
                  onPlaceSelected: (selectedPlace) {},
                  onSubmitted: (query) {},
                  onPhotosLoaded: () {
                    Future.delayed(2.seconds, () {
                      if (!mounted) return;
                      setState(
                        () => _currentStep = _trip == null
                            ? 1
                            : _isDateRangeSet
                                ? 3
                                : 2,
                      );
                      _maybeScrollToCurrentStep(animationDuration: 1000.0);
                    });
                  },
                ),
              ),
              TripInfoSectionView(
                step: 2,
                isCurrentStep: _currentStep == 2,
                title: 'Duration of the trip',
                subtitle:
                    'Select the dates of your trip. Don\'t worry, you can modify it anytime.',
                child: DurationSelectorView(
                  currentDateRange: _currentDateRange,
                  onDateRangeChanged: _onDateRangeChanged,
                ),
                onStepTap: () {
                  setState(() => _currentStep = 2);
                  _maybeScrollToCurrentStep();
                },
                onPreviousStepTap: () {
                  setState(() => _currentStep = 1);
                  _maybeScrollToCurrentStep();
                },
              ),
              TripInfoSectionView(
                step: 3,
                isCurrentStep: _currentStep == 3,
                title: 'Choose places to visit',
                subtitle: 'Select the places you want to visit.',
                child: SizedBox(),
                onStepTap: () {
                  setState(() => _currentStep = 3);
                  _maybeScrollToCurrentStep();
                },
                onPreviousStepTap: () {
                  setState(() => _currentStep = 2);
                  _maybeScrollToCurrentStep();
                },
              ),
              TripInfoSectionView(
                step: 4,
                isCurrentStep: _currentStep == 4,
                title: 'Build itinerary',
                subtitle:
                    'Build your itinerary by adding flight tickets, hotel bookings, '
                    'and more.',
                child: SizedBox(),
                onStepTap: () {
                  setState(() => _currentStep = 4);
                  _maybeScrollToCurrentStep();
                },
                onPreviousStepTap: () {
                  setState(() => _currentStep = 3);
                  _maybeScrollToCurrentStep();
                },
              ),
              TripInfoSectionView(
                step: 5,
                isCurrentStep: _currentStep == 5,
                title: 'Invite co-travelers',
                subtitle:
                    'Invite your friends and family to join you on your trip.',
                child: SizedBox(),
                onStepTap: () {
                  setState(() => _currentStep = 5);
                  _maybeScrollToCurrentStep();
                },
                onPreviousStepTap: () {
                  setState(() => _currentStep = 4);
                  _maybeScrollToCurrentStep();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class TripInfoSectionView extends StatelessWidget {
  const TripInfoSectionView({
    super.key,
    required this.step,
    required this.isCurrentStep,
    required this.title,
    required this.subtitle,
    required this.child,
    this.onStepTap,
    this.onPreviousStepTap,
  });

  final int step;
  final bool isCurrentStep;
  final String title;
  final String subtitle;
  final Widget child;
  final VoidCallback? onStepTap;
  final VoidCallback? onPreviousStepTap;

  @override
  Widget build(BuildContext context) {
    final topPadding =
        step == 1 ? context.appHeight * 0.1 : _sectionTitleHeight + _titleGap;
    return AnimatedOpacity(
      opacity: isCurrentStep ? 1.0 : 0.5,
      duration: const Duration(milliseconds: 300),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: max(400.0, context.appHeight - kAppBarHeight - topPadding),
          minHeight: 400.0,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: max(600, context.appWidth * 0.5),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Opacity(
                    opacity: step == 1 || !isCurrentStep ? 0.0 : 1.0,
                    child: IconButton(
                      onPressed: step == 1 ? null : onPreviousStepTap,
                      icon: Icon(
                        Icons.arrow_upward_rounded,
                        size: 24,
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.4),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Column(
                  children: [
                    // circular container
                    MouseRegion(
                      cursor: isCurrentStep
                          ? SystemMouseCursors.basic
                          : SystemMouseCursors.click,
                      child: GestureDetector(
                        onTap: isCurrentStep ? null : onStepTap,
                        child: Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primary,
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              step.toString(),
                              style: Theme.of(context)
                                  .textTheme
                                  .titleLarge
                                  ?.copyWith(
                                    color:
                                        Theme.of(context).colorScheme.onPrimary,
                                  ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: Container(
                        height: double.infinity,
                        width: 1.5,
                        color: Theme.of(context)
                            .colorScheme
                            .primary
                            .withValues(alpha: 0.2),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      MouseRegion(
                        cursor: isCurrentStep
                            ? SystemMouseCursors.basic
                            : SystemMouseCursors.click,
                        child: GestureDetector(
                          onTap: isCurrentStep ? null : onStepTap,
                          child: Text(
                            title,
                            style: Theme.of(context)
                                .textTheme
                                .displaySmall
                                ?.copyWith(
                                  color:
                                      Theme.of(context).colorScheme.onSurface,
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        subtitle,
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurface
                                      .withValues(alpha: 0.8),
                                  height: 1.5,
                                ),
                      ),
                      const SizedBox(height: 24),
                      Flexible(child: child),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
