import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:travio/providers/theme_provider.dart';
import 'package:travio/router/app_router.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('About Travio'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.goHome(),
        ),
        actions: [
          IconButton(
            icon: Icon(
              context.watch<ThemeProvider>().isDarkMode
                  ? Icons.light_mode
                  : Icons.dark_mode,
            ),
            onPressed: () => context.read<ThemeProvider>().toggleTheme(),
            tooltip: 'Toggle theme',
          ),
        ],
      ),
      body: const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'About Travio',
                style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 16),
              Text(
                'Craft unforgettable adventures with Travio, the intuitive web app designed to simplify your trip planning from dream to destination.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
