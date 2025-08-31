import 'package:firebase_auth/firebase_auth.dart';
import 'package:travio/utils/utils.dart';

class AuthService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  // Get current user
  static User? get currentUser => _auth.currentUser;

  // Get current user UID
  static String? get currentUserUid => _auth.currentUser?.uid;

  // Check if user is signed in
  static bool get isSignedIn => _auth.currentUser != null;

  // Sign in anonymously
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

  // Sign out
  static Future<void> signOut() async {
    try {
      await _auth.signOut();
      logPrint('✅ User signed out successfully');
    } catch (e) {
      logPrint('❌ Sign out error: $e');
    }
  }

  // Listen to auth state changes
  static Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Get user info for debugging
  static void logUserInfo() {
    final user = currentUser;
    if (user != null) {
      logPrint('👤 Current User Info:');
      logPrint('   UID: ${user.uid}');
      logPrint('   Anonymous: ${user.isAnonymous}');
      logPrint('   Created: ${user.metadata.creationTime}');
      logPrint('   Last Sign In: ${user.metadata.lastSignInTime}');
    } else {
      logPrint('👤 No user currently signed in');
    }
  }
}
