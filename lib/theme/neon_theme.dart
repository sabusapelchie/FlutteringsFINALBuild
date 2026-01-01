import 'package:flutter/material.dart';

class NeonTheme {
  static const neonBlue = Color(0xFF00E5FF);
  static const neonPurple = Color(0xFFB388FF);
  static const darkBg = Color(0xFF0B0F1A);

  static ThemeData theme = ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: darkBg,
    primaryColor: neonBlue,
    fontFamily: 'Orbitron',

    appBarTheme: AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.bold,
        color: neonBlue,
      ),
    ),

    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: neonPurple,
        foregroundColor: Colors.black,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        padding: EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        textStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
    ),

    cardTheme: CardThemeData(
      color: darkBg.withOpacity(0.9),
      elevation: 12,
      shadowColor: neonPurple,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
    ),
  );
}
