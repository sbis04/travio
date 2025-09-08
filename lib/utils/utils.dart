import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

export 'constants.dart';
export 'responsive.dart';

void logPrint(String message) {
  if (kDebugMode) {
    debugPrint(message);
  }
}

extension ContextExtension on BuildContext {
  double get appHeight => MediaQuery.sizeOf(this).height;
  double get appWidth => MediaQuery.sizeOf(this).width;
}

extension DateTimeExtension on DateTime {
  DateTime get startOfDay => DateTime(year, month, day);

  DateTime get endOfDay => DateTime(year, month, day, 23, 59);
}

extension StatefulWidgetExtensions on State<StatefulWidget> {
  /// Check if the widget exist before safely setting state.
  void safeSetState(VoidCallback fn) {
    if (mounted) {
      // ignore: invalid_use_of_protected_member
      setState(fn);
    }
  }
}
