import 'package:flutter/material.dart';

class AppTheme {
  static const primary = Color(0xFF1769E0);
  static const light = ColorScheme.light(primary: primary, secondary: Color(0xFF38A3F1), surface: Color(0xFFF6F8FC));
  static const dark = ColorScheme.dark(primary: Color(0xFF78AEFF), secondary: Color(0xFF54B7F2), surface: Color(0xFF151D2B));

  static ThemeData get lightTheme => ThemeData(
    useMaterial3: true,
    colorScheme: light,
    scaffoldBackgroundColor: const Color(0xFFF5F8FD),
    appBarTheme: const AppBarTheme(backgroundColor: Color(0xFFF5F8FD), foregroundColor: Color(0xFF14243B), elevation: 0, centerTitle: false),
    cardTheme: CardThemeData(color: Colors.white, elevation: 0, margin: EdgeInsets.zero, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18), side: const BorderSide(color: Color(0xFFE7EDF5)))),
    inputDecorationTheme: InputDecorationTheme(filled: true, fillColor: Colors.white, border: OutlineInputBorder(borderRadius: BorderRadius.circular(13), borderSide: const BorderSide(color: Color(0xFFDCE5F0))), enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(13), borderSide: const BorderSide(color: Color(0xFFDCE5F0))), contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14)),
  );

  static ThemeData get darkTheme => ThemeData(
    useMaterial3: true,
    colorScheme: dark,
    scaffoldBackgroundColor: const Color(0xFF101722),
    appBarTheme: const AppBarTheme(backgroundColor: Color(0xFF101722), foregroundColor: Color(0xFFF1F5F9), elevation: 0, centerTitle: false),
    cardTheme: CardThemeData(color: const Color(0xFF1B2636), elevation: 0, margin: EdgeInsets.zero, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18), side: const BorderSide(color: Color(0xFF2B3A4F)))),
    inputDecorationTheme: InputDecorationTheme(filled: true, fillColor: const Color(0xFF1B2636), border: OutlineInputBorder(borderRadius: BorderRadius.circular(13), borderSide: const BorderSide(color: Color(0xFF35465C))), enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(13), borderSide: const BorderSide(color: Color(0xFF35465C))), contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14)),
  );
}
