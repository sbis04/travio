import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:travio/models/place.dart';
import 'package:travio/models/trip.dart';
import 'package:travio/services/places_service.dart';
import 'package:travio/utils/utils.dart';
import 'package:travio/widgets/place_search_field.dart';

class SelectDestinationView extends StatefulWidget {
  const SelectDestinationView({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.onPlaceSelected,
    required this.onSubmitted,
    required this.isSearching,
    this.trip,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final Function(Place) onPlaceSelected;
  final Function(String) onSubmitted;
  final bool isSearching;
  final Trip? trip;

  @override
  State<SelectDestinationView> createState() => _SelectDestinationViewState();
}

class _SelectDestinationViewState extends State<SelectDestinationView> {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Place search field
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 550),
          child: PlaceSearchField(
            controller: widget.controller,
            focusNode: widget.focusNode,
            isSearching: widget.isSearching,
            onPlaceSelected: widget.onPlaceSelected,
            onSubmitted: widget.onSubmitted,
            hintText: 'Where would you like to go? ✈️',
          ),
        ),

        // Place photos section
        if (widget.trip != null) ...[
          const SizedBox(height: 32),
          StaggeredPlacePhotosGrid(placeId: widget.trip!.placeId),
        ],
      ],
    );
  }
}

class StaggeredPlacePhotosGrid extends StatefulWidget {
  const StaggeredPlacePhotosGrid({
    super.key,
    required this.placeId,
  });

  final String placeId;

  @override
  State<StaggeredPlacePhotosGrid> createState() =>
      _StaggeredPlacePhotosGridState();
}

class _StaggeredPlacePhotosGridState extends State<StaggeredPlacePhotosGrid> {
  List<String> _placePhotos = [];

  Future<void> _loadPlacePhotos() async {
    try {
      final photos = await PlacesService.getPlacePhotos(
        placeId: widget.placeId,
        maxPhotos: 20,
        maxWidth: 800,
      );

      if (mounted) {
        setState(() => _placePhotos = photos);
      }
    } catch (e) {
      logPrint('❌ Error loading place photos: $e');
    }
  }

  @override
  void initState() {
    super.initState();
    _loadPlacePhotos();
  }

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.only(bottom: 24),
        child: MasonryGridView.count(
          padding: EdgeInsets.only(bottom: 50),
          crossAxisCount: 3,
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          itemCount: _placePhotos.length,
          itemBuilder: (context, index) {
            final photoUrl = _placePhotos[index];

            return ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: CachedNetworkImage(
                imageUrl: photoUrl,
                fit: BoxFit.cover,
                alignment: Alignment.center,
              ),
            );
          },
        ),
      ),
    );
  }
}
