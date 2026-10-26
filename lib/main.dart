import 'package:convena/pages/auth_page.dart';
import 'package:convena/services/theme_services.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();

  runApp(
    MultiProvider(
      providers: [ChangeNotifierProvider(create: (_) => ThemeService(prefs))],
      child: const App(),
    ),
  );
}

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeService>();
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: 'Inter',
        brightness: theme.isDark ? Brightness.dark : Brightness.light,
        scaffoldBackgroundColor: theme.colors.bg,
      ),
      home: AuthPage(),
    );
  }
}
