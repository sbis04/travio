import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:travio/models/place.dart';
import 'package:travio/services/places_service.dart';
import 'package:travio/utils/utils.dart';
import 'package:travio/widgets/hoverable_image.dart';

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
  Timer? _searchTimer;
  List<Place> _searchResults = [];
  List<PlaceSuggestion> _suggestions = [];
  bool _isSearching = false;

  bool get _hasPlaceFieldFocus => _placeTextFocusNode.hasFocus;

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
  }

  @override
  void dispose() {
    _searchTimer?.cancel();
    _placeTextController.dispose();
    _placeTextFocusNode.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    // Cancel previous timer
    _searchTimer?.cancel();

    if (query.isEmpty) {
      setState(() {
        _suggestions.clear();
        _searchResults.clear();
        _isSearching = false;
      });
      return;
    }

    // Debounce search requests
    _searchTimer = Timer(const Duration(milliseconds: 500), () {
      _performSearch(query);
    });
  }

  Future<void> _performSearch(String query) async {
    if (query.isEmpty) return;

    setState(() {
      _isSearching = true;
    });

    try {
      // Get autocomplete suggestions
      final suggestions = await PlacesService.getAutocompleteSuggestions(query);

      // Get search results
      final places = await PlacesService.searchPlaces(query);

      print('🔍 Search Query: "$query"');
      print('📝 Autocomplete Suggestions (${suggestions.length}):');
      for (int i = 0; i < suggestions.length && i < 5; i++) {
        final suggestion = suggestions[i];
        print(
            '  ${i + 1}. ${suggestion.mainText} - ${suggestion.secondaryText}');
      }

      print('📍 Places Found (${places.length}):');
      for (int i = 0; i < places.length && i < 5; i++) {
        final place = places[i];
        print('  ${i + 1}. ${place.name}');
        print('     Address: ${place.displayAddress}');
        print('     Rating: ${place.rating ?? 'N/A'}');
        print('     Types: ${place.types.take(3).join(', ')}');
        if (place.hasLocation) {
          print('     Location: ${place.latitude}, ${place.longitude}');
        }
        print('');
      }

      setState(() {
        _suggestions = suggestions;
        _searchResults = places;
        _isSearching = false;
      });
    } catch (e) {
      print('❌ Search Error: $e');
      setState(() {
        _isSearching = false;
        _suggestions.clear();
        _searchResults.clear();
      });
    }
  }

  void _onSearchSubmitted(String query) {
    if (query.isNotEmpty) {
      print('🚀 Search Submitted: "$query"');
      _performSearch(query);
    }
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
                        child: TextField(
                          controller: _placeTextController,
                          focusNode: _placeTextFocusNode,
                          onChanged: _onSearchChanged,
                          onSubmitted: _onSearchSubmitted,
                          textInputAction: TextInputAction.search,
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: _placeTextFocusNode.hasFocus
                                ? Theme.of(context)
                                    .colorScheme
                                    .primary
                                    .withAlpha(40)
                                : Theme.of(context)
                                    .colorScheme
                                    .outline
                                    .withAlpha(100),
                            hintText: _isSearching
                                ? 'Searching...'
                                : 'Where would you like to go? Or click 👉',
                            hintStyle: TextStyle(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withValues(alpha: 0.6),
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(20),
                              borderSide: BorderSide(
                                color: Theme.of(context).colorScheme.outline,
                                width: 2,
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(20),
                              borderSide: BorderSide(
                                color: Theme.of(context).colorScheme.outline,
                                width: 2,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(20),
                              borderSide: BorderSide(
                                color: Theme.of(context).colorScheme.primary,
                                width: 2,
                              ),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 20,
                            ),
                            suffixIcon: Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: ElevatedButton(
                                onPressed: _isSearching
                                    ? null
                                    : () => _onSearchSubmitted(
                                        _placeTextController.text),
                                style: ElevatedButton.styleFrom(
                                  elevation: 2,
                                  backgroundColor:
                                      Theme.of(context).colorScheme.primary,
                                  disabledBackgroundColor: Theme.of(context)
                                      .colorScheme
                                      .primary
                                      .withAlpha(100),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 24,
                                    vertical: 16,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(15),
                                  ),
                                ),
                                child: _isSearching
                                    ? SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                            Theme.of(context)
                                                .colorScheme
                                                .onPrimary,
                                          ),
                                        ),
                                      )
                                    : Text(
                                        'Get Started',
                                        style: TextStyle(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onPrimary,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 14,
                                        ),
                                      ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 300),
          alignment: Alignment.topCenter,
          child: _hasPlaceFieldFocus || _placeTextController.text.isNotEmpty
              // TODO: Add the top places view here
              ? Container(
                  height: 400,
                  width: double.infinity,
                  color: Theme.of(context).colorScheme.primary,
                )
              : SizedBox(width: double.infinity),
        ),
      ],
    );
  }
}
