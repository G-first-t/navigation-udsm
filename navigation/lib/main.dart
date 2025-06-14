import 'package:flutter/material.dart';
import 'package:navigation/pages/home_screen.dart';
import 'package:navigation/utils/logger.dart';

void main() {
  runApp(const MainApp());
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
