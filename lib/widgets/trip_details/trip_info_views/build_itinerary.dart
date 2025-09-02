import 'dart:ui';
import 'dart:typed_data';

import 'package:dotted_border/dotted_border.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
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
  bool _isUploading = false;
  double _uploadProgress = 0.0;
  int _totalUploadBytes = 0;
  int _uploadedBytes = 0;

  @override
  void initState() {
    super.initState();
    _loadDocuments();
  }

  Future<void> _loadDocuments() async {
    try {
      final documents = await DocumentService.getDocuments(widget.tripId);

      if (mounted) {
        setState(() {
          _documents = documents;
        });
      }
    } catch (e) {
      logPrint('❌ Error loading documents: $e');
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
              'Successfully uploaded ${uploadedDocs.length} document${uploadedDocs.length == 1 ? '' : 's'} (${StorageService.formatStorageSize(_totalUploadBytes)})',
            ),
            variant: AppToastVariant.primary,
          ),
        );

        // Refresh the document list
        _loadDocuments();
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
      constraints: const BoxConstraints(maxWidth: 600),
      child: Padding(
        padding: const EdgeInsets.only(bottom: 24),
        child: SingleChildScrollView(
          child: Column(
            spacing: 16,
            children: [
              _documents.isEmpty
                  ? InkWell(
                      onTap: _isUploading ? null : _pickAndUploadDocuments,
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
                                          SizedBox(
                                            height: 1.414 * _documentCardWidth,
                                            child: Opacity(
                                              opacity: 0.4,
                                              child: ListView.separated(
                                                scrollDirection:
                                                    Axis.horizontal,
                                                physics:
                                                    const NeverScrollableScrollPhysics(),
                                                itemCount: 6,
                                                separatorBuilder: (context,
                                                        index) =>
                                                    const SizedBox(width: 16),
                                                itemBuilder: (context, index) =>
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
                            _isUploading
                                ? Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      SizedBox(
                                        width: 40,
                                        height: 40,
                                        child: CircularProgressIndicator(
                                          value: _uploadProgress,
                                          strokeWidth: 3,
                                          color: Theme.of(context)
                                              .colorScheme
                                              .primary,
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      Text(
                                        'Uploading... ${(_uploadProgress * 100).toStringAsFixed(0)}%\n${StorageService.formatStorageSize(_uploadedBytes)} / ${StorageService.formatStorageSize(_totalUploadBytes)}',
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleMedium
                                            ?.copyWith(
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .onSurface,
                                              fontWeight: FontWeight.w600,
                                            ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ],
                                  )
                                : Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
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
                          onTap: _isUploading ? null : _pickAndUploadDocuments,
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
                              itemBuilder: (context, index) => _DocumentCard(
                                document: _documents[index],
                                showTitle: false,
                              ),
                            ),
                          ),
                        ),
                      ],
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
