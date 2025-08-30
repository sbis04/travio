import 'package:flutter/material.dart';
import 'package:travio/utils/responsive.dart';

class FeaturesSection extends StatelessWidget {
  const FeaturesSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: 16,
        vertical: Responsive.isDesktop(context) ? 80 : 48,
      ),
      child: ResponsiveContainer(
        child: Column(
          children: [
            Text(
              'Everything you need to plan the perfect trip',
              style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontWeight: FontWeight.bold,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              'From inspiration to execution, Travio provides all the tools you need to create unforgettable travel experiences.',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.7),
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 64),
            Responsive(
              mobile: const _FeaturesMobile(),
              tablet: const _FeaturesTablet(),
              desktop: const _FeaturesDesktop(),
            ),
          ],
        ),
      ),
    );
  }
}

class _FeaturesDesktop extends StatelessWidget {
  const _FeaturesDesktop();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _FeatureCard(
            icon: Icons.map_outlined,
            title: 'Smart Itineraries',
            description:
                'Create detailed day-by-day plans with our intelligent suggestion engine.',
            imageUrl:
                'https://pixabay.com/get/g823d22b784c124fb2c267a5d981b91a49914820ee4c4d9a6b8ccc2f4fa3174ba5ca16a0d67c3a9f9d83a62cec9859e477d9c8252c4cb6647caed6b82045e1e83_1280.jpg',
          ),
        ),
        const SizedBox(width: 32),
        Expanded(
          child: _FeatureCard(
            icon: Icons.group_outlined,
            title: 'Collaborative Planning',
            description:
                'Invite friends and family to collaborate on your trip planning in real-time.',
            imageUrl:
                'https://pixabay.com/get/g55c76a68dd964f885652a96f73255fdf73e6a5eaa60d6f865a15f6ee86c40e7ac013e528273514665242a0bfc5d9f3dd51f0e9307485f0ceaf918b132ad58e1b_1280.jpg',
          ),
        ),
        const SizedBox(width: 32),
        Expanded(
          child: _FeatureCard(
            icon: Icons.explore_outlined,
            title: 'Local Discoveries',
            description:
                'Find hidden gems and local favorites recommended by fellow travelers.',
            imageUrl:
                'https://pixabay.com/get/g1e5130f5ecb63cdeed62a61d50d412421435fee52a362121b42881662ac155b7a4091793a840ef2bc930d827e2058c8b1757f3e8b290d3090b4ad2814d5974dc_1280.jpg',
          ),
        ),
      ],
    );
  }
}

class _FeaturesTablet extends StatelessWidget {
  const _FeaturesTablet();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _FeatureCard(
                icon: Icons.map_outlined,
                title: 'Smart Itineraries',
                description:
                    'Create detailed day-by-day plans with our intelligent suggestion engine.',
                imageUrl:
                    'https://pixabay.com/get/g823d22b784c124fb2c267a5d981b91a49914820ee4c4d9a6b8ccc2f4fa3174ba5ca16a0d67c3a9f9d83a62cec9859e477d9c8252c4cb6647caed6b82045e1e83_1280.jpg',
              ),
            ),
            const SizedBox(width: 24),
            Expanded(
              child: _FeatureCard(
                icon: Icons.group_outlined,
                title: 'Collaborative Planning',
                description:
                    'Invite friends and family to collaborate on your trip planning.',
                imageUrl:
                    'https://pixabay.com/get/g55c76a68dd964f885652a96f73255fdf73e6a5eaa60d6f865a15f6ee86c40e7ac013e528273514665242a0bfc5d9f3dd51f0e9307485f0ceaf918b132ad58e1b_1280.jpg',
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        _FeatureCard(
          icon: Icons.explore_outlined,
          title: 'Local Discoveries',
          description:
              'Find hidden gems and local favorites recommended by fellow travelers.',
          imageUrl:
              'https://pixabay.com/get/g1e5130f5ecb63cdeed62a61d50d412421435fee52a362121b42881662ac155b7a4091793a840ef2bc930d827e2058c8b1757f3e8b290d3090b4ad2814d5974dc_1280.jpg',
        ),
      ],
    );
  }
}

class _FeaturesMobile extends StatelessWidget {
  const _FeaturesMobile();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _FeatureCard(
          icon: Icons.map_outlined,
          title: 'Smart Itineraries',
          description:
              'Create detailed day-by-day plans with our intelligent suggestion engine.',
          imageUrl:
              'https://pixabay.com/get/g823d22b784c124fb2c267a5d981b91a49914820ee4c4d9a6b8ccc2f4fa3174ba5ca16a0d67c3a9f9d83a62cec9859e477d9c8252c4cb6647caed6b82045e1e83_1280.jpg',
        ),
        const SizedBox(height: 24),
        _FeatureCard(
          icon: Icons.group_outlined,
          title: 'Collaborative Planning',
          description:
              'Invite friends and family to collaborate on your trip planning in real-time.',
          imageUrl:
              'https://pixabay.com/get/g55c76a68dd964f885652a96f73255fdf73e6a5eaa60d6f865a15f6ee86c40e7ac013e528273514665242a0bfc5d9f3dd51f0e9307485f0ceaf918b132ad58e1b_1280.jpg',
        ),
        const SizedBox(height: 24),
        _FeatureCard(
          icon: Icons.explore_outlined,
          title: 'Local Discoveries',
          description:
              'Find hidden gems and local favorites recommended by fellow travelers.',
          imageUrl:
              'https://pixabay.com/get/g1e5130f5ecb63cdeed62a61d50d412421435fee52a362121b42881662ac155b7a4091793a840ef2bc930d827e2058c8b1757f3e8b290d3090b4ad2814d5974dc_1280.jpg',
        ),
      ],
    );
  }
}

class _FeatureCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final String imageUrl;

  const _FeatureCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.imageUrl,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.1),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                imageUrl,
                fit: BoxFit.cover,
                height: 250,
                width: double.infinity,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    color: Theme.of(context).colorScheme.primary,
                    size: 24,
                  ),
                ),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              color: Theme.of(context).colorScheme.onSurface,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ],
                  ),
                ),
              ],
              spacing: 12,
            ),
          ],
        ),
      ),
    );
  }
}
