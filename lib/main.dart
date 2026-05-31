import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'models/sound_button.dart';
import 'theme/app_theme.dart';
import 'screens/home_screen.dart';
import 'screens/settings_screen.dart';

void main() async {
  // Ensures Flutter is fully initialized before we run any setup code
  WidgetsFlutterBinding.ensureInitialized();

  // Initializes Hive local database in the app's documents directory
  await Hive.initFlutter();

  // Registers our SoundButton model so Hive knows how to store it
  Hive.registerAdapter(SoundButtonAdapter());

  // Opens the box (think of it as a table) where SoundButtons are stored
  await Hive.openBox<SoundButton>('sound_buttons');

  // ProviderScope is required for Riverpod to work — wraps the entire app
  runApp(const ProviderScope(child: MyApp()));
}

// The root widget of the entire app
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Soundboard',
      debugShowCheckedModeBanner: false, // Removes the debug ribbon in the corner
      theme: AppTheme.darkTheme, // Our custom dark theme from step 2
      home: const MainScreen(),
    );
  }
}

// MainScreen handles the bottom navigation between Home and Settings
class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0; // Tracks which tab is active

  // The two screens the app switches between
  final List<Widget> _screens = const [
    HomeScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex], // Shows the active screen
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.grid_view_rounded),
            label: 'Soundboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings_rounded),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}