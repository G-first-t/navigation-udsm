import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:navigation/firebase_options.dart';
import 'package:navigation/utils/logger.dart';
import 'package:navigation/pages/welcome_page.dart';
import 'package:navigation/auth/login_screen.dart';
import 'package:navigation/auth/register_screen.dart';
import 'package:navigation/pages/home_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  AppLogger.info('Starting application initialization...');

  try {
    AppLogger.debug('Initializing Firebase...');
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    AppLogger.info('Firebase initialized successfully');

    // Force show WelcomePage for demo
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isFirstLaunch', true); // <-- Always true for demo

    runApp(const MainApp());
    AppLogger.info('Running the app...');
  } catch (e, stack) {
    AppLogger.error('Initialization failed', e, stack);
  }
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  Future<bool> isFirstLaunch() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('isFirstLaunch') ?? true;
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: FutureBuilder<bool>(
        future: isFirstLaunch(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }

          final firstLaunch = snapshot.data!;
          if (firstLaunch) {
            return WelcomePage(
              onLogin: () {
                // Show Login Page
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                );
              },
              onSignup: () {
                // Show Sign Up Page
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const SignupScreen()),
                );
              },
            );
          } else {
            return const HomeScreen(); // fallback in real use
          }
        },
      ),
    );
  }
}
