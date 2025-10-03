import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';
import 'package:int_tst/expense_section/botton_nav.dart';
import 'package:int_tst/Home_page.dart';
import 'package:int_tst/expense_section/model/splash_screen.dart';
import 'package:int_tst/main_section/Income_sms.dart';
import 'package:int_tst/main_section/expense_sms.dart';
import 'package:int_tst/expense_section/expense_add_page.dart';
import 'package:int_tst/fire.dart';
// import 'package:int_tst/settings_page.dart';

import 'login_section/settings.dart'; // Add this import for darkModeNotifier

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await GetStorage.init();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final storage = GetStorage();
    bool initialDarkMode = storage.read('isDarkMode') ?? false; // Load initial preference

    // Sync initial value with the notifier from settings_page.dart
    darkModeNotifier.value = initialDarkMode;

    return ValueListenableBuilder<bool>(
      valueListenable: darkModeNotifier, // Listen to dark mode changes
      builder: (context, isDarkMode, child) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'FinTrack',
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
            useMaterial3: true,
            brightness: Brightness.light, // Explicitly set for light theme
            scaffoldBackgroundColor: Colors.white, // Customize as needed
          ),
          darkTheme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: Colors.deepPurple,
              brightness: Brightness.dark, // Dark theme
            ),
            useMaterial3: true,
            scaffoldBackgroundColor: Colors.grey[900], // Customize as needed
          ),
          themeMode: isDarkMode ? ThemeMode.dark : ThemeMode.light, // Dynamic toggle
          home:  const SplashScreen(),
        );
      },
    );
  }
}