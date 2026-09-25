import 'package:flutter/material.dart';

class AppTheme {
  const AppTheme._();

  static const coolHorizon = Color(0xFF80AEE8);
  static const nightBordeaux = Color(0xFF5B0015);
  static const ivoryMist = Color(0xFFF7F2E0);

  static ThemeData get lightTheme {
    return ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: coolHorizon,
        primary: nightBordeaux,
        secondary: coolHorizon,
        surface: ivoryMist,
      ),
      scaffoldBackgroundColor: ivoryMist,
      appBarTheme: const AppBarTheme(
        backgroundColor: ivoryMist,
        foregroundColor: nightBordeaux,
        elevation: 0,
        centerTitle: false,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: coolHorizon.withValues(alpha: .28)),
        ),
        focusedBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
          borderSide: BorderSide(color: nightBordeaux, width: 1.5),
        ),
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      useMaterial3: true,
    );
  }
}
