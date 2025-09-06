import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:travio/providers/theme_provider.dart';
import 'package:travio/utils/utils.dart';

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
                    OutlinedButton(
                      onPressed: () {},
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(
                            color: Theme.of(context).colorScheme.primary),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 12),
                      ),
                      child: Text(
                        'Sign In',
                        style: TextStyle(
                            color: Theme.of(context).colorScheme.primary),
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: () {},
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        foregroundColor:
                            Theme.of(context).colorScheme.onPrimary,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 12),
                      ),
                      child: const Text('Get Started'),
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
