import 'package:cloud_firestore/cloud_firestore.dart';

enum DocumentType {
  passport,
  visa,
  flight,
  train,
  hotel,
  rental,
  cruise,
  insurance,
  other,
}

class TripDocument {
  final String id;
  final String fileName;
  final String originalFileName;
  final String storageUrl;
  final String downloadUrl;
  final DocumentType type;
  final int fileSizeBytes;
  final String mimeType;
  final DateTime uploadedAt;
  final String? description;

  TripDocument({
    required this.id,
    required this.fileName,
    required this.originalFileName,
    required this.storageUrl,
    required this.downloadUrl,
    required this.type,
    required this.fileSizeBytes,
    required this.mimeType,
    required this.uploadedAt,
    this.description,
  });

  // Create from Firestore document
  factory TripDocument.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return TripDocument(
      id: doc.id,
      fileName: data['file_name'] ?? '',
      originalFileName: data['original_file_name'] ?? '',
      storageUrl: data['storage_url'] ?? '',
      downloadUrl: data['download_url'] ?? '',
      type: DocumentType.values.firstWhere(
        (e) => e.name == data['type'],
        orElse: () => DocumentType.other,
      ),
      fileSizeBytes: data['file_size_bytes'] ?? 0,
      mimeType: data['mime_type'] ?? '',
      uploadedAt: (data['uploaded_at'] as Timestamp).toDate(),
      description: data['description'],
    );
  }

  // Convert to Firestore map
  Map<String, dynamic> toFirestore() {
    return {
      'file_name': fileName,
      'original_file_name': originalFileName,
      'storage_url': storageUrl,
      'download_url': downloadUrl,
      'type': type.name,
      'file_size_bytes': fileSizeBytes,
      'mime_type': mimeType,
      'uploaded_at': Timestamp.fromDate(uploadedAt),
      'description': description,
    };
  }

  // Copy with modifications
  TripDocument copyWith({
    String? id,
    String? fileName,
    String? originalFileName,
    String? storageUrl,
    String? downloadUrl,
    DocumentType? type,
    int? fileSizeBytes,
    String? mimeType,
    DateTime? uploadedAt,
    String? description,
  }) {
    return TripDocument(
      id: id ?? this.id,
      fileName: fileName ?? this.fileName,
      originalFileName: originalFileName ?? this.originalFileName,
      storageUrl: storageUrl ?? this.storageUrl,
      downloadUrl: downloadUrl ?? this.downloadUrl,
      type: type ?? this.type,
      fileSizeBytes: fileSizeBytes ?? this.fileSizeBytes,
      mimeType: mimeType ?? this.mimeType,
      uploadedAt: uploadedAt ?? this.uploadedAt,
      description: description ?? this.description,
    );
  }

  // Get human-readable file size
  String get fileSizeFormatted {
    if (fileSizeBytes < 1024) {
      return '$fileSizeBytes B';
    } else if (fileSizeBytes < 1024 * 1024) {
      return '${(fileSizeBytes / 1024).toStringAsFixed(1)} KB';
    } else {
      return '${(fileSizeBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
  }

  // Get document type display name
  String get typeDisplayName {
    switch (type) {
      case DocumentType.passport:
        return 'Passport';
      case DocumentType.visa:
        return 'Visa';
      case DocumentType.flight:
        return 'Flight';
      case DocumentType.train:
        return 'Train';
      case DocumentType.rental:
        return 'Car Rental';
      case DocumentType.cruise:
        return 'Cruise';
      case DocumentType.hotel:
        return 'Hotel';
      case DocumentType.insurance:
        return 'Insurance';
      case DocumentType.other:
        return 'Other';
    }
  }

  // Get file extension from fileName
  String get fileExtension {
    final parts = fileName.split('.');
    return parts.length > 1 ? parts.last.toLowerCase() : '';
  }

  // Check if file is an image
  bool get isImage {
    final imageExtensions = ['jpg', 'jpeg', 'png', 'gif', 'bmp', 'webp'];
    return imageExtensions.contains(fileExtension);
  }

  // Check if file is a PDF
  bool get isPdf {
    return fileExtension == 'pdf';
  }

  @override
  String toString() {
    return 'TripDocument(id: $id, fileName: $fileName, type: $type, size: $fileSizeFormatted)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TripDocument && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
