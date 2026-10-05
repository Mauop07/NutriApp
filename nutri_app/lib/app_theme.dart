import 'package:flutter/material.dart';

/// Configuración global de estilos, colores y componentes visuales (ThemeData).
class AppTheme {
  // Paleta de colores institucional
  static const Color primaryBlue = Colors.blue;
  static const Color corporateGreen = Color(0xFF26CA4F);
  static const Color background = Colors.white;
  static const Color textMain = Colors.black;
  static const Color textMuted = Colors.grey;

  /// Tema claro principal de la aplicación.
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: background,
      primaryColor: primaryBlue,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryBlue,
        primary: primaryBlue,
        secondary: corporateGreen,
      ),
      // Estandarización global para campos de texto (TextFields)
      inputDecorationTheme: const InputDecorationTheme(
        border: OutlineInputBorder(),
        prefixIconColor: Colors.black54,
      ),
      // Estandarización global para botones elevados
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryBlue,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 50),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
    );
  }
}
