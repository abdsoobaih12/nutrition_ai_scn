import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:ai_scn/models/analysis_result.dart';
import 'package:ai_scn/screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  Hive.registerAdapter(AnalysisResultAdapter());
  runApp(const SmartIngredientScannerApp());
}

class SmartIngredientScannerApp extends StatelessWidget {
  const SmartIngredientScannerApp({super.key});

  @override
  Widget build(BuildContext context) {
    final seed = const Color(0xFF41E296);
    return MaterialApp(
      title: 'Smart Ingredient Scanner',
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0F1115),
        colorScheme: ColorScheme.fromSeed(
          seedColor: seed,
          brightness: Brightness.dark,
        ),
        textTheme: const TextTheme(
          headlineLarge: TextStyle(
            fontSize: 36,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
          bodyLarge: TextStyle(color: Colors.white70, height: 1.4),
        ),
      ),
      home: const HomeScreen(),
    );
  }
}
