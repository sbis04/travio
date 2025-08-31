import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class PageLoadingIndicator extends StatelessWidget {
  const PageLoadingIndicator({
    super.key,
    required this.child,
    required this.isLoading,
  });

  final Widget child;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        AnimatedOpacity(
          duration: 300.ms,
          opacity: isLoading ? 1.0 : 0.0,
          curve: Curves.easeInOut,
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Center(
              child: Image.asset(
                'assets/images/travio_logo_small.png',
                width: 50,
                height: 50,
              )
                  .animate(
                    onPlay: (controller) => controller.repeat(reverse: true),
                  )
                  .shimmer(
                    color: Colors.white.withAlpha(100),
                    delay: 100.ms,
                    duration: 1000.ms,
                  )
                  .flipH(
                    duration: 500.ms,
                    begin: 0.1,
                    end: 0,
                    curve: Curves.easeIn,
                    perspective: 2,
                  )
                  .then(delay: 0.ms)
                  .flipH(
                    duration: 500.ms,
                    begin: 0,
                    end: -0.1,
                    curve: Curves.easeOut,
                    perspective: 1,
                  ),
              // child: CircularProgressIndicator(
              //   valueColor: AlwaysStoppedAnimation<Color>(
              //     Theme.of(context).colorScheme.primary,
              //   ),
              // ),
            ),
          ),
        ),
      ],
    );
  }
}
