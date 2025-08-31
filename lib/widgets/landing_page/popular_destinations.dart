import 'dart:async';

import 'package:flutter/material.dart';
import 'package:travio/models/place.dart';
import 'package:travio/models/popular_destinations.dart';
import 'package:travio/services/places_service.dart';
import 'package:travio/utils/utils.dart';

class PopularDestinations extends StatefulWidget {
  const PopularDestinations({
    super.key,
    required this.scrollController,
    required this.onPlaceSelected,
    required this.onLoading,
  });

  final ScrollController scrollController;
  final Function(Place) onPlaceSelected;
  final Function(bool) onLoading;

  @override
  State<PopularDestinations> createState() => _PopularDestinationsState();
}

class _PopularDestinationsState extends State<PopularDestinations> {
  final _horizontalScrollController1 = ScrollController();
  final _horizontalScrollController2 = ScrollController();
  bool _isPaused1 = false;
  bool _isPaused2 = false;
  Timer? _scrollTimer1;
  Timer? _scrollTimer2;
  bool _isScrollingForward1 = true;
  bool _isScrollingForward2 = false;

  @override
  void initState() {
    super.initState();
    // Start auto-scrolling after widget is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Initialize row 2 to start from the end
      if (_horizontalScrollController2.hasClients) {
        final maxScroll = _horizontalScrollController2.position.maxScrollExtent;
        _horizontalScrollController2.jumpTo(maxScroll);
      }
      _startAutoScroll();
    });
  }

  @override
  void dispose() {
    _scrollTimer1?.cancel();
    _scrollTimer2?.cancel();
    _horizontalScrollController1.dispose();
    _horizontalScrollController2.dispose();
    super.dispose();
  }

  void _onDestinationTapped(PopularDestination destination) async {
    logPrint('🎯 Popular Destination Tapped: ${destination.name}');
    widget.onLoading(true);
    // scroll to show the top places view if the focus is gained
    widget.scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );

    try {
      // Search for the Place using the destination name
      final places = await PlacesService.searchDestinations(destination.name);

      if (places.isNotEmpty) {
        // Use the first (most relevant) result
        final selectedPlace = places.first;

        logPrint('✅ Place found: ${selectedPlace.name}');
        logPrint('   Address: ${selectedPlace.displayAddress}');
        logPrint('   Types: ${selectedPlace.types.join(', ')}');

        // Return the Place to the parent widget
        widget.onPlaceSelected(selectedPlace);
      } else {
        logPrint('⚠️ No Place found for ${destination.name}');
      }
    } catch (e) {
      logPrint('❌ Error searching for place: $e');
    } finally {
      widget.onLoading(false);
    }
  }

  void _startAutoScroll() {
    _startRow1Animation();
    _startRow2Animation();
  }

  void _startRow1Animation() {
    _scrollTimer1 = Timer.periodic(const Duration(milliseconds: 12), (timer) {
      if (!mounted || _isPaused1) return;

      if (_horizontalScrollController1.hasClients) {
        final maxScroll = _horizontalScrollController1.position.maxScrollExtent;
        final currentScroll = _horizontalScrollController1.offset;

        if (_isScrollingForward1) {
          if (currentScroll >= maxScroll) {
            _isScrollingForward1 = false; // Reverse direction
          } else {
            _horizontalScrollController1.jumpTo(currentScroll + 0.5);
          }
        } else {
          if (currentScroll <= 0) {
            _isScrollingForward1 = true; // Forward direction
          } else {
            _horizontalScrollController1.jumpTo(currentScroll - 0.5);
          }
        }
      }
    });
  }

  void _startRow2Animation() {
    _scrollTimer2 = Timer.periodic(const Duration(milliseconds: 12), (timer) {
      if (!mounted || _isPaused2) return;

      if (_horizontalScrollController2.hasClients) {
        final maxScroll = _horizontalScrollController2.position.maxScrollExtent;
        final currentScroll = _horizontalScrollController2.offset;

        if (_isScrollingForward2) {
          if (currentScroll >= maxScroll) {
            _isScrollingForward2 = false; // Reverse direction
          } else {
            _horizontalScrollController2.jumpTo(currentScroll + 0.4);
          }
        } else {
          if (currentScroll <= 0) {
            _isScrollingForward2 = true; // Forward direction
          } else {
            _horizontalScrollController2.jumpTo(currentScroll - 0.4);
          }
        }
      }
    });
  }

  Widget _buildScrollingImageRow({
    required List<PopularDestination> destinations,
    required ScrollController controller,
  }) {
    return SizedBox(
      height: 300,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        controller: controller,
        scrollDirection: Axis.horizontal,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: destinations.length,
        itemBuilder: (context, index) {
          final destination = destinations[index];

          return DestinationCard(
            key: ValueKey(destination.name),
            destination: destination,
            onSelect: _onDestinationTapped,
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        MouseRegion(
          onEnter: (_) => setState(() => _isPaused1 = true),
          onExit: (_) => setState(() => _isPaused1 = false),
          child: _buildScrollingImageRow(
            destinations: kDestinations.take(7).toList(),
            controller: _horizontalScrollController1,
          ),
        ),
        const SizedBox(height: 16),
        MouseRegion(
          onEnter: (_) => setState(() => _isPaused2 = true),
          onExit: (_) => setState(() => _isPaused2 = false),
          child: _buildScrollingImageRow(
            destinations: kDestinations.skip(7).take(7).toList(),
            controller: _horizontalScrollController2,
          ),
        ),
      ],
    );
  }
}

class DestinationCard extends StatefulWidget {
  const DestinationCard(
      {super.key, required this.destination, required this.onSelect});

  final PopularDestination destination;
  final Function(PopularDestination) onSelect;

  @override
  State<DestinationCard> createState() => _DestinationCardState();
}

class _DestinationCardState extends State<DestinationCard> {
  bool _isHovering = false;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _isHovering = true),
        onExit: (_) => setState(() => _isHovering = false),
        child: GestureDetector(
          onTap: () => widget.onSelect(widget.destination),
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 100),
            curve: Curves.easeInOut,
            opacity: _isHovering ? 1.0 : 0.9,
            child: Card(
              elevation: _isHovering ? 8 : 5,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Stack(
                alignment: Alignment.bottomLeft,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.asset(
                      widget.destination.assetImage,
                      fit: BoxFit.cover,
                      width: 420,
                      height: 300,
                    ),
                  ),
                  Container(
                    width: 420,
                    height: 100,
                    decoration: BoxDecoration(
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(12),
                        bottomRight: Radius.circular(12),
                      ),
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0),
                          Colors.black,
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(left: 16, bottom: 8),
                    child: Text(
                      widget.destination.name,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
