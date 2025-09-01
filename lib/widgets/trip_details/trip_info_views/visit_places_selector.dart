import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:travio/models/place.dart';
import 'package:travio/services/places_service.dart';
import 'package:travio/utils/utils.dart';

class VisitPlacesSelectorView extends StatefulWidget {
  const VisitPlacesSelectorView({
    super.key,
    required this.selectedPlaceId,
    this.initialSelectedPlaces = const [],
    this.onSelectedPlacesChanged,
  });

  final String selectedPlaceId;
  final List<Place> initialSelectedPlaces;
  final ValueChanged<List<Place>>? onSelectedPlacesChanged;

  @override
  State<VisitPlacesSelectorView> createState() =>
      _VisitPlacesSelectorViewState();
}

class _VisitPlacesSelectorViewState extends State<VisitPlacesSelectorView> {
  List<Place> _popularPlaces = [];
  List<Place> _selectedPlaces = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    // Initialize with existing selected places
    _selectedPlaces = List.from(widget.initialSelectedPlaces);
    _loadPopularPlaces();
  }

  @override
  void didUpdateWidget(VisitPlacesSelectorView oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Update selected places if they changed from parent
    if (oldWidget.initialSelectedPlaces != widget.initialSelectedPlaces) {
      setState(() {
        _selectedPlaces = List.from(widget.initialSelectedPlaces);
      });
    }
  }

  Future<void> _loadPopularPlaces() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final places = await PlacesService.getPopularPlaces(
        placeId: widget.selectedPlaceId,
        maxResults: 20,
      );

      if (mounted) {
        setState(() {
          _popularPlaces = places;
          _isLoading = false;
        });
      }
    } catch (e) {
      logPrint('❌ Error loading popular places: $e');
      if (mounted) {
        setState(() {
          _error = 'Failed to load popular places';
          _isLoading = false;
        });
      }
    }
  }

  void _togglePlaceSelection(Place place) {
    setState(() {
      // Check if place is already selected by placeId (more reliable than object equality)
      final existingIndex =
          _selectedPlaces.indexWhere((p) => p.placeId == place.placeId);

      if (existingIndex != -1) {
        // Remove if already selected
        _selectedPlaces.removeAt(existingIndex);
      } else {
        // Add if not selected
        _selectedPlaces.add(place);
      }
    });

    // Notify parent about selection changes
    widget.onSelectedPlacesChanged?.call(_selectedPlaces);
  }

  bool _isPlaceSelected(Place place) {
    return _selectedPlaces.any((p) => p.placeId == place.placeId);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32.0),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.error_outline,
                size: 48,
                color: Theme.of(context).colorScheme.error,
              ),
              const SizedBox(height: 16),
              Text(
                _error!,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Theme.of(context).colorScheme.error,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadPopularPlaces,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (_popularPlaces.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Text(
            'No popular places found for this destination.',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.6),
                ),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AnimatedSize(
          duration: 300.ms,
          curve: Curves.easeInOut,
          alignment: Alignment.topLeft,
          child: _selectedPlaces.isNotEmpty
              ? Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: SizedBox(
                    width: double.infinity,
                    child: Text(
                      '${_selectedPlaces.length} place${_selectedPlaces.length == 1 ? '' : 's'} selected',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            color: Theme.of(context).colorScheme.primary,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ),
                )
              : const SizedBox(width: double.infinity),
        ),
        Expanded(
          child: LayoutBuilder(builder: (context, constraints) {
            final crossAxisCount = constraints.maxWidth > 820
                ? 3
                : constraints.maxWidth > 550
                    ? 2
                    : 1;
            final childAspectRatio = crossAxisCount == 1 ? 1.5 : 1.0;
            return Padding(
              padding: const EdgeInsets.only(bottom: 24),
              child: GridView.builder(
                padding: EdgeInsets.only(bottom: 16),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                  childAspectRatio: childAspectRatio,
                ),
                itemCount: _popularPlaces.length,
                itemBuilder: (context, index) {
                  final place = _popularPlaces[index];
                  final isSelected = _isPlaceSelected(place);

                  return _PopularPlaceCard(
                    place: place,
                    isSelected: isSelected,
                    hasSelected: _selectedPlaces.isNotEmpty,
                    onTap: () => _togglePlaceSelection(place),
                  );
                },
              ),
            );
          }),
        ),
      ],
    );
  }
}

class _PopularPlaceCard extends StatelessWidget {
  const _PopularPlaceCard({
    required this.place,
    required this.isSelected,
    required this.hasSelected,
    required this.onTap,
  });

  final Place place;
  final bool isSelected;
  final bool hasSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Image section
                Expanded(
                  flex: 4,
                  child: ClipRRect(
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(10),
                      topRight: Radius.circular(10),
                    ),
                    child: AnimatedOpacity(
                      opacity: isSelected
                          ? 1.0
                          : hasSelected
                              ? 0.6
                              : 1.0,
                      duration: 200.ms,
                      child: Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Theme.of(context)
                              .colorScheme
                              .outline
                              .withValues(alpha: 0.2),
                        ),
                        child: place.photoUrls.isNotEmpty
                            ? CachedNetworkImage(
                                imageUrl: place.photoUrls.first,
                                fit: BoxFit.cover,
                              )
                            : const SizedBox.shrink(),
                      ),
                    ),
                  ),
                ),
                // Content section
                Expanded(
                  flex: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          place.name,
                          style:
                              Theme.of(context).textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    height: 1.2,
                                  ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        if (place.rating != null) ...[
                          Row(
                            children: [
                              Icon(
                                Icons.star_rounded,
                                size: 16,
                                color: Colors.amber[700],
                              ),
                              const SizedBox(width: 4),
                              Text(
                                place.rating!.toStringAsFixed(1),
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurface
                                          .withValues(alpha: 0.7),
                                      fontWeight: FontWeight.w600,
                                    ),
                              ),
                              if (place.userRatingsTotal != null) ...[
                                Text(
                                  ' ( ${place.userRatingsTotal} )',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.copyWith(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSurface
                                            .withValues(alpha: 0.5),
                                        fontWeight: FontWeight.w600,
                                      ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
            // Selection indicator
            Positioned(
              top: 8,
              right: 8,
              child: AnimatedContainer(
                duration: 200.ms,
                decoration: BoxDecoration(
                  color: isSelected
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context)
                          .colorScheme
                          .surface
                          .withValues(alpha: 0.8),
                  shape: BoxShape.circle,
                ),
                padding: const EdgeInsets.all(4),
                child: Icon(
                  isSelected ? Icons.check : Icons.add,
                  size: 16,
                  color: isSelected
                      ? Theme.of(context).colorScheme.onPrimary
                      : Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.6),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
