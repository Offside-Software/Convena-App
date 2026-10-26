import 'package:convena/pages/auth_page.dart';
import 'package:convena/services/auth_service.dart';
import 'package:convena/services/theme_services.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeService(prefs)),
        ChangeNotifierProvider(create: (_) => AuthService(prefs)),
      ],
      child: const App(),
    ),
  );
}

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeService>();
    final baseTextTheme = theme.isDark
        ? ThemeData.dark().textTheme
        : ThemeData.light().textTheme;

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: GoogleFonts.montserrat().fontFamily,
        brightness: theme.isDark ? Brightness.dark : Brightness.light,
        scaffoldBackgroundColor: theme.colors.bg,
        textTheme: GoogleFonts.montserratTextTheme(baseTextTheme),
        primaryTextTheme: GoogleFonts.montserratTextTheme(baseTextTheme),
      ),
      home: const AuthPage(),
    );
  }
}
