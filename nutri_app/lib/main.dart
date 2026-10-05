import 'package:flutter/material.dart';
import 'screens/home_screen.dart';

void main() {
  runApp(const NutriApp());
}

class NutriApp extends StatelessWidget {
  const NutriApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'NutriApp',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.green,
          primary: const Color(0xFF2EAD70),
          secondary: const Color(0xFF64C9D0),
        ),
        scaffoldBackgroundColor: const Color(0xFFF5F7F5),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black87,
          elevation: 0,
          centerTitle: true,
        ),
      ),

      // Pantalla inicial de NutriApp
      home: const HomeScreen(),
    );
  }
}