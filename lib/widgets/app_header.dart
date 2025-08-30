import 'package:flutter/material.dart';
import 'package:travio/utils/utils.dart';

class AppHeader extends StatelessWidget {
  final VoidCallback onThemeToggle;

  const AppHeader({
    super.key,
    required this.onThemeToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: kAppBarHeight,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.1),
            width: 0.5,
          ),
        ),
      ),
      child: ResponsiveContainer(
        child: Row(
          children: [
            // Logo
            Row(
              children: [
                Image.asset(
                  'assets/images/travio_logo_small.png',
                  width: 28,
                  height: 28,
                ),
                const SizedBox(width: 8),
                Text(
                  'Travio',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const Spacer(),
            // Navigation
            if (Responsive.isDesktop(context)) ...[
              _NavButton(
                text: 'Features',
                onPressed: () {},
              ),
              const SizedBox(width: 24),
              _NavButton(
                text: 'Pricing',
                onPressed: () {},
              ),
              const SizedBox(width: 24),
              _NavButton(
                text: 'About',
                onPressed: () {},
              ),
              const SizedBox(width: 32),
              // Theme toggle button
              IconButton(
                onPressed: onThemeToggle,
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
                  side:
                      BorderSide(color: Theme.of(context).colorScheme.primary),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
                child: Text(
                  'Sign In',
                  style:
                      TextStyle(color: Theme.of(context).colorScheme.primary),
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Theme.of(context).colorScheme.onPrimary,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
                child: const Text('Get Started'),
              ),
            ] else ...[
              // Theme toggle button for mobile
              IconButton(
                onPressed: onThemeToggle,
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
