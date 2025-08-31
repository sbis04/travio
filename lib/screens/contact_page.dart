import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:travio/providers/theme_provider.dart';
import 'package:travio/router/app_router.dart';

class ContactPage extends StatelessWidget {
  const ContactPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Contact Us'),
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
                'Contact Travio',
                style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 16),
              Text(
                'Get in touch with us for any questions about your travel planning needs.',
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
