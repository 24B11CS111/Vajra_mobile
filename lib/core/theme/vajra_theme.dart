import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'vajra_colors.dart';

class VajraTheme {
  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: VajraColors.primaryBackground,
      primaryColor: VajraColors.accent,
      colorScheme: const ColorScheme.dark(
        primary: VajraColors.accent,
        surface: VajraColors.surface,
        error: VajraColors.error,
        onPrimary: VajraColors.primaryBackground,
        onSurface: VajraColors.primaryText,
      ),
      textTheme: GoogleFonts.interTextTheme(
        ThemeData.dark().textTheme.copyWith(
          displayLarge: const TextStyle(color: VajraColors.primaryText, fontWeight: FontWeight.w700, letterSpacing: -1.0),
          displayMedium: const TextStyle(color: VajraColors.primaryText, fontWeight: FontWeight.w600, letterSpacing: -0.5),
          bodyLarge: const TextStyle(color: VajraColors.primaryText, fontSize: 16),
          bodyMedium: const TextStyle(color: VajraColors.secondaryText, fontSize: 14),
          labelLarge: const TextStyle(color: VajraColors.primaryBackground, fontWeight: FontWeight.w600), // Used in buttons
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      useMaterial3: true,
    );
  }
}
