import 'package:cloud_firestore/cloud_firestore.dart';

/// Flight information extracted from flight documents
class FlightInformation {
  final String? flightNumber;
  final String? airline;
  final String? originCode; // Airport IATA code (e.g., "JFK")
  final String? destinationCode; // Airport IATA code (e.g., "LAX")
  final String? originPlaceName; // Full airport name
  final String? destinationPlaceName; // Full airport name
  final String? originPlaceId; // Places API place ID for airport
  final String? destinationPlaceId; // Places API place ID for airport
  final DateTime? departureTime;
  final DateTime? arrivalTime;
  final String? gate;
  final String? terminal;
  final String? seat;
  final String? confirmationNumber;
  final String? passengerName;
  final String? ticketNumber;
  final String? classOfService; // Economy, Business, First
  final String? status; // Confirmed, Cancelled, Delayed
  final DateTime? extractedAt;

  FlightInformation({
    this.flightNumber,
    this.airline,
    this.originCode,
    this.destinationCode,
    this.originPlaceName,
    this.destinationPlaceName,
    this.originPlaceId,
    this.destinationPlaceId,
    this.departureTime,
    this.arrivalTime,
    this.gate,
    this.terminal,
    this.seat,
    this.confirmationNumber,
    this.passengerName,
    this.ticketNumber,
    this.classOfService,
    this.status,
    this.extractedAt,
  });

  factory FlightInformation.fromFirestore(Map<String, dynamic> data) {
    return FlightInformation(
      flightNumber: data['flight_number'],
      airline: data['airline'],
      originCode: data['origin_code'],
      destinationCode: data['destination_code'],
      originPlaceName: data['origin_place_name'],
      destinationPlaceName: data['destination_place_name'],
      originPlaceId: data['origin_place_id'],
      destinationPlaceId: data['destination_place_id'],
      departureTime: _parseDateTime(data['departure_time']),
      arrivalTime: _parseDateTime(data['arrival_time']),
      gate: data['gate'],
      terminal: data['terminal'],
      seat: data['seat'],
      confirmationNumber: data['confirmation_number'],
      passengerName: data['passenger_name'],
      ticketNumber: data['ticket_number'],
      classOfService: data['class_of_service'],
      status: data['status'],
      extractedAt: _parseDateTime(data['extracted_at']),
    );
  }

  // Helper method to safely parse DateTime from various formats
  static DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;

    try {
      if (value is Timestamp) {
        return value.toDate();
      } else if (value is String) {
        // Handle ISO string format as fallback
        return DateTime.parse(value);
      } else {
        return null;
      }
    } catch (e) {
      // Log error but don't throw - return null for invalid dates
      print('⚠️ Error parsing DateTime: $e');
      return null;
    }
  }

  Map<String, dynamic> toFirestore() {
    return {
      'flight_number': flightNumber,
      'airline': airline,
      'origin_code': originCode,
      'destination_code': destinationCode,
      'origin_place_name': originPlaceName,
      'destination_place_name': destinationPlaceName,
      'origin_place_id': originPlaceId,
      'destination_place_id': destinationPlaceId,
      'departure_time':
          departureTime != null ? Timestamp.fromDate(departureTime!) : null,
      'arrival_time':
          arrivalTime != null ? Timestamp.fromDate(arrivalTime!) : null,
      'gate': gate,
      'terminal': terminal,
      'seat': seat,
      'confirmation_number': confirmationNumber,
      'passenger_name': passengerName,
      'ticket_number': ticketNumber,
      'class_of_service': classOfService,
      'status': status,
      'extracted_at': extractedAt != null
          ? Timestamp.fromDate(extractedAt!)
          : FieldValue.serverTimestamp(),
    };
  }

  FlightInformation copyWith({
    String? flightNumber,
    String? airline,
    String? originCode,
    String? destinationCode,
    String? originPlaceName,
    String? destinationPlaceName,
    String? originPlaceId,
    String? destinationPlaceId,
    DateTime? departureTime,
    DateTime? arrivalTime,
    String? gate,
    String? terminal,
    String? seat,
    String? confirmationNumber,
    String? passengerName,
    String? ticketNumber,
    String? classOfService,
    String? status,
    DateTime? extractedAt,
  }) {
    return FlightInformation(
      flightNumber: flightNumber ?? this.flightNumber,
      airline: airline ?? this.airline,
      originCode: originCode ?? this.originCode,
      destinationCode: destinationCode ?? this.destinationCode,
      originPlaceName: originPlaceName ?? this.originPlaceName,
      destinationPlaceName: destinationPlaceName ?? this.destinationPlaceName,
      originPlaceId: originPlaceId ?? this.originPlaceId,
      destinationPlaceId: destinationPlaceId ?? this.destinationPlaceId,
      departureTime: departureTime ?? this.departureTime,
      arrivalTime: arrivalTime ?? this.arrivalTime,
      gate: gate ?? this.gate,
      terminal: terminal ?? this.terminal,
      seat: seat ?? this.seat,
      confirmationNumber: confirmationNumber ?? this.confirmationNumber,
      passengerName: passengerName ?? this.passengerName,
      ticketNumber: ticketNumber ?? this.ticketNumber,
      classOfService: classOfService ?? this.classOfService,
      status: status ?? this.status,
      extractedAt: extractedAt ?? this.extractedAt,
    );
  }

  @override
  String toString() {
    return 'FlightInformation(flight: $flightNumber, route: $originCode→$destinationCode, departure: $departureTime)';
  }
}

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
