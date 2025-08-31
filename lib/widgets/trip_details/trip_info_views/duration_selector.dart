import 'package:calendar_date_picker2/calendar_date_picker2.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:travio/utils/utils.dart';

typedef CurrentDateRange = ({DateTime? start, DateTime? end});

class DurationSelectorView extends StatelessWidget {
  const DurationSelectorView({
    super.key,
    required this.currentDateRange,
    required this.onDateRangeChanged,
  });

  final CurrentDateRange? currentDateRange;
  final Function(CurrentDateRange) onDateRangeChanged;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 550),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color:
                  Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
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
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        Text(
                          currentDateRange?.start != null
                              ? DateFormat.yMMMd()
                                  .format(currentDateRange!.start!)
                              : 'Select a date',
                          style: Theme.of(context)
                              .textTheme
                              .headlineSmall
                              ?.copyWith(
                                color: Theme.of(context)
                                    .colorScheme
                                    .primary
                                    .withValues(
                                        alpha: currentDateRange?.start != null
                                            ? 1
                                            : 0.5),
                              ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
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
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        // SizedBox(height: 2),
                        Text(
                          currentDateRange?.end != null
                              ? DateFormat.yMMMd()
                                  .format(currentDateRange!.end!)
                              : 'Select a date',
                          style: Theme.of(context)
                              .textTheme
                              .headlineSmall
                              ?.copyWith(
                                color: Theme.of(context)
                                    .colorScheme
                                    .primary
                                    .withValues(
                                        alpha: currentDateRange?.end != null
                                            ? 1
                                            : 0.5),
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
              selectedDayHighlightColor: Theme.of(context).colorScheme.primary,
              selectedRangeHighlightColor:
                  Theme.of(context).colorScheme.primary.withValues(alpha: 0.8),
              daySplashColor:
                  Theme.of(context).colorScheme.primary.withAlpha(100),
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
              dayTextStyle: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
              monthTextStyle: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
              yearTextStyle: Theme.of(context).textTheme.titleMedium?.copyWith(
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
            value: [currentDateRange?.start, currentDateRange?.end].toList(),
            onValueChanged: (dates) => onDateRangeChanged(
              (
                start: dates.elementAtOrNull(0)?.startOfDay,
                end: dates.elementAtOrNull(1)?.endOfDay,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
