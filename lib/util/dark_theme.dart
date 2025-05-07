import 'package:flutter/material.dart';

const Color primaryColor = Color(0xFF2B2024); // Hitam
const Color secondaryColor = Color(0xFFA80038); // Merah
const Color accentColor = Color(0xFFFBF9FA); // Putih

final ThemeData darkTheme = ThemeData(
  colorScheme: ColorScheme.fromSeed(
    seedColor: secondaryColor,
    brightness: Brightness.dark,
    primary: primaryColor,
    secondary: secondaryColor,
    tertiary: accentColor,
    surface: primaryColor,
    background: primaryColor,
    onPrimary: accentColor,
    onSecondary: accentColor,
    onTertiary: primaryColor,
    onSurface: accentColor,
    onBackground: accentColor,
    error: const Color(0xffd32f2f),
    onError: accentColor,
  ),
  scaffoldBackgroundColor: primaryColor,
  appBarTheme: AppBarTheme(
    backgroundColor: primaryColor,
    foregroundColor: accentColor,
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: secondaryColor,
      foregroundColor: accentColor
    ),
  ),
  useMaterial3: true,
);
