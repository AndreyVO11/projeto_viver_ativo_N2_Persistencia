import 'package:flutter/material.dart';

/// Tema visual do app, alinhado à RNF001 (interface acessível visualmente):
/// fontes com no mínimo 18pt, cores de alto contraste e componentes grandes
/// o suficiente para toque em ambiente externo (sol forte, usuário em pé).
class AppTheme {
  AppTheme._();

  static const Color primary = Color(0xFF1B5E20); // verde escuro - alto contraste
  static const Color primaryLight = Color(0xFF43A047);
  static const Color danger = Color(0xFFB3261E);
  static const Color background = Color(0xFFFFFFFF);
  static const Color surface = Color(0xFFF5F5F5);
  static const Color textPrimary = Color(0xFF1A1A1A);

  static const double minFontSize = 18;
  static const double minButtonHeight = 56;

  static ThemeData get theme {
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primary,
        primary: primary,
        error: danger,
        brightness: Brightness.light,
      ),
      scaffoldBackgroundColor: background,
    );

    return base.copyWith(
      textTheme: base.textTheme.apply(
        bodyColor: textPrimary,
        displayColor: textPrimary,
        fontSizeFactor: 1.0,
      ).copyWith(
        bodyLarge: const TextStyle(fontSize: minFontSize, color: textPrimary),
        bodyMedium: const TextStyle(fontSize: minFontSize, color: textPrimary),
        titleLarge: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: textPrimary),
        titleMedium: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: textPrimary),
        labelLarge: const TextStyle(fontSize: minFontSize, fontWeight: FontWeight.w600),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        centerTitle: true,
        titleTextStyle: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
        iconTheme: IconThemeData(size: 28, color: Colors.white),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(minButtonHeight),
          textStyle: const TextStyle(fontSize: minFontSize, fontWeight: FontWeight.w600),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primary,
          minimumSize: const Size.fromHeight(minButtonHeight),
          textStyle: const TextStyle(fontSize: minFontSize, fontWeight: FontWeight.w600),
          side: const BorderSide(color: primary, width: 2),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primary,
          textStyle: const TextStyle(fontSize: minFontSize, fontWeight: FontWeight.w600),
          minimumSize: const Size.fromHeight(48),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade400),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primary, width: 2),
        ),
        labelStyle: const TextStyle(fontSize: minFontSize),
        hintStyle: TextStyle(fontSize: minFontSize, color: Colors.grey.shade600),
      ),
      cardTheme: CardThemeData(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      ),
      chipTheme: base.chipTheme.copyWith(
        labelStyle: const TextStyle(fontSize: 16),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      iconTheme: const IconThemeData(size: 28, color: textPrimary),
    );
  }
}
