// lib/theme.dart
import 'package:flutter/material.dart';
import 'screens/components/const/colors.dart';

/// Enumerate all modes you plan to support
enum AppTheme { Default, Dark, Blue, HighContrast }

/// Map each mode to its ThemeData
final Map<AppTheme, ThemeData> appThemeData = {
  AppTheme.Default: ThemeData(
    brightness: Brightness.light,
    primaryColor: darkGreen,
    scaffoldBackgroundColor: Color(0xFFA5D6A7), // ← light green 200
    colorScheme: ColorScheme.light(
      primary: primaryGreen,
      secondary: secondaryGreen, // ← same light green
      surface: Colors.white,
    ),
    textTheme: const TextTheme(
      bodyLarge: TextStyle(color: textColor),
      bodyMedium: TextStyle(color: textColor),
      headlineLarge:
          TextStyle(color: primaryGreen, fontWeight: FontWeight.bold),
      headlineMedium: TextStyle(color: darkGreen, fontWeight: FontWeight.bold),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: darkGreen,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        elevation: 0,
      ),
    ),
  ),
  AppTheme.Dark: ThemeData(
    brightness: Brightness.dark,
    primaryColor: primaryGreen,
    scaffoldBackgroundColor: Colors.black,
    colorScheme: ColorScheme.dark(
      primary: primaryGreen,
      secondary: secondaryGreen,
      surface: Colors.grey[850]!,
    ),
    textTheme: const TextTheme(
      bodyLarge: TextStyle(color: Colors.white70),
      bodyMedium: TextStyle(color: Colors.white70),
      headlineLarge:
          TextStyle(color: primaryGreen, fontWeight: FontWeight.bold),
      headlineMedium:
          TextStyle(color: secondaryGreen, fontWeight: FontWeight.bold),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryGreen,
        foregroundColor: Colors.black,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        elevation: 0,
      ),
    ),
  ),
  AppTheme.Blue: ThemeData(
    brightness: Brightness.light,
    primarySwatch: Colors.blue,
    scaffoldBackgroundColor: Colors.blue[50],
    colorScheme: ColorScheme.light(
      primary: Colors.blue,
      secondary: Colors.teal,
    ),
  ),
  AppTheme.HighContrast: ThemeData(
    brightness: Brightness.light,
    primaryColor: Colors.pink,
    scaffoldBackgroundColor: Colors.pink[50],
    textTheme: const TextTheme(
      bodyLarge: TextStyle(
          fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
      bodyMedium: TextStyle(
          fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.pink,
        foregroundColor: Color(0xFFFCE4EC),
      ),
    ),
  ),
};
