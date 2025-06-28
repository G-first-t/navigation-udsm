import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:navigation/auth/register_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:navigation/auth/login_screen.dart';
import 'package:navigation/firebase_options.dart';
import 'package:navigation/utils/logger.dart';
import 'package:navigation/pages/welcome_page.dart'; // Create this file

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  AppLogger.info('Starting application initialization...');
  try {
    AppLogger.debug('Initializing Firebase...');
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    AppLogger.info('Firebase initialized successfully');
    runApp(const MainApp());
    AppLogger.info('Running the app...');
  } catch (e, stack) {
    AppLogger.error('Initialization failed', e, stack);
  }
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  Future<bool> _isFirstTime() async {
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: FutureBuilder<bool>(
        future: _isFirstTime(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }

          final isFirstTime = snapshot.data!;
          if (isFirstTime) {
            return WelcomePage(
              onLogin: () async {
                final prefs = await SharedPreferences.getInstance();
                await prefs.setBool('welcome_seen', true);
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                );
              },
              onSignup: () async {
                final prefs = await SharedPreferences.getInstance();
                await prefs.setBool('welcome_seen', true);
                // Replace with your SignUp page route:
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const SignupScreen()),
                );
              },
            );
          } else {
            return const LoginScreen();
          }
        },
      ),
    );
  }
}
