import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:travio/theme.dart';

class BuildItineraryView extends StatelessWidget {
  const BuildItineraryView({super.key});

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 600),
      child: Padding(
        padding: const EdgeInsets.only(bottom: 24),
        child: SingleChildScrollView(
          child: Column(
            spacing: 16,
            children: [
              InkWell(
                onTap: () {},
                borderRadius: BorderRadius.circular(20),
                child: Padding(
                  padding: const EdgeInsets.only(left: 8.0, right: 8.0),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Row(
                        children: [
                          Opacity(
                            opacity: 0.5,
                            child: _DocumentCard(showTitle: true),
                          ),
                          SizedBox(width: 16),
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(20),
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    Expanded(
                                      child: SizedBox(
                                        height: 1.414 * 100,
                                        child: Opacity(
                                          opacity: 0.4,
                                          child: ListView.separated(
                                            scrollDirection: Axis.horizontal,
                                            physics:
                                                const NeverScrollableScrollPhysics(),
                                            itemCount: 8,
                                            separatorBuilder:
                                                (context, index) =>
                                                    SizedBox(width: 16),
                                            itemBuilder: (context, index) =>
                                                _DocumentCard(),
                                          ),
                                        ),
                                      ),
                                    ),
                                    BackdropFilter(
                                      filter: ImageFilter.blur(
                                          sigmaX: 2, sigmaY: 2),
                                      child: Expanded(child: SizedBox()),
                                    )
                                  ],
                                ),
                              ),
                            ),
                          )
                        ],
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.add_circle_rounded,
                            size: 40,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Add Documents',
                            style: Theme.of(context)
                                .textTheme
                                .headlineSmall
                                ?.copyWith(
                                  color:
                                      Theme.of(context).colorScheme.onSurface,
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              _AddDetailCard(
                key: const ValueKey('add-flight-detail-card'),
                title: 'Add Flight Details',
                image: 'assets/images/flight.jpg',
                onTap: () {},
              ),
              _AddDetailCard(
                key: const ValueKey('add-hotel-detail-card'),
                title: 'Add Hotel Info',
                image: 'assets/images/hotel.jpg',
                onTap: () {},
              ),
              _AddDetailCard(
                key: const ValueKey('add-rental-car-detail-card'),
                title: 'Add Rental Car Details',
                image: 'assets/images/rental_car.jpg',
                onTap: () {},
              ),
              _AddDetailCard(
                key: const ValueKey('add-train-detail-card'),
                title: 'Add Train Booking',
                image: 'assets/images/train.jpg',
                onTap: () {},
              ),
              _AddDetailCard(
                key: const ValueKey('add-cruise-detail-card'),
                title: 'Add Cruise Booking',
                image: 'assets/images/cruise.jpg',
                onTap: () {},
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AddDetailCard extends StatefulWidget {
  const _AddDetailCard({
    super.key,
    required this.title,
    required this.image,
    required this.onTap,
  });

  final String title;
  final String image;
  final VoidCallback onTap;

  @override
  State<_AddDetailCard> createState() => _AddDetailCardState();
}

class _AddDetailCardState extends State<_AddDetailCard> {
  bool _isHovering = false;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onHover: (value) => setState(() => _isHovering = value),
      onTap: widget.onTap,
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: 200.ms,
        curve: Curves.easeInOut,
        width: double.infinity,
        decoration: BoxDecoration(
          color: DarkModeColors.darkOnPrimary.withValues(alpha: 0.8),
          image: DecorationImage(
            image: AssetImage(widget.image),
            fit: BoxFit.cover,
            opacity: _isHovering ? 0.6 : 0.35,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Row(
            children: [
              Icon(
                Icons.add_circle_rounded,
                size: 40,
                color: Colors.white.withValues(alpha: 0.8),
              ),
              const SizedBox(width: 12),
              Text(
                widget.title,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DocumentCard extends StatelessWidget {
  const _DocumentCard({this.showTitle = false});

  final bool showTitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 1.414 * 100,
      width: 100,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3),
          width: 1.5,
        ),
        boxShadow: showTitle
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 5,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: showTitle
          ? Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.document_scanner_rounded,
                  size: 24,
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.8),
                ),
                const SizedBox(height: 8),
                Text(
                  'document.pdf',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.8),
                      ),
                ),
              ],
            )
          : SizedBox(),
    );
  }
}
