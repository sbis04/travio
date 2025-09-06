import 'package:cloud_firestore/cloud_firestore.dart';

enum AuthProvider {
  anonymous,
  google,
  emailPassword,
}

class AppUser {
  final String uid;
  final String? email;
  final String? displayName;
  final String? photoUrl;
  final AuthProvider authProvider;
  final DateTime createdAt;
  final DateTime lastSignInAt;
  final bool isAnonymous;

  AppUser({
    required this.uid,
    this.email,
    this.displayName,
    this.photoUrl,
    required this.authProvider,
    required this.createdAt,
    required this.lastSignInAt,
    required this.isAnonymous,
  });

  factory AppUser.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AppUser(
      uid: doc.id,
      email: data['email'],
      displayName: data['display_name'],
      photoUrl: data['photo_url'],
      authProvider: AuthProvider.values.firstWhere(
        (e) => e.name == data['auth_provider'],
        orElse: () => AuthProvider.anonymous,
      ),
      createdAt: _parseDateTime(data['created_at']) ?? DateTime.now(),
      lastSignInAt: _parseDateTime(data['last_sign_in_at']) ?? DateTime.now(),
      isAnonymous: data['is_anonymous'] ?? true,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'email': email,
      'display_name': displayName,
      'photo_url': photoUrl,
      'auth_provider': authProvider.name,
      'created_at': Timestamp.fromDate(createdAt),
      'last_sign_in_at': Timestamp.fromDate(lastSignInAt),
      'is_anonymous': isAnonymous,
      'updated_at': FieldValue.serverTimestamp(),
    };
  }

  AppUser copyWith({
    String? uid,
    String? email,
    String? displayName,
    String? photoUrl,
    AuthProvider? authProvider,
    DateTime? createdAt,
    DateTime? lastSignInAt,
    bool? isAnonymous,
  }) {
    return AppUser(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      photoUrl: photoUrl ?? this.photoUrl,
      authProvider: authProvider ?? this.authProvider,
      createdAt: createdAt ?? this.createdAt,
      lastSignInAt: lastSignInAt ?? this.lastSignInAt,
      isAnonymous: isAnonymous ?? this.isAnonymous,
    );
  }

  @override
  String toString() {
    return 'AppUser(uid: $uid, email: $email, provider: $authProvider, isAnonymous: $isAnonymous)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AppUser && other.uid == uid;
  }

  @override
  int get hashCode => uid.hashCode;
}

// Helper function to parse DateTime (reused from document.dart)
DateTime? _parseDateTime(dynamic value) {
  if (value == null) return null;

  try {
    if (value is Timestamp) {
      return value.toDate();
    } else if (value is String) {
      return DateTime.parse(value);
    } else {
      return null;
    }
  } catch (e) {
    print('⚠️ Error parsing DateTime: $e');
    return null;
  }
}
