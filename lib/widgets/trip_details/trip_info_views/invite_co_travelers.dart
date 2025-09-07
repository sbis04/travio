import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:travio/services/auth_service.dart';
import 'package:travio/services/trip_service.dart';
import 'package:travio/utils/utils.dart';
import 'package:travio/widgets/app_textfield.dart';
import 'package:travio/widgets/auth/auth_dialog.dart';
import 'package:travio/widgets/sonnar.dart';

class InviteCoTravelersView extends StatefulWidget {
  const InviteCoTravelersView({super.key, required this.tripId});

  final String tripId;

  @override
  State<InviteCoTravelersView> createState() => _InviteCoTravelersViewState();
}

class _InviteCoTravelersViewState extends State<InviteCoTravelersView> {
  late final TextEditingController _linkController;
  final _linkFocusNode = FocusNode();

  Future<void> _linkUserToTrip(String tripId) async {
    try {
      logPrint('🔗 Starting trip linking process for trip: $tripId');

      // Check if user is authenticated (should be called after successful auth)
      final currentUser = AuthService.currentUser;
      if (currentUser == null) {
        logPrint('❌ No user signed in to link trip to');
        return;
      }

      if (currentUser.isAnonymous) {
        logPrint('❌ User is still anonymous, cannot link trip');
        return;
      }

      logPrint('👤 Linking trip to authenticated user: ${currentUser.uid}');

      // Link the trip to the current authenticated user
      final success = await TripService.linkTripToCurrentUser(tripId);

      if (success) {
        logPrint('✅ Trip successfully linked to authenticated user');
        logPrint('   Trip ID: $tripId');
        logPrint('   User: ${currentUser.email ?? currentUser.uid}');
        logPrint('   Trip is now private and owned by authenticated user');
      } else {
        logPrint('❌ Failed to link trip to authenticated user');
      }
    } catch (e) {
      logPrint('❌ Error in trip linking process: $e');
    }
  }

  @override
  void initState() {
    super.initState();
    // get the web url of the current trip
    final webUrl = Uri.base.toString();
    _linkController = TextEditingController(text: webUrl);
  }

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 650),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // const SizedBox(height: 16),
            // Trip link copy to clipboard
            Text(
              '${(AuthService.currentUser?.isAnonymous ?? true) ? 'Publicly accessible' : 'Private'} link to the trip:',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.8),
                    height: 1.5,
                  ),
            ),
            const SizedBox(height: 8),
            AppTextField(
              controller: _linkController,
              focusNode: _linkFocusNode,
              // enabled: false,
              suffixIcon: Padding(
                padding: const EdgeInsets.only(right: 8),
                child: IconButton(
                  focusColor: Colors.transparent,
                  hoverColor: Colors.transparent,
                  splashColor: Colors.transparent,
                  highlightColor: Colors.transparent,
                  onPressed: () {
                    Clipboard.setData(
                        ClipboardData(text: _linkController.text));
                    AppSonnar.of(context).show(
                      AppToast(
                        title: Text('Link copied to clipboard'),
                        variant: AppToastVariant.primary,
                      ),
                    );
                  },
                  icon: Icon(
                    Icons.copy_rounded,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            StreamBuilder<User?>(
              stream: AuthService.authStateChanges,
              builder: (context, snapshot) {
                final user = snapshot.data;
                final isAuthenticated = user != null && !user.isAnonymous;

                if (isAuthenticated) {
                  return SizedBox();
                } else {
                  return AuthContent(
                    isDialog: false,
                    onSignedIn: () => _linkUserToTrip(widget.tripId),
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
