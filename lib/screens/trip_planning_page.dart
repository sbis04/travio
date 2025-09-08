import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:travio/models/trip.dart';
import 'package:travio/services/place_photo_cache_service.dart';
import 'package:travio/services/trip_service.dart';
import 'package:travio/utils/utils.dart';
import 'package:travio/widgets/app_header.dart';
import 'package:travio/widgets/page_loading_indicator.dart';
import 'package:travio/widgets/trip_planning/auto_sliding_images.dart';
import 'package:travio/widgets/trip_planning/expandable_section.dart';
import 'package:travio/widgets/trip_planning/flight_section.dart';
import 'package:travio/widgets/trip_planning/accommodation_section.dart';
import 'package:travio/widgets/trip_planning/places_section.dart';

class TripPlanningPage extends StatelessWidget {
  const TripPlanningPage({super.key, required this.tripId});

  final String tripId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // const AppHeader(fullWidth: true),
          Expanded(
            child: TripPlanningSection(
              tripId: tripId,
            ),
          ),
        ],
      ),
    );
  }
}

class TripPlanningSection extends StatefulWidget {
  const TripPlanningSection({
    super.key,
    required this.tripId,
  });

  final String tripId;

  @override
  State<TripPlanningSection> createState() => _TripPlanningSectionState();
}

class _TripPlanningSectionState extends State<TripPlanningSection> {
  Trip? _trip;
  bool _isLoading = true;
  bool _isMapLoading = true;
  List<String> _placeImages = [];
  GoogleMapController? _mapController;

  @override
  void initState() {
    super.initState();
    _loadTripData();
  }

  Future<void> _loadTripData() async {
    try {
      logPrint('📱 Loading trip data for planning page: ${widget.tripId}');

      final trip = await TripService.getTrip(widget.tripId);
      if (trip == null) {
        logPrint('❌ Trip not found: ${widget.tripId}');
        return;
      }

      // Load place images from cache
      final images = await PlacePhotoCacheService.getPlacePhotos(
        placeId: trip.placeId,
        maxPhotos: 20,
      );

      if (mounted) {
        setState(() {
          _trip = trip;
          _placeImages = images;
          _isLoading = false;
        });

        logPrint('✅ Trip planning data loaded: ${trip.placeName}');
        logPrint('📸 Loaded ${images.length} images for place');
      }
    } catch (e) {
      logPrint('❌ Error loading trip planning data: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
    setState(() => _isMapLoading = false);

    // Center map on trip destination if coordinates available
    if (_trip?.latitude != null && _trip?.longitude != null) {
      _mapController?.animateCamera(
        CameraUpdate.newLatLng(
          LatLng(_trip!.latitude!, _trip!.longitude!),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return PageLoadingIndicator(
      isLoading: _isLoading,
      child: _trip == null
          ? const SizedBox()
          : Stack(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Left Side - Content
                    Expanded(
                      child: const SizedBox(),
                    ),
                    // Right Side - Map
                    Expanded(
                      child: _buildMapSection(),
                    ),
                  ],
                ),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Left Side - Content
                    Expanded(
                      child: _buildContentSection(),
                    ),
                    // Right Side - Map
                    Expanded(
                      child: const SizedBox(),
                    ),
                  ],
                ),
              ],
            ),
    );
  }

  Widget _buildContentSection() {
    return Material(
      clipBehavior: Clip.none,
      color: Theme.of(context).colorScheme.surface,
      elevation: 12,
      child: SizedBox(
        height: double.infinity,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Auto-sliding images with overlay
              _buildImageSection(),
              const SizedBox(height: 32),
              // Expandable sections
              Padding(
                padding: const EdgeInsets.only(
                  left: 24,
                  right: 24,
                  bottom: 24,
                ),
                child: _buildExpandableSections(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImageSection() {
    if (_placeImages.isEmpty) {
      return SizedBox(
        height: 200,
        child: Center(
          child: Text(
            'No images available',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.6),
                ),
          ),
        ),
      );
    }

    var boxDecoration = BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Theme.of(context).colorScheme.surface.withValues(alpha: 0),
          Theme.of(context).colorScheme.surface,
        ],
        stops: const [0, 0.42],
      ),
    );
    return SizedBox(
      height: 300,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Auto-sliding images
          AutoSlidingImages(
            images: _placeImages,
            height: 300,
          ),

          // Bottom fade overlay with trip info
          Positioned(
            bottom: -16,
            left: 0,
            right: 0,
            child: Container(
              height: 160,
              decoration: boxDecoration,
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    'Trip to ${_trip!.placeName}',
                    style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                  ),
                  if (_trip!.startDate != null && _trip!.endDate != null) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.calendar_month_outlined,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${_formatDate(_trip!.startDate!)} - ${_formatDate(_trip!.endDate!)}',
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurface
                                        .withValues(alpha: 0.8),
                                  ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExpandableSections() {
    return Column(
      children: [
        // Flight Section
        ExpandableSection(
          title: 'Flights',
          count: _trip!.documentInfo.hasFlightInfo
              ? 2
              : 0, // TODO: Get actual count
          icon: Icons.flight_takeoff,
          child: FlightSection(tripId: widget.tripId),
        ),

        const SizedBox(height: 16),

        // Accommodation Section
        ExpandableSection(
          title: 'Accommodations',
          count: _trip!.documentInfo.hasHotelInfo
              ? 1
              : 0, // TODO: Get actual count
          icon: Icons.hotel,
          child: AccommodationSection(tripId: widget.tripId),
        ),

        const SizedBox(height: 16),

        // Places to Visit Section
        ExpandableSection(
          title: 'Places to visit',
          count: 0, // TODO: Get actual count from visit places
          icon: Icons.place,
          child: PlacesSection(tripId: widget.tripId),
        ),
      ],
    );
  }

  Widget _buildMapSection() {
    return _trip?.latitude != null && _trip?.longitude != null
        ? AnimatedOpacity(
            opacity: _isMapLoading ? 0.01 : 1.0,
            duration: const Duration(milliseconds: 600),
            child: GoogleMap(
              onMapCreated: _onMapCreated,
              myLocationEnabled: false,
              buildingsEnabled: false,
              compassEnabled: false,
              zoomControlsEnabled: false,
              zoomGesturesEnabled: false,
              scrollGesturesEnabled: false,
              tiltGesturesEnabled: false,
              rotateGesturesEnabled: false,
              trafficEnabled: false,
              mapToolbarEnabled: false,
              initialCameraPosition: CameraPosition(
                target: LatLng(_trip!.latitude!, _trip!.longitude!),
                zoom: 12,
              ),
              // markers: {
              //   Marker(
              //     markerId: MarkerId(_trip!.placeId),
              //     position: LatLng(_trip!.latitude!, _trip!.longitude!),
              //     infoWindow: InfoWindow(
              //       title: _trip!.placeName,
              //       snippet: _trip!.placeAddress,
              //     ),
              //   ),
              // },
            ),
          )
        : Container(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.map_outlined,
                    size: 64,
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.3),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Map not available',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withValues(alpha: 0.6),
                        ),
                  ),
                  Text(
                    'Location coordinates not found',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withValues(alpha: 0.5),
                        ),
                  ),
                ],
              ),
            ),
          );
  }

  String _formatDate(DateTime date) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return '${date.day} ${months[date.month - 1]}, ${date.year}';
  }
}
