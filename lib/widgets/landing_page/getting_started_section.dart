import 'dart:math';

import 'package:flutter/material.dart';
import 'package:travio/utils/utils.dart';
import 'package:travio/widgets/hoverable_image.dart';

class GettingStartedSection extends StatelessWidget {
  const GettingStartedSection({super.key});

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: max(
            400.0, context.appHeight - kAppBarHeight - context.appHeight * 0.2),
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
                    style: Theme.of(context).textTheme.displayMedium?.copyWith(
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
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ElevatedButton.icon(
                        onPressed: () {},
                        label: Text(
                          'Start Planning',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          elevation: 4,
                          backgroundColor:
                              Theme.of(context).colorScheme.primary,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 32,
                            vertical: 24,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(50),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
