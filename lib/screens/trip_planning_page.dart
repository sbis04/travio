import 'dart:math';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:pointer_interceptor/pointer_interceptor.dart';
import 'package:travio/models/document.dart';
import 'package:travio/models/place.dart';
import 'package:travio/models/trip.dart';
import 'package:travio/services/auth_service.dart';
import 'package:travio/services/document_service.dart';
import 'package:travio/services/place_photo_cache_service.dart';
import 'package:travio/services/trip_service.dart';
import 'package:travio/utils/utils.dart';
import 'package:travio/widgets/app_header.dart';
import 'package:travio/widgets/page_loading_indicator.dart';
import 'package:travio/widgets/restricted_access_view.dart';
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
  bool get _userHasAccess =>
      (_trip?.isPublic ?? true) || _trip?.userUid == AuthService.currentUserUid;

  // Sidebar state
  String _selectedSection = ''; // Will be set to first available section

  // Map state
  Set<Marker> _markers = {};

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  Future<void> _initializeData() async {
    await Future.wait([
      _loadTripData(),
      _loadVisitPlaces(),
      _loadAccommodationData(),
      _loadFlightData(),
    ]);

    // if (mounted) {
    //   _setDefaultSelectedSection();
    // }
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

      // Initialize markers after loading visit places
      _initializeAllPlaceMarkers();
    } catch (e) {
      logPrint('❌ Error loading visit places: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _initializeAllPlaceMarkers() {
    _updateMarkersWithSelection(null); // Initialize with no selection
  }

  void _updateMarkersWithSelection(String? selectedPlaceId) {
    final markers = <Marker>{};

    // Add markers for all visit places that have coordinates
    for (final place in _visitPlaces) {
      if (place.latitude != null && place.longitude != null) {
        final isSelected = selectedPlaceId == place.placeId;

        markers.add(
          Marker(
            markerId: MarkerId(place.placeId),
            position: LatLng(place.latitude!, place.longitude!),
            infoWindow: InfoWindow(
              title: place.name,
              snippet: place.displayAddress,
            ),
            icon: BitmapDescriptor.defaultMarkerWithHue(
              isSelected ? BitmapDescriptor.hueRed : BitmapDescriptor.hueBlue,
            ),
            alpha: isSelected || selectedPlaceId == null
                ? 1.0
                : 0.6, // Full opacity for selected, dimmed for others
          ),
        );
      }
    }

    logPrint(
        '🗺️ Updated ${markers.length} place markers (selected: $selectedPlaceId)');

    setState(() => _markers = markers);
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

    // Initialize map with all visit place markers
    _initializeAllPlaceMarkers();

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
          : !_userHasAccess
              ? Column(
                  children: [
                    AppHeader(
                      hideButtons: true,
                      hideThemeToggle: true,
                    ),
                    Expanded(
                      child: RestrictedAccessView(),
                    ),
                  ],
                )
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

  Widget _buildLeftSideSection() {
    return Container(
      width: 250,
      color: Theme.of(context).colorScheme.primaryContainer,
      height: double.infinity,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with logo
          Padding(
            padding: const EdgeInsets.all(16),
            child: AppLogo(),
          ),

          const SizedBox(height: 8),

          // Conditional sections based on available data
          if (_flightInfo.isNotEmpty)
            _buildSidebarSection(
              id: 'flights',
              title: 'Flights',
              icon: Icons.flight_rounded,
              count: _flightInfo.length,
              isSelected: _selectedSection == 'flights',
              onTap: (isExpanded) => setState(
                  () => _selectedSection = isExpanded ? '' : 'flights'),
            ),

          if (_accommodationInfo.isNotEmpty) ...[
            const SizedBox(height: 2),
            _buildSidebarSection(
              id: 'accommodations',
              title: 'Accommodations',
              icon: Icons.hotel_rounded,
              count: _accommodationInfo.length,
              isSelected: _selectedSection == 'accommodations',
              onTap: (isExpanded) => setState(
                  () => _selectedSection = isExpanded ? '' : 'accommodations'),
            ),
          ],

          if (_visitPlaces.isNotEmpty) ...[
            const SizedBox(height: 2),
            _buildSidebarSection(
              id: 'places',
              title: 'Places to visit',
              icon: Icons.place_rounded,
              count: _visitPlaces.length,
              isSelected: _selectedSection == 'places',
              onTap: (isExpanded) =>
                  setState(() => _selectedSection = isExpanded ? '' : 'places'),
            ),
          ],

          Divider(
            color: Theme.of(context).colorScheme.outline,
            thickness: 1,
            height: 50,
          ),

          // Itinerary section
          Expanded(
            child: _buildItinerarySection(),
          ),

          // Hide sidebar button at bottom
          // Padding(
          //   padding: const EdgeInsets.all(16),
          //   child: TextButton.icon(
          //     onPressed: () {
          //       // TODO: Implement sidebar hide/show
          //     },
          //     icon: Icon(
          //       Icons.chevron_left,
          //       size: 16,
          //       color: Theme.of(context)
          //           .colorScheme
          //           .onPrimaryContainer
          //           .withValues(alpha: 0.7),
          //     ),
          //     label: Text(
          //       'Hide sidebar',
          //       style: Theme.of(context).textTheme.bodySmall?.copyWith(
          //             color: Theme.of(context)
          //                 .colorScheme
          //                 .onPrimaryContainer
          //                 .withValues(alpha: 0.7),
          //           ),
          //     ),
          //     style: TextButton.styleFrom(
          //       padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          //     ),
          //   ),
          // ),
        ],
      ),
    );
  }

  Widget _buildSidebarSection({
    required String id,
    required String title,
    required IconData icon,
    required bool isSelected,
    required Function(bool isExpanded) onTap,
    int? count,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => onTap(isSelected),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: isSelected
                ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.1)
                : Colors.transparent,
          ),
          child: Row(
            children: [
              Icon(
                icon,
                size: 18,
                color: isSelected
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.8),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight:
                            isSelected ? FontWeight.w600 : FontWeight.w500,
                        color: isSelected
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(context).colorScheme.onSurface,
                      ),
                ),
              ),
              if (count != null && count > 0)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    count.toString(),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: isSelected
                              ? Theme.of(context).colorScheme.onPrimary
                              : Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withValues(alpha: 0.8),
                        ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildItinerarySection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Itinerary header
          Row(
            children: [
              Icon(
                Icons.calendar_today_outlined,
                size: 16,
                color: Theme.of(context).colorScheme.onSurface,
              ),
              const SizedBox(width: 8),
              Text(
                'Planning',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Itinerary timeline
          Expanded(
            child: _buildItineraryTimeline(),
          ),
        ],
      ),
    );
  }

  Widget _buildItineraryTimeline() {
    if (_trip?.startDate == null || _trip?.endDate == null) {
      return Container(
        padding: const EdgeInsets.all(16),
        child: Text(
          'Set trip dates to see itinerary',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context)
                    .colorScheme
                    .onPrimaryContainer
                    .withValues(alpha: 0.6),
              ),
        ),
      );
    }

    // Generate itinerary items based on trip data
    final itineraryItems = _generateItineraryItems();

    return ScrollConfiguration(
      behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
      child: ListView.builder(
        padding: EdgeInsets.only(bottom: 50),
        itemCount: itineraryItems.length,
        itemBuilder: (context, index) {
          final item = itineraryItems[index];
          return _buildItineraryItem(item);
        },
      ),
    );
  }

  List<ItineraryItem> _generateItineraryItems() {
    final items = <ItineraryItem>[];

    if (_trip?.startDate == null || _trip?.endDate == null) return items;

    final startDate = _trip!.startDate!;
    final endDate = _trip!.endDate!;
    final totalDays = endDate.difference(startDate).inDays + 1;

    for (int i = 0; i < totalDays; i++) {
      final currentDate = startDate.add(Duration(days: i));
      final dayNumber = i + 1;

      // Check for flights on this date
      final dayFlights = _flightInfo.where((flight) {
        return flight.departureTime != null &&
            _isSameDay(flight.departureTime!, currentDate);
      }).toList();

      // Check for accommodations on this date
      final dayAccommodations = _accommodationInfo.where((accommodation) {
        return accommodation.checkInDate != null &&
            _isSameDay(accommodation.checkInDate!, currentDate);
      }).toList();

      // Determine day description
      String description;
      if (i == 0 && dayFlights.isNotEmpty) {
        description = 'Arrive in ${_trip!.placeName}';
      } else if (i == totalDays - 1 && dayFlights.isNotEmpty) {
        description = 'Departure';
      } else if (dayAccommodations.isNotEmpty) {
        description =
            'Check-in ${dayAccommodations.first.hotelName ?? 'Hotel'}';
      } else if (dayFlights.isNotEmpty) {
        final flight = dayFlights.first;
        description = '${flight.originCode} - ${flight.destinationCode}';
      } else {
        description = 'Explore ${_trip!.placeName}';
      }

      items.add(ItineraryItem(
        date: currentDate,
        dayNumber: dayNumber,
        description: description,
        hasFlights: dayFlights.isNotEmpty,
        hasAccommodations: dayAccommodations.isNotEmpty,
      ));
    }

    return items;
  }

  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  Widget _buildItineraryItem(ItineraryItem item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Date header
          Text(
            _formatItineraryDate(item.date),
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(fontWeight: FontWeight.w600),
          ),

          const SizedBox(height: 4),

          // Description
          Text(
            item.description,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.5),
                ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),

          // Activity indicators
          if (item.hasFlights || item.hasAccommodations) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                if (item.hasFlights) ...[
                  Icon(
                    Icons.flight_takeoff,
                    size: 12,
                    color: Theme.of(context)
                        .colorScheme
                        .primary
                        .withValues(alpha: 0.7),
                  ),
                  const SizedBox(width: 4),
                ],
                if (item.hasAccommodations) ...[
                  Icon(
                    Icons.hotel,
                    size: 12,
                    color: Theme.of(context)
                        .colorScheme
                        .primary
                        .withValues(alpha: 0.7),
                  ),
                ],
              ],
            ),
          ],
        ],
      ),
    );
  }

  String _formatItineraryDate(DateTime date) {
    const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
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

    final weekday = weekdays[date.weekday - 1];
    final month = months[date.month - 1];

    return '$weekday, $month ${date.day}';
  }

  Widget _buildPlanningSection() {
    if (_trip?.startDate == null || _trip?.endDate == null) {
      return const SizedBox();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Planning section title
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Text(
            'Planning',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
        ),

        const SizedBox(height: 16),

        // Date-based expandable sections
        ..._buildDateSections(),
      ],
    );
  }

  List<Widget> _buildDateSections() {
    if (_trip?.startDate == null || _trip?.endDate == null) return [];

    final startDate = _trip!.startDate!;
    final endDate = _trip!.endDate!;
    final totalDays = endDate.difference(startDate).inDays + 1;

    final widgets = <Widget>[];

    for (int i = 0; i < totalDays; i++) {
      final currentDate = startDate.add(Duration(days: i));

      // Check for activities on this date
      final dayFlights = _flightInfo.where((flight) {
        return flight.departureTime != null &&
            _isSameDay(flight.departureTime!, currentDate);
      }).toList();

      final dayAccommodations = _accommodationInfo.where((accommodation) {
        return accommodation.checkInDate != null &&
            _isSameDay(accommodation.checkInDate!, currentDate);
      }).toList();

      // Determine activity count for the day
      final activityCount = dayFlights.length + dayAccommodations.length;

      // Create expandable section for this date
      widgets.add(
        ExpandableSection(
          title: _formatPlanningDate(currentDate),
          count: activityCount,
          icon: _getDateIcon(currentDate, dayFlights, dayAccommodations),
          initiallyExpanded: false, // Collapsed by default
          child: const SizedBox(
            height: 200, // Placeholder height for future content
            child: Center(
              child: Text('Day planning content will go here'),
            ),
          ),
        ),
      );

      // Add spacing between date sections (except for last item)
      if (i < totalDays - 1) {
        widgets.add(const SizedBox(height: 16));
      }
    }

    return widgets;
  }

  String _formatPlanningDate(DateTime date) {
    const weekdays = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday'
    ];
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

    final weekday = weekdays[date.weekday - 1];
    final month = months[date.month - 1];

    return '$weekday, $month ${date.day}';
  }

  IconData _getDateIcon(DateTime date, List<FlightInformation> dayFlights,
      List<AccommodationInformation> dayAccommodations) {
    // Priority: Flight > Accommodation > General day
    if (dayFlights.isNotEmpty) {
      return Icons.flight_takeoff;
    } else if (dayAccommodations.isNotEmpty) {
      return Icons.hotel;
    } else {
      return Icons.calendar_today;
    }
  }

  // void _setDefaultSelectedSection() {
  //   if (_selectedSection.isNotEmpty) return; // Already set

  //   // Set to first available section
  //   if (_flightInfo.isNotEmpty) {
  //     _selectedSection = 'flights';
  //   } else if (_accommodationInfo.isNotEmpty) {
  //     _selectedSection = 'accommodations';
  //   } else if (_visitPlaces.isNotEmpty) {
  //     _selectedSection = 'places';
  //   }

  //   if (mounted) {
  //     setState(() {});
  //   }
  // }

  Widget _buildExpandableSections() {
    return Column(
      children: [
        // Flight Section (always present if data exists)
        if (_flightInfo.isNotEmpty) ...[
          ExpandableSection(
            title: 'Flights',
            count: _flightInfo.length,
            icon: Icons.flight_rounded,
            initiallyExpanded: _selectedSection == 'flights',
            child: FlightSection(flightInfo: _flightInfo),
          ),
          const SizedBox(height: 16),
        ],

        // Accommodation Section (always present if data exists)
        if (_accommodationInfo.isNotEmpty) ...[
          ExpandableSection(
            title: 'Accommodations',
            count: _accommodationInfo.length,
            icon: Icons.hotel_rounded,
            initiallyExpanded: _selectedSection == 'accommodations',
            child: AccommodationSection(accommodationInfo: _accommodationInfo),
          ),
          const SizedBox(height: 16),
        ],

        // Places to Visit Section (always present if data exists)
        if (_visitPlaces.isNotEmpty) ...[
          ExpandableSection(
            title: 'Places to visit',
            count: _visitPlaces.length,
            icon: Icons.place_rounded,
            initiallyExpanded: _selectedSection == 'places',
            child: PlacesSection(
              visitPlaces: _visitPlaces,
              onPlaceSelected: _onPlaceSelected,
            ),
          ),
        ],
      ],
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
            _buildLeftSideSection(),
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
                      // All sections with selective expansion
                      _buildExpandableSections(),
                      const SizedBox(height: 24),
                      _buildPlanningSection(),
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
              onTap: (LatLng position) {
                // Reset selection when tapping on empty map area
                _resetPlaceSelection();
              },
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
              markers: _markers,
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

  Future<void> _onPlaceSelected(Place place) async {
    if (_mapController == null ||
        place.latitude == null ||
        place.longitude == null) {
      logPrint(
          '❌ Cannot animate to place: Map controller or coordinates not available');
      return;
    }

    try {
      logPrint('📍 Animating map to place: ${place.name}');
      logPrint('   Coordinates: ${place.latitude}, ${place.longitude}');

      final placeLocation = LatLng(place.latitude!, place.longitude!);

      // Update markers to highlight selected place
      _updateMarkersWithSelection(place.placeId);

      // Animate camera to the selected place
      await _mapController!.animateCamera(
        CameraUpdate.newLatLngZoom(placeLocation, 12),
      );

      logPrint('✅ Map animated to place: ${place.name}');
    } catch (e) {
      logPrint('❌ Error animating map to place: $e');
    }
  }

  void _resetPlaceSelection() {
    logPrint(
        '🔄 Resetting place selection - showing all markers at full opacity');
    _updateMarkersWithSelection(null);
  }
}

/// Data model for itinerary timeline items
class ItineraryItem {
  final DateTime date;
  final int dayNumber;
  final String description;
  final bool hasFlights;
  final bool hasAccommodations;

  ItineraryItem({
    required this.date,
    required this.dayNumber,
    required this.description,
    this.hasFlights = false,
    this.hasAccommodations = false,
  });
}
