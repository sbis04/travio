import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:travio/firebase_options.dart';
import 'package:travio/screens/travio_landing_page.dart';
import 'package:travio/theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  // Default to light mode
  ThemeMode _themeMode = ThemeMode.light;

  void toggleTheme() => setState(() => _themeMode =
      _themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Travio - Trips Made Simple',
      debugShowCheckedModeBanner: false,
      theme: lightTheme,
      darkTheme: darkTheme,
      themeMode: _themeMode,
      home: TravioLandingPage(onThemeToggle: toggleTheme),
    );
  }
}
