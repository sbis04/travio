import 'package:flutter/material.dart';
import 'package:travio/utils/responsive.dart';

class AppFooter extends StatelessWidget {
  const AppFooter({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: 16,
        vertical: Responsive.isDesktop(context) ? 48 : 32,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.1),
            width: 0.5,
          ),
        ),
      ),
      child: ResponsiveContainer(
        child: Responsive(
          mobile: const _FooterMobile(),
          tablet: const _FooterTablet(),
          desktop: const _FooterDesktop(),
        ),
      ),
    );
  }
}

class _FooterDesktop extends StatelessWidget {
  const _FooterDesktop();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.flight_takeoff,
                        color: Theme.of(context).colorScheme.primary,
                        size: 24,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Travio',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              color: Theme.of(context).colorScheme.primary,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Plan your perfect trip with confidence. Discover, organize, and share your travel experiences.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withValues(alpha: 0.7),
                          height: 1.5,
                        ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 48),
            Expanded(
              child: _FooterColumn(
                title: 'Product',
                links: ['Features', 'Pricing', 'Templates', 'Integrations'],
              ),
            ),
            const SizedBox(width: 32),
            Expanded(
              child: _FooterColumn(
                title: 'Company',
                links: ['About', 'Blog', 'Careers', 'Contact'],
              ),
            ),
            const SizedBox(width: 32),
            Expanded(
              child: _FooterColumn(
                title: 'Support',
                links: ['Help Center', 'Privacy', 'Terms', 'Status'],
              ),
            ),
          ],
        ),
        const SizedBox(height: 32),
        Divider(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.1),
        ),
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '© 2025 Travio. All rights reserved.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.6),
                  ),
            ),
            Row(
              children: [
                IconButton(
                  onPressed: () {},
                  icon: Icon(
                    Icons.facebook,
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.6),
                    size: 20,
                  ),
                ),
                IconButton(
                  onPressed: () {},
                  icon: Icon(
                    Icons.close,
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.6),
                    size: 20,
                  ),
                ),
                IconButton(
                  onPressed: () {},
                  icon: Icon(
                    Icons.link,
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.6),
                    size: 20,
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }
}

class _FooterTablet extends StatelessWidget {
  const _FooterTablet();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Icon(
              Icons.flight_takeoff,
              color: Theme.of(context).colorScheme.primary,
              size: 24,
            ),
            const SizedBox(width: 8),
            Text(
              'Travio',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _FooterColumn(
                title: 'Product',
                links: ['Features', 'Pricing', 'Templates'],
              ),
            ),
            const SizedBox(width: 32),
            Expanded(
              child: _FooterColumn(
                title: 'Company',
                links: ['About', 'Blog', 'Contact'],
              ),
            ),
            const SizedBox(width: 32),
            Expanded(
              child: _FooterColumn(
                title: 'Support',
                links: ['Help', 'Privacy', 'Terms'],
              ),
            ),
          ],
        ),
        const SizedBox(height: 32),
        Divider(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.1),
        ),
        const SizedBox(height: 16),
        Text(
          '© 2025 Travio. All rights reserved.',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.6),
              ),
        ),
      ],
    );
  }
}

class _FooterMobile extends StatelessWidget {
  const _FooterMobile();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.flight_takeoff,
              color: Theme.of(context).colorScheme.primary,
              size: 24,
            ),
            const SizedBox(width: 8),
            Text(
              'Travio',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        _FooterColumn(
          title: 'Quick Links',
          links: ['Features', 'Pricing', 'About', 'Contact', 'Help', 'Privacy'],
        ),
        const SizedBox(height: 24),
        Divider(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.1),
        ),
        const SizedBox(height: 16),
        Text(
          '© 2025 Travio. All rights reserved.',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.6),
              ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

class _FooterColumn extends StatelessWidget {
  final String title;
  final List<String> links;

  const _FooterColumn({
    required this.title,
    required this.links,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface,
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 16),
        ...links.map((link) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: InkWell(
                onTap: () {},
                child: Text(
                  link,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.7),
                      ),
                ),
              ),
            )),
      ],
    );
  }
}
