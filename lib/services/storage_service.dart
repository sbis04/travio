import 'dart:typed_data';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:travio/models/document.dart';
import 'package:travio/utils/utils.dart';

class StorageService {
  static final FirebaseStorage _storage = FirebaseStorage.instance;

  // Upload a single file and return TripDocument
  static Future<TripDocument?> uploadDocument({
    required String tripId,
    required String fileName,
    required Uint8List fileBytes,
    required String mimeType,
    required DocumentType type,
    String? description,
    Function(double)? onProgress,
  }) async {
    try {
      logPrint('📤 Uploading document: $fileName (${fileBytes.length} bytes)');

      // Generate unique file name to avoid conflicts
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final uniqueFileName = '${timestamp}_${fileName.replaceAll(' ', '_')}';

      // Create storage path: trips/{tripId}/documents/{uniqueFileName}
      final storageRef =
          _storage.ref().child('trips/$tripId/documents/$uniqueFileName');

      // Create upload task
      final uploadTask = storageRef.putData(
        fileBytes,
        SettableMetadata(
          contentType: mimeType,
          customMetadata: {
            'originalFileName': fileName,
            'tripId': tripId,
            'documentType': type.name,
            'uploadedAt': DateTime.now().toIso8601String(),
          },
        ),
      );

      // Listen to upload progress
      uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
        final progress = snapshot.bytesTransferred / snapshot.totalBytes;
        onProgress?.call(progress);
        logPrint('📤 Upload progress: ${(progress * 100).toStringAsFixed(1)}%');
      });

      // Wait for upload to complete
      final snapshot = await uploadTask;

      if (snapshot.state == TaskState.success) {
        // Get download URL
        final downloadUrl = await storageRef.getDownloadURL();

        logPrint('✅ File uploaded successfully: $uniqueFileName');
        logPrint('   Download URL: $downloadUrl');

        // Create TripDocument object
        final document = TripDocument(
          id: '', // Will be set by Firestore
          fileName: uniqueFileName,
          originalFileName: fileName,
          storageUrl: storageRef.fullPath,
          downloadUrl: downloadUrl,
          type: type,
          fileSizeBytes: fileBytes.length,
          mimeType: mimeType,
          uploadedAt: DateTime.now(),
          description: description,
        );

        return document;
      } else {
        logPrint('❌ Upload failed with state: ${snapshot.state}');
        return null;
      }
    } catch (e) {
      logPrint('❌ Error uploading document: $e');
      return null;
    }
  }

  // Upload multiple files
  static Future<List<TripDocument>> uploadMultipleDocuments({
    required String tripId,
    required List<
            ({
              String fileName,
              Uint8List bytes,
              String mimeType,
              DocumentType type,
              String? description
            })>
        files,
    Function(int bytesUploaded, int totalBytes)? onProgress,
  }) async {
    final uploadedDocuments = <TripDocument>[];

    logPrint('📤 Uploading ${files.length} documents...');

    // Calculate total bytes across all files
    final totalBytes =
        files.fold<int>(0, (sum, file) => sum + file.bytes.length);
    int bytesUploaded = 0;

    logPrint('📊 Total size to upload: ${formatStorageSize(totalBytes)}');

    for (int i = 0; i < files.length; i++) {
      final file = files[i];

      final document = await uploadDocument(
        tripId: tripId,
        fileName: file.fileName,
        fileBytes: file.bytes,
        mimeType: file.mimeType,
        type: file.type,
        description: file.description,
        onProgress: (fileProgress) {
          // Calculate bytes uploaded for this specific file
          final fileBytesUploaded = (file.bytes.length * fileProgress).round();
          final totalBytesUploaded = bytesUploaded + fileBytesUploaded;

          // Report overall progress based on bytes
          onProgress?.call(totalBytesUploaded, totalBytes);
        },
      );

      if (document != null) {
        uploadedDocuments.add(document);
      }

      // Update bytes uploaded after completing this file
      bytesUploaded += file.bytes.length;

      // Report final progress for this file
      onProgress?.call(bytesUploaded, totalBytes);
    }

    logPrint(
        '✅ Uploaded ${uploadedDocuments.length}/${files.length} documents successfully');
    logPrint('📊 Total uploaded: ${formatStorageSize(bytesUploaded)}');
    return uploadedDocuments;
  }

  // Delete a document from storage
  static Future<bool> deleteDocument(String storagePath) async {
    try {
      logPrint('🗑️ Deleting document from storage: $storagePath');

      final storageRef = _storage.ref().child(storagePath);
      await storageRef.delete();

      logPrint('✅ Document deleted from storage successfully');
      return true;
    } catch (e) {
      logPrint('❌ Error deleting document from storage: $e');
      return false;
    }
  }

  // Get download URL for a storage path
  static Future<String?> getDownloadUrl(String storagePath) async {
    try {
      final storageRef = _storage.ref().child(storagePath);
      final downloadUrl = await storageRef.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      logPrint('❌ Error getting download URL: $e');
      return null;
    }
  }

  // Get file metadata
  static Future<FullMetadata?> getFileMetadata(String storagePath) async {
    try {
      final storageRef = _storage.ref().child(storagePath);
      final metadata = await storageRef.getMetadata();
      return metadata;
    } catch (e) {
      logPrint('❌ Error getting file metadata: $e');
      return null;
    }
  }

  // Check if file exists in storage
  static Future<bool> fileExists(String storagePath) async {
    try {
      final storageRef = _storage.ref().child(storagePath);
      await storageRef.getMetadata();
      return true;
    } catch (e) {
      return false;
    }
  }

  // Get storage usage for a trip
  static Future<int> getTripStorageUsage(String tripId) async {
    try {
      final storageRef = _storage.ref().child('trips/$tripId/documents');
      final listResult = await storageRef.listAll();

      int totalSize = 0;
      for (final item in listResult.items) {
        final metadata = await item.getMetadata();
        totalSize += metadata.size ?? 0;
      }

      logPrint('📊 Trip $tripId storage usage: ${totalSize} bytes');
      return totalSize;
    } catch (e) {
      logPrint('❌ Error calculating storage usage: $e');
      return 0;
    }
  }

  // Format storage size
  static String formatStorageSize(int bytes) {
    if (bytes < 1024) {
      return '$bytes B';
    } else if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    } else if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    } else {
      return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
    }
  }

  // Validate file before upload
  static bool validateFile({
    required String fileName,
    required int fileSizeBytes,
    int maxSizeBytes = 10 * 1024 * 1024, // 10MB default
    List<String> allowedExtensions = const [
      'pdf',
      'jpg',
      'jpeg',
      'png',
      'doc',
      'docx'
    ],
  }) {
    // Check file size
    if (fileSizeBytes > maxSizeBytes) {
      logPrint(
          '❌ File too large: ${formatStorageSize(fileSizeBytes)} > ${formatStorageSize(maxSizeBytes)}');
      return false;
    }

    // Check file extension
    final extension = fileName.split('.').last.toLowerCase();
    if (!allowedExtensions.contains(extension)) {
      logPrint('❌ File extension not allowed: $extension');
      return false;
    }

    return true;
  }
}
