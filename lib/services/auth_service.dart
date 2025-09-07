import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:travio/models/user.dart' as user_model;
import 'package:travio/utils/utils.dart';

class AuthService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Google Sign-In instance
  static final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
  );

  // Get current user
  static User? get currentUser => _auth.currentUser;

  // Get current user UID
  static String? get currentUserUid => _auth.currentUser?.uid;

  // Check if user is signed in
  static bool get isSignedIn => _auth.currentUser != null;

  // Sign in anonymously (enhanced to check existing auth)
  static Future<User?> signInAnonymously() async {
    try {
      // Check if already signed in
      if (isSignedIn) {
        logPrint('✅ User already signed in: $currentUserUid');
        return currentUser;
      }

      logPrint('🔐 Signing in anonymously...');
      final UserCredential result = await _auth.signInAnonymously();
      final User? user = result.user;

      if (user != null) {
        logPrint('✅ Anonymous sign-in successful: ${user.uid}');
        await _saveUserToFirestore(user, user_model.AuthProvider.anonymous);
        return user;
      } else {
        logPrint('❌ Anonymous sign-in failed: No user returned');
        return null;
      }
    } catch (e) {
      logPrint('❌ Anonymous sign-in error: $e');
      return null;
    }
  }

  // Google Sign-In implementation using older API
  static Future<User?> signInWithGoogle() async {
    try {
      logPrint('🔐 Starting Google Sign-In...');

      // Trigger the Google Sign-In flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        logPrint('❌ Google Sign-In cancelled by user');
        return null;
      }

      logPrint('✅ Google user obtained: ${googleUser.email}');

      // Get authentication details
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      // Create a new credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      final userCredential = await _auth.signInWithCredential(credential);
      final user = userCredential.user;
      if (user != null) {
        logPrint('✅ Google Sign-In successful: ${user.email}');
        await _saveUserToFirestore(user, user_model.AuthProvider.google);
        return user;
      }

      return null;
    } catch (e) {
      logPrint('❌ Error during Google Sign-In: $e');

      // Handle specific error cases
      if (e.toString().contains('sign_in_canceled')) {
        logPrint('ℹ️ Google Sign-In was cancelled by user');
        return null;
      } else if (e.toString().contains('network_error')) {
        throw Exception(
            'Network error. Please check your internet connection.');
      } else {
        // For configuration issues, return null gracefully
        logPrint('⚠️ Google Sign-In configuration may be incomplete');
        return null;
      }
    }
  }

  // Email/Password Sign-In
  static Future<User?> signInWithEmailPassword({
    required String email,
    required String password,
  }) async {
    try {
      logPrint('🔐 Starting email/password sign-in...');

      // Check if user is currently anonymous
      final currentUser = _auth.currentUser;
      final isAnonymous = currentUser?.isAnonymous ?? false;

      UserCredential userCredential;

      if (isAnonymous && currentUser != null) {
        // Convert anonymous user to email/password user
        logPrint('🔄 Converting anonymous user to email/password user...');
        final credential =
            EmailAuthProvider.credential(email: email, password: password);
        userCredential = await currentUser.linkWithCredential(credential);
        logPrint('✅ Anonymous user converted to email/password user');
      } else {
        // Sign in with email/password
        userCredential = await _auth.signInWithEmailAndPassword(
          email: email,
          password: password,
        );
      }

      final user = userCredential.user;
      if (user != null) {
        logPrint('✅ Email/password sign-in successful');
        await _saveUserToFirestore(user, user_model.AuthProvider.emailPassword);
        return user;
      }

      return null;
    } catch (e) {
      logPrint('❌ Error during email/password sign-in: $e');
      rethrow;
    }
  }

  // Email/Password Sign-Up
  static Future<User?> signUpWithEmailPassword({
    required String email,
    required String password,
    String? displayName,
  }) async {
    try {
      logPrint('🔐 Starting email/password sign-up...');

      // Check if user is currently anonymous
      final currentUser = _auth.currentUser;
      final isAnonymous = currentUser?.isAnonymous ?? false;

      UserCredential userCredential;

      if (isAnonymous && currentUser != null) {
        // Convert anonymous user to email/password user
        logPrint('🔄 Converting anonymous user to email/password user...');
        final credential =
            EmailAuthProvider.credential(email: email, password: password);
        userCredential = await currentUser.linkWithCredential(credential);

        // Update display name if provided
        if (displayName != null && displayName.isNotEmpty) {
          await userCredential.user?.updateDisplayName(displayName);
        }

        logPrint('✅ Anonymous user converted to email/password user');
      } else {
        // Create new account
        userCredential = await _auth.createUserWithEmailAndPassword(
          email: email,
          password: password,
        );

        // Update display name if provided
        if (displayName != null && displayName.isNotEmpty) {
          await userCredential.user?.updateDisplayName(displayName);
        }
      }

      final user = userCredential.user;
      if (user != null) {
        logPrint('✅ Email/password sign-up successful');
        await _saveUserToFirestore(user, user_model.AuthProvider.emailPassword);
        return user;
      }

      return null;
    } catch (e) {
      logPrint('❌ Error during email/password sign-up: $e');
      rethrow;
    }
  }

  // Sign out
  static Future<void> signOut() async {
    try {
      // Sign out from Google if signed in with Google
      try {
        if (await _googleSignIn.isSignedIn()) {
          await _googleSignIn.signOut();
          logPrint('✅ Google sign out successful');
        }
      } catch (e) {
        logPrint('⚠️ Google sign out error: $e');
      }

      await _auth.signOut();
      logPrint('✅ User signed out successfully');
    } catch (e) {
      logPrint('❌ Sign out error: $e');
    }
  }

  // Save user information to Firestore
  static Future<void> _saveUserToFirestore(
      User user, user_model.AuthProvider provider) async {
    try {
      logPrint('💾 Saving user to Firestore: ${user.uid}');

      final userDoc = _firestore.collection('users').doc(user.uid);
      final userSnapshot = await userDoc.get();

      final now = DateTime.now();

      if (userSnapshot.exists) {
        // Update existing user
        await userDoc.update({
          if (user.email != null) 'email': user.email,
          if (user.displayName != null) 'display_name': user.displayName,
          if (user.photoURL != null) 'photo_url': user.photoURL,
          'auth_provider': provider.name,
          'last_sign_in_at': Timestamp.fromDate(now),
          'is_anonymous': user.isAnonymous,
          'updated_at': FieldValue.serverTimestamp(),
        });
        logPrint('✅ Updated existing user in Firestore');
      } else {
        // Create new user
        final appUser = user_model.AppUser(
          uid: user.uid,
          email: user.email,
          displayName: user.displayName,
          photoUrl: user.photoURL,
          authProvider: provider,
          createdAt: now,
          lastSignInAt: now,
          isAnonymous: user.isAnonymous,
        );

        await userDoc.set(appUser.toFirestore());
        logPrint('✅ Created new user in Firestore');
      }
    } catch (e) {
      logPrint('❌ Error saving user to Firestore: $e');
      // Don't throw - user authentication succeeded even if Firestore save failed
    }
  }

  // Get user from Firestore
  static Future<user_model.AppUser?> getUserFromFirestore(String uid) async {
    try {
      final userDoc = await _firestore.collection('users').doc(uid).get();
      if (userDoc.exists) {
        return user_model.AppUser.fromFirestore(userDoc);
      }
      return null;
    } catch (e) {
      logPrint('❌ Error getting user from Firestore: $e');
      return null;
    }
  }

  // Get current app user (combines Firebase Auth + Firestore data)
  static Future<user_model.AppUser?> getCurrentAppUser() async {
    final user = currentUser;
    if (user == null) return null;

    try {
      final appUser = await getUserFromFirestore(user.uid);
      return appUser;
    } catch (e) {
      logPrint('❌ Error getting current app user: $e');
      return null;
    }
  }

  // Check authentication state
  static bool get isAnonymous => _auth.currentUser?.isAnonymous ?? false;
  static bool get isAuthenticated => isSignedIn && !isAnonymous;

  // Auth state stream
  static Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Get user info for debugging
  static void logUserInfo() {
    final user = currentUser;
    if (user != null) {
      logPrint('👤 Current User Info:');
      logPrint('   UID: ${user.uid}');
      logPrint('   Anonymous: ${user.isAnonymous}');
      logPrint('   Email: ${user.email ?? 'N/A'}');
      logPrint('   Display Name: ${user.displayName ?? 'N/A'}');
      logPrint('   Created: ${user.metadata.creationTime}');
      logPrint('   Last Sign In: ${user.metadata.lastSignInTime}');
    } else {
      logPrint('👤 No user currently signed in');
    }
  }

  // Reset password
  static Future<bool> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      logPrint('✅ Password reset email sent to: $email');
      return true;
    } catch (e) {
      logPrint('❌ Error sending password reset email: $e');
      return false;
    }
  }

  // Delete user account
  static Future<bool> deleteAccount() async {
    try {
      final user = currentUser;
      if (user == null) return false;

      logPrint('🗑️ Deleting user account: ${user.uid}');

      // Delete user from Firestore
      await _firestore.collection('users').doc(user.uid).delete();

      // Delete Firebase Auth user
      await user.delete();

      logPrint('✅ User account deleted successfully');
      return true;
    } catch (e) {
      logPrint('❌ Error deleting user account: $e');
      return false;
    }
  }
}
