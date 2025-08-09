import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

final darkTheme = ThemeData(
  brightness: Brightness.dark,
  primaryColor: const Color(0xFFBB86FC),
  colorScheme: const ColorScheme.dark(
    primary: Color(0xFFBB86FC),
    secondary: Color(0xFF03DAC6),
    background: Color(0xFF121212),
    surface: Color(0xFF1E1E1E),
    onPrimary: Colors.black,
    onSecondary: Colors.black,
    onBackground: Colors.white,
    onSurface: Colors.white,
    onError: Colors.black,
    error: Color(0xFFCF6679),
  ),
  scaffoldBackgroundColor: const Color(0xFF121212),
  appBarTheme: AppBarTheme(
    backgroundColor: const Color(0xFF1E1E1E),
    elevation: 0,
    titleTextStyle: GoogleFonts.lato(
      fontSize: 20,
      fontWeight: FontWeight.bold,
      color: Colors.white,
    ),
  ),
  textTheme: GoogleFonts.latoTextTheme(
    const TextTheme(
      displayLarge: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      displayMedium: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      displaySmall: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      headlineMedium: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      headlineSmall: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      titleLarge: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      bodyLarge: TextStyle(color: Colors.white),
      bodyMedium: TextStyle(color: Colors.white70),
    ),
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      foregroundColor: Colors.black,
      backgroundColor: const Color(0xFFBB86FC),
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      textStyle: GoogleFonts.lato(
        fontSize: 16,
        fontWeight: FontWeight.bold,
      ),
    ),
  ),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: const Color(0xFF1E1E1E),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide.none,
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Color(0xFFBB86FC)),
    ),
    labelStyle: const TextStyle(color: Colors.white70),
  ),
  cardTheme: CardThemeData(
    color: const Color(0xFF1E1E1E),
    elevation: 4,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    ),
  ),
);