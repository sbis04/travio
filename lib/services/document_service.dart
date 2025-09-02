import 'dart:typed_data';
import 'package:travio/models/document.dart';
import 'package:travio/services/storage_service.dart';
import 'package:travio/services/firestore_service.dart';
import 'package:travio/utils/utils.dart';

class DocumentService {
  // Upload documents and save metadata to Firestore
  static Future<List<TripDocument>> uploadDocuments({
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
    try {
      logPrint('🚀 Starting document upload process for trip: $tripId');
      logPrint('   Files to upload: ${files.length}');

      // Step 1: Upload files to Firebase Storage
      final uploadedDocuments = await StorageService.uploadMultipleDocuments(
        tripId: tripId,
        files: files,
        onProgress: onProgress,
      );

      // Step 2: Save metadata to Firestore
      final savedDocuments = <TripDocument>[];
      for (final document in uploadedDocuments) {
        final documentId = await FirestoreService.addDocument(
          tripId: tripId,
          document: document,
        );

        if (documentId != null) {
          // Create updated document with Firestore ID
          final updatedDocument = document.copyWith(id: documentId);
          savedDocuments.add(updatedDocument);
        }
      }

      logPrint('✅ Document upload process completed');
      logPrint('   Uploaded: ${uploadedDocuments.length}/${files.length}');
      logPrint(
          '   Saved to Firestore: ${savedDocuments.length}/${uploadedDocuments.length}');

      return savedDocuments;
    } catch (e) {
      logPrint('❌ Error in document upload process: $e');
      return [];
    }
  }

  // Delete document (removes from both Storage and Firestore)
  static Future<bool> deleteDocument({
    required String tripId,
    required TripDocument document,
  }) async {
    try {
      logPrint('🗑️ Deleting document: ${document.fileName}');

      // Step 1: Delete from Firebase Storage
      final storageDeleted =
          await StorageService.deleteDocument(document.storageUrl);

      // Step 2: Delete from Firestore (even if storage deletion failed)
      final firestoreDeleted = await FirestoreService.removeDocument(
        tripId: tripId,
        documentId: document.id,
      );

      final success = storageDeleted && firestoreDeleted;
      if (success) {
        logPrint('✅ Document deleted successfully: ${document.fileName}');
      } else {
        logPrint(
            '⚠️ Partial deletion: Storage: $storageDeleted, Firestore: $firestoreDeleted');
      }

      return success;
    } catch (e) {
      logPrint('❌ Error deleting document: $e');
      return false;
    }
  }

  // Get all documents for a trip
  static Future<List<TripDocument>> getDocuments(String tripId) async {
    return await FirestoreService.getDocuments(tripId);
  }

  // Get documents by type
  static Future<List<TripDocument>> getDocumentsByType({
    required String tripId,
    required DocumentType type,
  }) async {
    return await FirestoreService.getDocumentsByType(
      tripId: tripId,
      type: type,
    );
  }

  // Listen to documents (real-time)
  static Stream<List<TripDocument>> watchDocuments(String tripId) {
    return FirestoreService.watchDocuments(tripId);
  }

  // Update document metadata
  static Future<bool> updateDocumentMetadata({
    required String tripId,
    required String documentId,
    String? description,
    DocumentType? type,
  }) async {
    final updates = <String, dynamic>{};

    if (description != null) {
      updates['description'] = description;
    }

    if (type != null) {
      updates['type'] = type.name;
    }

    if (updates.isEmpty) {
      logPrint('⚠️ No updates provided for document metadata');
      return true;
    }

    return await FirestoreService.updateDocument(
      tripId: tripId,
      documentId: documentId,
      updates: updates,
    );
  }

  // Get document count and storage usage
  static Future<({int count, int storageBytes})> getDocumentStats(
      String tripId) async {
    try {
      final countFuture = FirestoreService.getDocumentCount(tripId);
      final storageFuture = StorageService.getTripStorageUsage(tripId);

      final results = await Future.wait([countFuture, storageFuture]);

      return (
        count: results[0],
        storageBytes: results[1],
      );
    } catch (e) {
      logPrint('❌ Error getting document stats: $e');
      return (count: 0, storageBytes: 0);
    }
  }

  // Validate files before upload
  static List<String> validateFiles(
    List<({String fileName, Uint8List bytes, String mimeType})> files,
  ) {
    final errors = <String>[];

    for (final file in files) {
      if (!StorageService.validateFile(
        fileName: file.fileName,
        fileSizeBytes: file.bytes.length,
      )) {
        errors.add('${file.fileName}: Invalid file (check size and format)');
      }
    }

    return errors;
  }

  // Get supported file extensions
  static List<String> get supportedExtensions =>
      ['pdf', 'jpg', 'jpeg', 'png', 'doc', 'docx'];

  // Get max file size in bytes
  static int get maxFileSizeBytes => 10 * 1024 * 1024; // 10MB

  // Get max file size formatted
  static String get maxFileSizeFormatted =>
      StorageService.formatStorageSize(maxFileSizeBytes);

  // Note: Document classification now happens automatically via Firestore trigger

  // Upload documents (classification happens automatically via Firestore trigger)
  static Future<List<TripDocument>> uploadDocumentsWithAutoClassification({
    required String tripId,
    required List<({String fileName, Uint8List bytes, String mimeType})> files,
    Function(int bytesUploaded, int totalBytes)? onProgress,
  }) async {
    try {
      logPrint('🚀 Starting document upload for trip: $tripId');
      logPrint(
          '   Classification will happen automatically via Firestore trigger');

      // Convert files to upload format (initially as 'other' type)
      final filesToUpload = files
          .map((file) => (
                fileName: file.fileName,
                bytes: file.bytes,
                mimeType: file.mimeType,
                type: DocumentType.other, // Will be updated by trigger
                description: null,
              ))
          .toList();

      // Upload documents - classification will happen automatically
      final uploadedDocs = await uploadDocuments(
        tripId: tripId,
        files: filesToUpload,
        onProgress: onProgress,
      );

      logPrint('✅ Document upload completed - AI classification in progress');
      return uploadedDocs;
    } catch (e) {
      logPrint('❌ Error in document upload: $e');
      return [];
    }
  }
}
