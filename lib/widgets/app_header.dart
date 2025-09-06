import 'dart:ui';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:travio/providers/theme_provider.dart';
import 'package:travio/services/auth_service.dart';
import 'package:travio/utils/utils.dart';
import 'package:travio/widgets/auth/auth_dialog.dart';

class AppHeader extends StatelessWidget {
  const AppHeader({super.key, this.hideButtons = false});

  final bool hideButtons;

  @override
  Widget build(BuildContext context) {
    return ResponsiveContainer(
      child: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: Container(
            height: kAppBarHeight,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.8),
            child: Row(
              children: [
                // Logo
                MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: GestureDetector(
                    onTap: () => context.go('/'),
                    child: Row(
                      children: [
                        Image.asset(
                          'assets/images/travio_logo_small.png',
                          width: 28,
                          height: 28,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Travio',
                          style: Theme.of(context)
                              .textTheme
                              .headlineSmall
                              ?.copyWith(
                                color: Theme.of(context).colorScheme.primary,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // Preview badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(50),
                    border: Border.all(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.5),
                    ),
                  ),
                  child: Row(
                    children: [
                      Text(
                        'Preview',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withValues(alpha: 0.5),
                            ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                if (!hideButtons) ...[
                  // Navigation
                  if (Responsive.isDesktop(context)) ...[
                    // _NavButton(
                    //   text: 'Features',
                    //   onPressed: () {
                    //     // TODO: Scroll to features section or navigate to features page
                    //   },
                    // ),
                    // const SizedBox(width: 24),
                    // _NavButton(
                    //   text: 'Pricing',
                    //   onPressed: () {
                    //     // TODO: Navigate to pricing page
                    //   },
                    // ),
                    const SizedBox(width: 24),
                    _NavButton(
                      text: 'About',
                      onPressed: () {
                        print('🔗 About button clicked - navigating to /about');
                        context.go('/about');
                      },
                    ),
                    const SizedBox(width: 24),
                    _NavButton(
                      text: 'Contact',
                      onPressed: () {
                        print(
                            '🔗 Contact button clicked - navigating to /contact');
                        context.go('/contact');
                      },
                    ),
                    const SizedBox(width: 32),
                    // Theme toggle button
                    IconButton(
                      onPressed: () =>
                          context.read<ThemeProvider>().toggleTheme(),
                      icon: Icon(
                        Theme.of(context).brightness == Brightness.light
                            ? Icons.dark_mode_outlined
                            : Icons.light_mode_outlined,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                      tooltip: Theme.of(context).brightness == Brightness.light
                          ? 'Switch to dark mode'
                          : 'Switch to light mode',
                    ),
                    const SizedBox(width: 12),
                    // Auth buttons - conditional based on auth state
                    StreamBuilder<User?>(
                      stream: AuthService.authStateChanges,
                      builder: (context, snapshot) {
                        final user = snapshot.data;
                        final isAuthenticated =
                            user != null && !user.isAnonymous;

                        if (isAuthenticated) {
                          // Show user menu when authenticated
                          return _UserMenu(user: user);
                        } else {
                          // Show auth buttons when not authenticated
                          return Row(
                            children: [
                              OutlinedButton(
                                onPressed: () =>
                                    _showAuthDialog(context, AuthMode.signIn),
                                style: OutlinedButton.styleFrom(
                                  side: BorderSide(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .primary),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 24, vertical: 12),
                                ),
                                child: Text(
                                  'Sign In',
                                  style: TextStyle(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .primary),
                                ),
                              ),
                              const SizedBox(width: 12),
                              ElevatedButton(
                                onPressed: () =>
                                    _showAuthDialog(context, AuthMode.signUp),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor:
                                      Theme.of(context).colorScheme.primary,
                                  foregroundColor:
                                      Theme.of(context).colorScheme.onPrimary,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 24, vertical: 12),
                                ),
                                child: const Text('Get Started'),
                              ),
                            ],
                          );
                        }
                      },
                    ),
                  ] else ...[
                    // Theme toggle button for mobile
                    IconButton(
                      onPressed: () =>
                          context.read<ThemeProvider>().toggleTheme(),
                      icon: Icon(
                        Theme.of(context).brightness == Brightness.light
                            ? Icons.dark_mode_outlined
                            : Icons.light_mode_outlined,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                      tooltip: Theme.of(context).brightness == Brightness.light
                          ? 'Switch to dark mode'
                          : 'Switch to light mode',
                    ),
                    IconButton(
                      onPressed: () {},
                      icon: Icon(
                        Icons.menu,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  ],
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Show authentication dialog
  static Future<void> _showAuthDialog(
      BuildContext context, AuthMode mode) async {
    await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (context) => AuthDialog(initialMode: mode),
    );
  }
}

/// User menu widget for authenticated users
class _UserMenu extends StatelessWidget {
  const _UserMenu({required this.user});

  final User user;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      offset: const Offset(0, 50),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primaryContainer,
          borderRadius: BorderRadius.circular(50),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: Theme.of(context).colorScheme.primary,
              backgroundImage: user.photoURL != null
                  ? NetworkImage(
                      user.photoURL!,
                    )
                  : null,
              child: user.photoURL == null
                  ? Text(
                      _getInitials(user.displayName ?? user.email ?? 'U'),
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onPrimary,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  user.displayName ?? 'User',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                      ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (user.email != null)
                  Text(
                    user.email!,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context)
                              .colorScheme
                              .onPrimaryContainer
                              .withValues(alpha: 0.7),
                          fontSize: 10,
                        ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.arrow_drop_down,
              color: Theme.of(context).colorScheme.onPrimaryContainer,
            ),
          ],
        ),
      ),
      onSelected: (value) => _handleMenuAction(context, value),
      itemBuilder: (context) => [
        PopupMenuItem(
          value: 'profile',
          child: ListTile(
            leading: const Icon(Icons.person_outline),
            title: const Text('Profile'),
            contentPadding: EdgeInsets.zero,
          ),
        ),
        PopupMenuItem(
          value: 'trips',
          child: ListTile(
            leading: const Icon(Icons.luggage_outlined),
            title: const Text('My Trips'),
            contentPadding: EdgeInsets.zero,
          ),
        ),
        PopupMenuItem(
          value: 'settings',
          child: ListTile(
            leading: const Icon(Icons.settings_outlined),
            title: const Text('Settings'),
            contentPadding: EdgeInsets.zero,
          ),
        ),
        const PopupMenuDivider(),
        PopupMenuItem(
          value: 'signout',
          child: ListTile(
            leading: Icon(
              Icons.logout,
              color: Theme.of(context).colorScheme.error,
            ),
            title: Text(
              'Sign Out',
              style: TextStyle(
                color: Theme.of(context).colorScheme.error,
              ),
            ),
            contentPadding: EdgeInsets.zero,
          ),
        ),
      ],
    );
  }

  void _handleMenuAction(BuildContext context, String action) {
    switch (action) {
      case 'profile':
        // TODO: Navigate to profile page
        break;
      case 'trips':
        // TODO: Navigate to trips page
        break;
      case 'settings':
        // TODO: Navigate to settings page
        break;
      case 'signout':
        _handleSignOut(context);
        break;
    }
  }

  Future<void> _handleSignOut(BuildContext context) async {
    try {
      await AuthService.signOut();
      logPrint('✅ User signed out from header menu');
    } catch (e) {
      logPrint('❌ Error signing out: $e');
    }
  }

  String _getInitials(String name) {
    if (name.isEmpty) return 'U';

    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    } else {
      return name[0].toUpperCase();
    }
  }
}

class _NavButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;

  const _NavButton({
    required this.text,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onPressed,
      child: Text(
        text,
        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Theme.of(context).colorScheme.onSurface,
              fontWeight: FontWeight.w500,
            ),
      ),
    );
  }
}
