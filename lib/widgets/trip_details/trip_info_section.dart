import 'dart:math';

import 'package:calendar_date_picker2/calendar_date_picker2.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:intl/intl.dart';
import 'package:travio/models/place.dart';
import 'package:travio/utils/utils.dart';
import 'package:travio/widgets/place_search_field.dart';

const _sectionTitleHeight = 50.0;

class TripInfoSection extends StatefulWidget {
  const TripInfoSection({
    super.key,
    required this.selectedPlace,
  });

  final Place? selectedPlace;

  @override
  State<TripInfoSection> createState() => _TripInfoSectionState();
}

class _TripInfoSectionState extends State<TripInfoSection> {
  final _scrollController = ScrollController();
  final _placeTextController = TextEditingController();
  final _placeTextFocusNode = FocusNode();
  int _currentStep = 2;
  int _currentScrollStep = 1;
  ({DateTime? start, DateTime? end})? _currentDateRange;

  @override
  void initState() {
    super.initState();
    SchedulerBinding.instance.addPostFrameCallback((timeStamp) {
      _maybeScrollToCurrentStep();
    });
  }

  @override
  void dispose() {
    _placeTextController.dispose();
    _placeTextFocusNode.dispose();
    super.dispose();
  }

  Future<void> _maybeScrollToCurrentStep() async {
    print('🚀 _currentStep: $_currentStep');

    if (_currentStep != _currentScrollStep) {
      _currentScrollStep = _currentStep;

      final double scrollDistance;

      if (_currentStep == 1) {
        scrollDistance = 0;
      } else {
        final topPadding = _currentStep == 1 ? context.appHeight * 0.1 : 0;
        final titleSpacing = 16.0 * 2;

        scrollDistance = max(
            400.0,
            context.appHeight -
                kAppBarHeight -
                topPadding -
                _sectionTitleHeight -
                titleSpacing -
                16);
      }

      // scroll to the current step
      await _scrollController.animateTo(
        scrollDistance,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
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
  Widget build(BuildContext context) {
    return SingleChildScrollView(
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
              title: 'Choose a place',
              subtitle: 'Search for the country or city you want to visit.',
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 550),
                child: PlaceSearchField(
                  controller: _placeTextController,
                  focusNode: _placeTextFocusNode,
                  isSearching: false,
                  onPlaceSelected: (selectedPlace) {},
                  onSubmitted: (query) {},
                  hintText: 'Where would you like to go? ✈️',
                ),
              ),
            ),
            TripInfoSectionView(
              step: 2,
              isCurrentStep: _currentStep == 2,
              title: 'Duration of the trip',
              subtitle:
                  'Select the dates of your trip. Don\'t worry, you can modify it anytime.',
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 550),
                child: Column(
                  children: [
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Theme.of(context)
                            .colorScheme
                            .outline
                            .withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          width: 2,
                          color: Theme.of(context).colorScheme.outline,
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: 8.0,
                          horizontal: 16.0,
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Start date',
                                    style:
                                        Theme.of(context).textTheme.bodyMedium,
                                  ),
                                  // SizedBox(height: 2),
                                  Text(
                                    _currentDateRange?.start != null
                                        ? DateFormat.yMMMd()
                                            .format(_currentDateRange!.start!)
                                        : 'Select a date',
                                    style: Theme.of(context)
                                        .textTheme
                                        .headlineSmall
                                        ?.copyWith(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .primary,
                                        ),
                                  ),
                                ],
                              ),
                            ),
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 16.0),
                              child: Container(
                                width: 1.5,
                                height: 50,
                                color: Theme.of(context).colorScheme.outline,
                              ),
                            ),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'End date',
                                    style:
                                        Theme.of(context).textTheme.bodyMedium,
                                  ),
                                  // SizedBox(height: 2),
                                  Text(
                                    _currentDateRange?.end != null
                                        ? DateFormat.yMMMd()
                                            .format(_currentDateRange!.end!)
                                        : 'Select a date',
                                    style: Theme.of(context)
                                        .textTheme
                                        .headlineSmall
                                        ?.copyWith(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .primary,
                                        ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    CalendarDatePicker2(
                      config: CalendarDatePicker2Config(
                        calendarType: CalendarDatePicker2Type.range,
                        hideMonthPickerDividers: true,
                        hideYearPickerDividers: true,
                        allowSameValueSelection: true,
                        selectedDayHighlightColor:
                            Theme.of(context).colorScheme.primary,
                        selectedRangeHighlightColor: Theme.of(context)
                            .colorScheme
                            .primary
                            .withValues(alpha: 0.8),
                        daySplashColor: Theme.of(context)
                            .colorScheme
                            .primary
                            .withAlpha(100),
                        disabledDayTextStyle:
                            Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .secondary
                                      .withValues(alpha: 0.5),
                                ),
                        selectedDayTextStyle:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                        selectedRangeDayTextStyle:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                        dayTextStyle: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                        monthTextStyle: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                        yearTextStyle: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                        selectedMonthTextStyle:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  color: Colors.white,
                                ),
                        selectedYearTextStyle:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  color: Colors.white,
                                ),
                        controlsTextStyle:
                            Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  color: Theme.of(context).colorScheme.primary,
                                  fontSize: 20,
                                ),
                      ),
                      value: [_currentDateRange?.start, _currentDateRange?.end]
                          .nonNulls
                          .toList(),
                      onValueChanged: (dates) {
                        if (dates.length != 2) {
                          return;
                        }

                        setState(() => _currentDateRange = (
                              start: dates[0].startOfDay,
                              end: dates[1].endOfDay,
                            ));
                      },
                    ),
                  ],
                ),
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
          ],
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
    final topPadding = step == 1 ? context.appHeight * 0.1 : 0;
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
                      cursor: SystemMouseCursors.click,
                      child: GestureDetector(
                        onTap: onStepTap,
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
                        cursor: SystemMouseCursors.click,
                        child: GestureDetector(
                          onTap: onStepTap,
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
                      child,
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
