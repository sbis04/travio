import 'dart:math';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:pointer_interceptor/pointer_interceptor.dart';
import 'package:travio/models/document.dart';
import 'package:travio/models/place.dart';
import 'package:travio/models/trip.dart';
import 'package:travio/services/document_service.dart';
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
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(
          right: 8,
          top: 16,
        ),
        child: PointerInterceptor(
          child: AppThemeToggle(opacity: 1),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endTop,
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
  List<Place> _visitPlaces = [];
  List<FlightInformation> _flightInfo = [];
  List<AccommodationInformation> _accommodationInfo = [];
  GoogleMapController? _mapController;

  @override
  void initState() {
    super.initState();
    _loadTripData();
    _loadVisitPlaces();
    _loadAccommodationData();
    _loadFlightData();
  }

  Future<void> _loadFlightData() async {
    try {
      logPrint('✈️ Loading flight data for trip: ${widget.tripId}');

      // Get all documents for this trip
      final documents = await DocumentService.getDocuments(widget.tripId);
      final flightDocuments =
          documents.where((doc) => doc.type == DocumentType.flight).toList();

      // Load flight info from subcollections
      await _loadAllFlightInfo(flightDocuments);

      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        logPrint('✅ Loaded ${flightDocuments.length} flight document(s)');
        logPrint('✈️ Total flights: ${_flightInfo.length}');
      }
    } catch (e) {
      logPrint('❌ Error loading flight data: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _loadAllFlightInfo(List<TripDocument> flightDocuments) async {
    try {
      final List<FlightInformation> allFlights = [];

      for (final document in flightDocuments) {
        try {
          final flightCollection = await DocumentService.firestore
              .collection('trips')
              .doc(widget.tripId)
              .collection('documents')
              .doc(document.id)
              .collection('flight_info')
              .orderBy('flight_index')
              .get();

          for (final doc in flightCollection.docs) {
            try {
              final flightInfo = FlightInformation.fromFirestore(doc.data());
              allFlights.add(flightInfo);
            } catch (e) {
              logPrint('⚠️ Error parsing flight ${doc.id}: $e');
            }
          }
        } catch (e) {
          logPrint('❌ Error loading flights from document ${document.id}: $e');
        }
      }

      if (mounted) {
        setState(() => _flightInfo = allFlights);
      }
    } catch (e) {
      logPrint('❌ Error in batch flight info loading: $e');
    }
  }

  Future<void> _loadAccommodationData() async {
    try {
      logPrint('🏨 Loading accommodation data for trip: ${widget.tripId}');

      // Get all documents for this trip
      final documents = await DocumentService.getDocuments(widget.tripId);
      final hotelDocuments =
          documents.where((doc) => doc.type == DocumentType.hotel).toList();

      // Load accommodation info from subcollections
      await _loadAllAccommodationInfo(hotelDocuments);

      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        logPrint('✅ Loaded ${hotelDocuments.length} hotel document(s)');
        logPrint('🏨 Total accommodations: ${_accommodationInfo.length}');
      }
    } catch (e) {
      logPrint('❌ Error loading accommodation data: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _loadAllAccommodationInfo(
      List<TripDocument> hotelDocuments) async {
    try {
      final List<AccommodationInformation> allAccommodations = [];

      for (final document in hotelDocuments) {
        try {
          final accommodationCollection = await DocumentService.firestore
              .collection('trips')
              .doc(widget.tripId)
              .collection('documents')
              .doc(document.id)
              .collection('accommodation_info')
              .orderBy('accommodation_index')
              .get();

          for (final doc in accommodationCollection.docs) {
            try {
              final accommodationInfo =
                  AccommodationInformation.fromFirestore(doc.data());
              allAccommodations.add(accommodationInfo);
            } catch (e) {
              logPrint('⚠️ Error parsing accommodation ${doc.id}: $e');
            }
          }
        } catch (e) {
          logPrint(
              '❌ Error loading accommodations from document ${document.id}: $e');
        }
      }

      if (mounted) {
        setState(() => _accommodationInfo = allAccommodations);
      }
    } catch (e) {
      logPrint('❌ Error in batch accommodation info loading: $e');
    }
  }

  Future<void> _loadVisitPlaces() async {
    try {
      logPrint('📍 Loading visit places for trip: ${widget.tripId}');

      final places = await TripService.getVisitPlaces(widget.tripId);

      safeSetState(() {
        _visitPlaces = places;
        _isLoading = false;
      });

      logPrint('✅ Loaded ${places.length} visit place(s)');
    } catch (e) {
      logPrint('❌ Error loading visit places: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
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

      safeSetState(() {
        _trip = trip;
        _placeImages = images;
        _isLoading = false;
      });

      logPrint('✅ Trip planning data loaded: ${trip.placeName}');
      logPrint('📸 Loaded ${images.length} images for place');
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
    final screenSize = MediaQuery.sizeOf(context);
    final screenWidth = screenSize.width;
    final planningAreaWidth = max(min(screenWidth * 0.5, 800.0), 630.0);
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
                    SizedBox(
                      width: planningAreaWidth,
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
                    SizedBox(
                        width: planningAreaWidth,
                        child: _buildContentSection()),
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
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 250,
              color: Theme.of(context).colorScheme.primaryContainer,
              height: double.infinity,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: AppLogo(),
                  ),
                ],
              ),
            ),
            VerticalDivider(
              color: Theme.of(context).colorScheme.outline,
              width: 1,
              thickness: 1,
            ),
            Expanded(
              child: ScrollConfiguration(
                behavior:
                    ScrollConfiguration.of(context).copyWith(scrollbars: false),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.only(bottom: 60),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Auto-sliding images with overlay
                      _buildImageSection(),
                      const SizedBox(height: 24),
                      // Expandable sections
                      _buildExpandableSections(),
                    ],
                  ),
                ),
              ),
            ),
          ],
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
          count: _flightInfo.length,
          icon: Icons.flight_rounded,
          child: FlightSection(flightInfo: _flightInfo),
        ),

        // Accommodation Section
        if (_accommodationInfo.isNotEmpty) ...[
          const SizedBox(height: 16),
          ExpandableSection(
            title: 'Accommodations',
            count: _accommodationInfo.length,
            icon: Icons.hotel_rounded,
            child: AccommodationSection(accommodationInfo: _accommodationInfo),
          ),
        ],

        // Places to Visit Section
        if (_visitPlaces.isNotEmpty) ...[
          const SizedBox(height: 16),
          ExpandableSection(
            title: 'Places to visit',
            count: _visitPlaces.length,
            icon: Icons.place_rounded,
            child: PlacesSection(visitPlaces: _visitPlaces),
          ),
        ],
      ],
    );
  }

  Widget _buildMapSection() {
    return _trip?.latitude != null && _trip?.longitude != null
        ? AnimatedOpacity(
            opacity: _isMapLoading ? 0.01 : 1.0,
            duration: const Duration(milliseconds: 600),
            child: GoogleMap(
              style: Theme.of(context).brightness == Brightness.light
                  ? kGoogleMapsLightStyle
                  : kGoogleMapsDarkStyle,
              onMapCreated: _onMapCreated,
              myLocationEnabled: false,
              buildingsEnabled: false,
              compassEnabled: false,
              zoomControlsEnabled: false,
              zoomGesturesEnabled: true,
              scrollGesturesEnabled: true,
              tiltGesturesEnabled: true,
              rotateGesturesEnabled: true,
              trafficEnabled: false,
              mapToolbarEnabled: false,
              myLocationButtonEnabled: false,
              webCameraControlEnabled: false,
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
