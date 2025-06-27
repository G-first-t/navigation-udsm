import 'package:flutter/material.dart';
import 'package:navigation/pages/home_screen.dart';
import 'firebase_options.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:navigation/utils/logger.dart';

 //The main function or the root for our application
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  AppLogger.info('Starting application initialization...');
  try {
    // Initializing Firebase
    AppLogger.debug('Initializing Firebase...');
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    AppLogger.info('Firebase initialized successfully');
    // Running the application
    runApp(const MainApp());
    AppLogger.info('Running the app...');
  } catch (e, stack) {
    AppLogger.error('Initialization failed', e, stack);
  }
}

class MainApp extends StatefulWidget {
  const MainApp({super.key});
  @override
  _MainAppState createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      initialRoute: '/home', // Set the initial route
      routes: {'/home': (context) => HomeScreen()},
    );
  }
}
 