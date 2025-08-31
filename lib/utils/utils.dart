import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

export 'constants.dart';
export 'responsive.dart';

extension ContextExtension on BuildContext {
  double get appHeight => MediaQuery.sizeOf(this).height;
  double get appWidth => MediaQuery.sizeOf(this).width;
}

void logPrint(String message) {
  if (kDebugMode) {
    debugPrint(message);
  }
}
