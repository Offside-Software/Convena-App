import 'package:flutter/material.dart';
import 'screens/event_map_screen.dart';

void main() {
  runApp(const App());
}

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Convena',
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0F1015),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFFD4F042), // Neon Lime Accent
          surface: Color(0xFF16171D),
        ),
        useMaterial3: true,
      ),
      home: const EventMapScreen(),
    );
  }
}
