import 'dart:math';
import 'dart:ui';
import 'dart:typed_data';

import 'package:dotted_border/dotted_border.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:travio/models/document.dart';
import 'package:travio/services/document_service.dart';
import 'package:travio/services/storage_service.dart';
import 'package:travio/theme.dart';
import 'package:travio/utils/utils.dart';
import 'package:travio/widgets/sonnar.dart';

const _documentCardWidth = 150.0;

class BuildItineraryView extends StatefulWidget {
  const BuildItineraryView({
    super.key,
    required this.tripId,
  });

  final String tripId;

  @override
  State<BuildItineraryView> createState() => _BuildItineraryViewState();
}

class _BuildItineraryViewState extends State<BuildItineraryView> {
  List<TripDocument> _documents = [];
  List<TripDocument> _flightDocuments = [];
  List<TripDocument> _hotelDocuments = [];
  bool _isUploading = false;
  double _uploadProgress = 0.0;
  int _totalUploadBytes = 0;
  int _uploadedBytes = 0;
  late Stream<List<TripDocument>> _documentsStream;
  List<FlightInformation> _flightInfo = [];
  List<AccommodationInformation> _hotelInfo = [];

  @override
  void dispose() {
    super.dispose();
    _documentsStream.drain();
  }

  @override
  void initState() {
    super.initState();
    // Set up real-time document stream listener for automatic classification updates
    _documentsStream = DocumentService.watchDocuments(widget.tripId);
    _documentsStream.listen((documents) {
      if (mounted) {
        setState(() {
          _documents = documents;
          _flightDocuments = documents
              .where((doc) => doc.type == DocumentType.flight)
              .toList();
          _hotelDocuments =
              documents.where((doc) => doc.type == DocumentType.hotel).toList();
        });

        _getAllFlightInfo();
        _getAllHotelInfo();
      }
    });
  }

  Future<void> _getAllFlightInfo() async {
    try {
      logPrint(
          '🛫 Loading flight info for ${_flightDocuments.length} flight document(s)');

      if (_flightDocuments.isEmpty) {
        if (mounted) {
          setState(() => _flightInfo = []);
        }
        return;
      }

      // Batch query to get all flight info from all documents
      final List<FlightInformation> allFlights = [];

      // Use Future.wait to get all flight subcollections in parallel
      final futures = _flightDocuments.map((document) async {
        try {
          final flightCollection = await DocumentService.firestore
              .collection('trips')
              .doc(widget.tripId)
              .collection('documents')
              .doc(document.id)
              .collection('flight_info')
              .orderBy('flight_index')
              .get();

          final documentFlights = <FlightInformation>[];
          for (final doc in flightCollection.docs) {
            try {
              final flightInfo = FlightInformation.fromFirestore(doc.data());
              documentFlights.add(flightInfo);
            } catch (e) {
              logPrint('⚠️ Error parsing flight ${doc.id}: $e');
            }
          }

          logPrint(
              '✅ Loaded ${documentFlights.length} flight(s) from ${document.originalFileName}');
          return documentFlights;
        } catch (e) {
          logPrint('❌ Error loading flights from document ${document.id}: $e');
          return <FlightInformation>[];
        }
      });

      final results = await Future.wait(futures);

      // Flatten all flights from all documents
      for (final documentFlights in results) {
        allFlights.addAll(documentFlights);
      }

      if (mounted) {
        setState(() => _flightInfo = allFlights);
        logPrint('✅ Total flight info loaded: ${allFlights.length} flight(s)');
      }
    } catch (e) {
      logPrint('❌ Error in batch flight info loading: $e');
    }
  }

  Future<void> _getAllHotelInfo() async {
    try {
      logPrint(
          '🏨 Loading hotel info for ${_hotelDocuments.length} hotel document(s)');

      if (_hotelDocuments.isEmpty) {
        if (mounted) {
          setState(() => _hotelInfo = []);
        }
        return;
      }

      // Batch query to get all hotel info from all documents
      final List<AccommodationInformation> allHotels = [];

      // Use Future.wait to get all hotel subcollections in parallel
      final futures = _hotelDocuments.map((document) async {
        try {
          final hotelCollection = await DocumentService.firestore
              .collection('trips')
              .doc(widget.tripId)
              .collection('documents')
              .doc(document.id)
              .collection('accommodation_info')
              .orderBy('accommodation_index')
              .get();

          final documentHotels = <AccommodationInformation>[];
          for (final doc in hotelCollection.docs) {
            try {
              final hotelInfo =
                  AccommodationInformation.fromFirestore(doc.data());
              documentHotels.add(hotelInfo);
            } catch (e) {
              logPrint('⚠️ Error parsing hotel ${doc.id}: $e');
            }
          }

          logPrint(
              '✅ Loaded ${documentHotels.length} hotel(s) from ${document.originalFileName}');
          return documentHotels;
        } catch (e) {
          logPrint('❌ Error loading hotels from document ${document.id}: $e');
          return <AccommodationInformation>[];
        }
      });

      final results = await Future.wait(futures);

      // Flatten all hotels from all documents
      for (final documentHotels in results) {
        allHotels.addAll(documentHotels);
      }

      if (mounted) {
        setState(() => _hotelInfo = allHotels);
        logPrint('✅ Total hotel info loaded: ${allHotels.length} hotel(s)');
      }
    } catch (e) {
      logPrint('❌ Error in batch hotel info loading: $e');
    }
  }

  Future<void> _pickAndUploadDocuments() async {
    try {
      logPrint('📁 Opening file picker...');

      final result = await FilePicker.platform.pickFiles(
        allowMultiple: true,
        type: FileType.custom,
        allowedExtensions: DocumentService.supportedExtensions,
        withData: true, // Important for web
      );

      if (result == null || result.files.isEmpty) {
        logPrint('📁 No files selected');
        return;
      }

      logPrint('📁 Selected ${result.files.length} files');

      // Validate files
      final filesToUpload = <({
        String fileName,
        Uint8List bytes,
        String mimeType,
        DocumentType type,
        String? description
      })>[];

      for (final file in result.files) {
        if (file.bytes == null) {
          logPrint('⚠️ Skipping file with no data: ${file.name}');
          continue;
        }

        // Validate file
        if (!StorageService.validateFile(
          fileName: file.name,
          fileSizeBytes: file.bytes!.length,
        )) {
          AppSonnar.of(context).show(
            AppToast(
              title: Text('Invalid File'),
              description:
                  Text('${file.name} is invalid (check size and format)'),
              variant: AppToastVariant.destructive,
            ),
          );
          continue;
        }

        // Determine document type based on file extension
        final extension = file.name.split('.').last.toLowerCase();
        // TODO: Determine the file type
        DocumentType type = DocumentType.other;
        filesToUpload.add((
          fileName: file.name,
          bytes: file.bytes!,
          mimeType: _getMimeType(extension),
          type: type,
          description: null,
        ));
      }

      if (filesToUpload.isEmpty) {
        AppSonnar.of(context).show(
          AppToast(
            title: Text('No Valid Files'),
            description:
                Text('No valid files to upload. Check file format and size.'),
            variant: AppToastVariant.destructive,
          ),
        );
        return;
      }

      // Start uploading immediately
      await _uploadFiles(filesToUpload);
    } catch (e) {
      logPrint('❌ Error picking files: $e');
      AppSonnar.of(context).show(
        AppToast(
          title: Text('File Selection Error'),
          description: Text('Error selecting files: ${e.toString()}'),
          variant: AppToastVariant.destructive,
        ),
      );
    }
  }

  Future<void> _uploadFiles(
      List<
              ({
                String fileName,
                Uint8List bytes,
                String mimeType,
                DocumentType type,
                String? description
              })>
          files) async {
    try {
      // Calculate total bytes
      final totalBytes =
          files.fold<int>(0, (sum, file) => sum + file.bytes.length);

      setState(() {
        _isUploading = true;
        _uploadProgress = 0.0;
        _totalUploadBytes = totalBytes;
        _uploadedBytes = 0;
      });

      logPrint(
          '📊 Starting upload: ${StorageService.formatStorageSize(totalBytes)} total');

      // Show upload started toast
      AppSonnar.of(context).show(
        AppToast(
          title: Text('Uploading Documents'),
          description: Text(
            'Starting upload of ${StorageService.formatStorageSize(totalBytes)} (${files.length} file${files.length == 1 ? '' : 's'})',
          ),
          variant: AppToastVariant.primary,
        ),
      );

      final uploadedDocs = await DocumentService.uploadDocuments(
        tripId: widget.tripId,
        files: files,
        onProgress: (bytesUploaded, totalBytes) {
          if (mounted) {
            setState(() {
              _uploadProgress = bytesUploaded / totalBytes;
              _uploadedBytes = bytesUploaded;
            });
          }
        },
      );

      if (mounted) {
        // Show success toast
        AppSonnar.of(context).show(
          AppToast(
            title: Text('Upload Complete'),
            description: Text(
              'Successfully uploaded ${uploadedDocs.length} document${uploadedDocs.length == 1 ? '' : 's'} (${StorageService.formatStorageSize(_totalUploadBytes)}). Documents will be automatically classified.',
            ),
            variant: AppToastVariant.primary,
          ),
        );
      }
    } catch (e) {
      logPrint('❌ Upload error: $e');
      if (mounted) {
        // Show error toast
        AppSonnar.of(context).show(
          AppToast(
            title: Text('Upload Failed'),
            description: Text('Error uploading documents: ${e.toString()}'),
            variant: AppToastVariant.destructive,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
          _uploadProgress = 0.0;
          _totalUploadBytes = 0;
          _uploadedBytes = 0;
        });
      }
    }
  }

  String _getMimeType(String extension) {
    switch (extension.toLowerCase()) {
      case 'pdf':
        return 'application/pdf';
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'doc':
        return 'application/msword';
      case 'docx':
        return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
      default:
        return 'application/octet-stream';
    }
  }

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 650),
      child: Padding(
        padding: const EdgeInsets.only(bottom: 24),
        child: ScrollConfiguration(
          behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
            child: Column(
              spacing: 16,
              children: [
                Stack(
                  alignment: Alignment.center,
                  children: [
                    AnimatedOpacity(
                      opacity: _isUploading ? 0.5 : 1.0,
                      duration: 300.ms,
                      curve: Curves.easeInOut,
                      child: _documents.isEmpty
                          ? InkWell(
                              focusColor: Colors.transparent,
                              hoverColor: Colors.transparent,
                              highlightColor: Colors.transparent,
                              splashColor: Colors.transparent,
                              onTap:
                                  _isUploading ? null : _pickAndUploadDocuments,
                              child: Padding(
                                padding: const EdgeInsets.only(
                                    left: 8.0, right: 8.0),
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
                                            borderRadius:
                                                BorderRadius.circular(20),
                                            child: Padding(
                                              padding:
                                                  const EdgeInsets.all(8.0),
                                              child: Stack(
                                                alignment: Alignment.center,
                                                children: [
                                                  SizedBox(
                                                    height: 1.414 *
                                                        _documentCardWidth,
                                                    child: Opacity(
                                                      opacity: 0.4,
                                                      child: ListView.separated(
                                                        scrollDirection:
                                                            Axis.horizontal,
                                                        physics:
                                                            const NeverScrollableScrollPhysics(),
                                                        itemCount: 6,
                                                        separatorBuilder:
                                                            (context, index) =>
                                                                const SizedBox(
                                                                    width: 16),
                                                        itemBuilder: (context,
                                                                index) =>
                                                            const _DocumentCard(),
                                                      ),
                                                    ),
                                                  ),
                                                  BackdropFilter(
                                                    filter: ImageFilter.blur(
                                                      sigmaX: 2,
                                                      sigmaY: 2,
                                                    ),
                                                    child: SizedBox(),
                                                  )
                                                ],
                                              ),
                                            ),
                                          ),
                                        )
                                      ],
                                    ),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.add_circle_rounded,
                                          size: 40,
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onSurface,
                                        ),
                                        const SizedBox(width: 12),
                                        Text(
                                          'Add Documents',
                                          style: Theme.of(context)
                                              .textTheme
                                              .headlineSmall
                                              ?.copyWith(
                                                color: Theme.of(context)
                                                    .colorScheme
                                                    .onSurface,
                                                fontWeight: FontWeight.w600,
                                              ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            )
                          : Row(
                              spacing: 16,
                              children: [
                                InkWell(
                                  focusColor: Colors.transparent,
                                  hoverColor: Colors.transparent,
                                  highlightColor: Colors.transparent,
                                  splashColor: Colors.transparent,
                                  onTap: _isUploading
                                      ? null
                                      : _pickAndUploadDocuments,
                                  borderRadius: BorderRadius.circular(20),
                                  child: _DocumentCard(
                                    title: 'Add Documents',
                                    icon: Icons.add_circle_rounded,
                                    showTitle: true,
                                    useDottedBorder: true,
                                  ),
                                ),
                                Expanded(
                                  child: SizedBox(
                                    height: 1.414 * _documentCardWidth,
                                    child: ListView.separated(
                                      scrollDirection: Axis.horizontal,
                                      itemCount: _documents.length,
                                      separatorBuilder: (context, index) =>
                                          const SizedBox(width: 16),
                                      itemBuilder: (context, index) =>
                                          _DocumentCard(
                                        document: _documents[index],
                                        showTitle: false,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                    ),
                    if (_isUploading)
                      BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 300),
                              child: LinearProgressIndicator(
                                value: _uploadProgress,
                                color: Theme.of(context).colorScheme.primary,
                                backgroundColor: Theme.of(context)
                                    .colorScheme
                                    .primary
                                    .withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(50),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Uploading... ${(_uploadProgress * 100).toStringAsFixed(0)}%\n${StorageService.formatStorageSize(_uploadedBytes)} / ${StorageService.formatStorageSize(_totalUploadBytes)}',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                    color:
                                        Theme.of(context).colorScheme.onSurface,
                                    fontWeight: FontWeight.w600,
                                  ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
                // Flight details section - conditional based on flight documents
                // _flightDocuments.isNotEmpty
                //     ? _FlightDetailsSection(
                //         tripId: widget.tripId,
                //         flightDocuments: _flightDocuments,
                //       )
                //     : _AddDetailCard(
                //         key: const ValueKey('add-flight-detail-card'),
                //         title: 'Add Flight Details',
                //         image: 'assets/images/flight.jpg',
                //         content: const SizedBox(),
                //         expandedContent: const SizedBox(),
                //       ),
                _AddDetailCard(
                  key: const ValueKey('add-flight-detail-card'),
                  title: 'Add Flight Details',
                  image: 'assets/images/flight.jpg',
                  content: _flightInfo.isEmpty
                      ? null
                      : _FlightContent(flightInfo: _flightInfo),
                  onTap: _isUploading ? null : _pickAndUploadDocuments,
                ),
                _AddDetailCard(
                  key: const ValueKey('add-hotel-detail-card'),
                  title: 'Add Hotel Info',
                  image: 'assets/images/hotel.jpg',
                  onTap: _isUploading ? null : _pickAndUploadDocuments,
                  content: _hotelInfo.isEmpty
                      ? null
                      : _HotelContent(hotelInfo: _hotelInfo),
                ),
                _AddDetailCard(
                  key: const ValueKey('add-rental-car-detail-card'),
                  title: 'Add Rental Car Details',
                  image: 'assets/images/rental_car.jpg',
                  isComingSoon: true,
                ),
                _AddDetailCard(
                  key: const ValueKey('add-train-detail-card'),
                  title: 'Add Train Booking',
                  image: 'assets/images/train.jpg',
                  isComingSoon: true,
                ),
                _AddDetailCard(
                  key: const ValueKey('add-cruise-detail-card'),
                  title: 'Add Cruise Booking',
                  image: 'assets/images/cruise.jpg',
                  isComingSoon: true,
                ),
              ],
            ),
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
    this.content,
    this.expandedContent,
    this.isComingSoon = false,
    this.onTap,
  });

  final String title;
  final String image;
  final Widget? content;
  final Widget? expandedContent;
  final bool isComingSoon;
  final VoidCallback? onTap;

  @override
  State<_AddDetailCard> createState() => _AddDetailCardState();
}

class _AddDetailCardState extends State<_AddDetailCard> {
  bool _isHovering = false;
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final hasExpandedContent = widget.expandedContent != null;
    return InkWell(
      focusColor: Colors.transparent,
      hoverColor: Colors.transparent,
      highlightColor: Colors.transparent,
      splashColor: Colors.transparent,
      onHover: widget.isComingSoon
          ? null
          : (value) => setState(() => _isHovering = value),
      onTap:
          widget.isComingSoon || widget.content != null ? null : widget.onTap,
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: 300.ms,
        curve: Curves.easeInOut,
        width: double.infinity,
        decoration: BoxDecoration(
          color: _isExpanded
              ? Theme.of(context).colorScheme.surface
              : DarkModeColors.darkOnPrimary
                  .withValues(alpha: widget.isComingSoon ? 0.12 : 0.9),
          image: _isExpanded
              ? null
              : DecorationImage(
                  image: AssetImage(widget.image),
                  fit: BoxFit.cover,
                  opacity: widget.isComingSoon
                      ? 0.2
                      : _isHovering
                          ? 0.6
                          : 0.3,
                ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: widget.isComingSoon
              ? null
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
        ),
        child: AnimatedSize(
          duration: 400.ms,
          curve: Curves.easeInOut,
          alignment: Alignment.topCenter,
          child: AnimatedSwitcher(
            duration: 400.ms,
            transitionBuilder: (child, animation) => FadeTransition(
              opacity: animation,
              child: child,
            ),
            child: widget.content ??
                (_isExpanded && hasExpandedContent
                    ? widget.expandedContent
                    : Padding(
                        padding: const EdgeInsets.all(24),
                        child: Row(
                          children: [
                            Opacity(
                              opacity: widget.isComingSoon ? 0.4 : 1.0,
                              child: Icon(
                                Icons.add_circle_rounded,
                                size: 40,
                                color: Colors.white.withValues(alpha: 0.8),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Opacity(
                              opacity: widget.isComingSoon ? 0.4 : 1.0,
                              child: Text(
                                widget.title,
                                style: Theme.of(context)
                                    .textTheme
                                    .headlineSmall
                                    ?.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                    ),
                              ),
                            ),
                            if (widget.isComingSoon) ...[
                              const Spacer(),
                              Text(
                                'COMING SOON',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurface,
                                      fontWeight: FontWeight.w700,
                                    ),
                              ),
                            ],
                          ],
                        ),
                      )),
          ),
        ),
      ),
    );
  }
}

class _DocumentCard extends StatelessWidget {
  const _DocumentCard({
    this.title,
    this.icon,
    this.document,
    this.showTitle = false,
    this.useDottedBorder = false,
  });

  final String? title;
  final IconData? icon;
  final TripDocument? document;
  final bool showTitle;
  final bool useDottedBorder;

  @override
  Widget build(BuildContext context) {
    final content = Container(
      height: 1.414 * _documentCardWidth,
      width: _documentCardWidth,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: useDottedBorder
            ? null
            : Border.all(
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.3),
                width: 1.5,
              ),
        boxShadow: (showTitle || document != null) && !useDottedBorder
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 5,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: document != null || showTitle
          ? Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon ?? _getDocumentIcon(),
                  size: 32,
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.8),
                ),
                const SizedBox(height: 8),
                Text(
                  title ?? _getDisplayName(),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.8),
                      ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                if (document != null)
                  Text(
                    document!.fileSizeFormatted,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withValues(alpha: 0.6),
                        ),
                  ),
              ],
            )
          : const SizedBox(),
    );
    return useDottedBorder
        ? DottedBorder(
            options: RoundedRectDottedBorderOptions(
              dashPattern: [10, 5],
              strokeWidth: 1.5,
              radius: Radius.circular(20),
              color: Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withValues(alpha: 0.3),
            ),
            child: content,
          )
        : content;
  }

  IconData _getDocumentIcon() {
    if (document == null) return Icons.document_scanner_rounded;

    if (document!.isPdf) {
      return Icons.picture_as_pdf_rounded;
    } else if (document!.isImage) {
      return Icons.image_rounded;
    } else {
      return Icons.description_rounded;
    }
  }

  String _getDisplayName() {
    if (document == null) return 'document.pdf';

    // Show original filename, truncated if too long
    return document!.originalFileName;
  }
}

class _FlightContent extends StatelessWidget {
  const _FlightContent({
    required this.flightInfo,
  });

  final List<FlightInformation> flightInfo;

  String _formatTime(DateTime dateTime) {
    final formatter = DateFormat('h:mm a');
    return formatter.format(dateTime.toUtc());
  }

  String _formatDate(DateTime dateTime) {
    final formatter = DateFormat('EEE, MMM dd');
    return formatter.format(dateTime.toUtc());
  }

  int? _getDaysLater(FlightInformation flight) {
    if (flight.departureTime == null || flight.arrivalTime == null) {
      return null;
    }

    final depDate = flight.departureTime!.toUtc();
    final arrDate = flight.arrivalTime!.toUtc();

    // Extract just the date parts (ignore time)
    final depDateOnly = DateTime(depDate.year, depDate.month, depDate.day);
    final arrDateOnly = DateTime(arrDate.year, arrDate.month, arrDate.day);

    // Calculate the difference in calendar days
    final daysDifference = arrDateOnly.difference(depDateOnly).inDays;

    // Return the number of days later if different calendar day, otherwise null
    return daysDifference > 0 ? daysDifference : null;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 24, right: 24, bottom: 12, top: 10),
      child: LayoutBuilder(
        builder: (_, constraints) {
          return Wrap(
            spacing: 24,
            runSpacing: 24,
            children: flightInfo.map((flight) {
              return SizedBox(
                width: constraints.maxWidth < 350
                    ? constraints.maxWidth
                    : constraints.maxWidth / 2 - 24 / 2,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Flight header (airline and flight number)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          flight.airline ?? '',
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white54,
                                  ),
                        ),
                        SizedBox(
                          height: 16,
                          child: VerticalDivider(
                            color: Colors.white54,
                            thickness: 1,
                            width: 16,
                          ),
                        ),
                        if (flight.flightNumber != null)
                          Text(
                            flight.flightNumber!.replaceFirst('-', ' '),
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white54,
                                    ),
                          ),
                      ],
                    ),
                    // Flight route with airplane icon
                    Row(
                      children: [
                        Text(
                          flight.originCode ?? '',
                          style: Theme.of(context)
                              .textTheme
                              .headlineSmall
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                        ),
                        Expanded(
                          child: Row(
                            children: [
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10),
                                  child: Container(
                                    width: double.infinity,
                                    height: 1,
                                    color: Colors.white30,
                                  ),
                                ),
                              ),
                              Transform.rotate(
                                angle: pi / 2,
                                child: Icon(
                                  Icons.flight_rounded,
                                  size: 24,
                                  color: Colors.white,
                                ),
                              ),
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10),
                                  child: Container(
                                    width: double.infinity,
                                    height: 1,
                                    color: Colors.white30,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          flight.destinationCode ?? '',
                          style: Theme.of(context)
                              .textTheme
                              .headlineSmall
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                        ),
                      ],
                    ),
                    // Origin and destination place names
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Origin
                        Expanded(
                          child: Text(
                            flight.originPlaceName ?? '',
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: Colors.white54,
                                      fontSize: 8,
                                    ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        // Destination
                        Expanded(
                          child: Text(
                            flight.destinationPlaceName ?? '',
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: Colors.white54,
                                      fontSize: 8,
                                    ),
                            textAlign: TextAlign.end,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    // Flight times
                    Row(
                      children: [
                        // Departure time
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (flight.departureTime != null)
                                Text(
                                  _formatTime(
                                    flight.departureTime!,
                                  ),
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyLarge
                                      ?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                ),
                              if (flight.departureTime != null)
                                Text(
                                  _formatDate(
                                    flight.departureTime!,
                                  ),
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white54,
                                      ),
                                ),
                            ],
                          ),
                        ),

                        // Arrival time
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              if (flight.arrivalTime != null)
                                Text.rich(
                                  TextSpan(
                                    children: [
                                      TextSpan(
                                        text: _formatTime(
                                          flight.arrivalTime!,
                                        ),
                                        children: [
                                          // Next day indicator (if applicable)
                                          if (_getDaysLater(flight) != null)
                                            TextSpan(
                                              text: '⁺${_getDaysLater(flight)}',
                                              style: TextStyle(
                                                fontWeight: FontWeight.normal,
                                                fontFeatures: [
                                                  FontFeature.superscripts()
                                                ],
                                              ),
                                            ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  // add +1 to superscript
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyLarge
                                      ?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                ),
                              if (flight.arrivalTime != null)
                                Text(
                                  _formatDate(flight.arrivalTime!),
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white54,
                                      ),
                                  textAlign: TextAlign.end,
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }).toList(),
          );
        },
      ),
    );
  }
}

class _HotelContent extends StatelessWidget {
  const _HotelContent({
    required this.hotelInfo,
  });

  final List<AccommodationInformation> hotelInfo;

  String _formatDate(DateTime dateTime) {
    final formatter = DateFormat('dd MMM');
    return formatter.format(dateTime.toUtc());
  }

  String _formatYear(DateTime dateTime) {
    final formatter = DateFormat('EEE, yyyy');
    return formatter.format(dateTime.toUtc());
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 24, right: 24, bottom: 20, top: 10),
      child: ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: hotelInfo.length,
        itemBuilder: (context, index) {
          final hotel = hotelInfo[index];
          return Column(
            children: [
              if (hotel.reservationNumber != null) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      hotel.reservationNumber ?? '',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: Colors.white38,
                          ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
              ],
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          hotel.hotelName ?? '',
                          style:
                              Theme.of(context).textTheme.bodyLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          hotel.address ?? '',
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Colors.white54,
                                  ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            children: [
                              if (hotel.checkInDate != null) ...[
                                Text(
                                  'Check In',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white54,
                                      ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _formatDate(hotel.checkInDate!),
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyLarge
                                      ?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                ),
                                Text(
                                  _formatYear(hotel.checkInDate!),
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white70,
                                      ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        SizedBox(
                          height: 60,
                          child: VerticalDivider(
                            color: Colors.white54,
                            thickness: 1,
                            width: 16,
                          ),
                        ),
                        Expanded(
                          child: Column(
                            children: [
                              if (hotel.checkOutDate != null) ...[
                                Text(
                                  'Check Out',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white54,
                                      ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _formatDate(hotel.checkOutDate!),
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyLarge
                                      ?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                ),
                                Text(
                                  _formatYear(hotel.checkOutDate!),
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white70,
                                      ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  )
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}
