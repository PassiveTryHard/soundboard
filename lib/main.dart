import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

// The root widget of the entire app
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Soundboard',
      debugShowCheckedModeBanner: false, // Removes the debug ribbon in the corner
      theme: ThemeData.dark(), // Dark mode as our default
      home: const Scaffold(
        body: Center(
          child: Text('Soundboard — Phase 2 in progress'),
        ),
      ),
    );
  }
}