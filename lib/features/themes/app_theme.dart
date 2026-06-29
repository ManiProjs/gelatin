import 'package:flutter/material.dart';

class AppTheme {
  static const _accent = Color(0xFF2196F3);

  static final ThemeData light = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: ColorScheme.fromSeed(
      seedColor: _accent,
      brightness: Brightness.light,
    ),
    scaffoldBackgroundColor: const Color(0xFFF7F8FA),
    cardColor: Colors.white,
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: false,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: _accent,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    ),
    navigationRailTheme: NavigationRailThemeData(
      indicatorColor: Colors.transparent,
    ),
    chipTheme: ChipThemeData(
      backgroundColor: Colors.grey.shade200,
      disabledColor: Colors.grey.shade100,
      selectedColor: _accent,
      secondarySelectedColor: _accent,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      labelStyle: const TextStyle(color: Colors.black87),
      secondaryLabelStyle: const TextStyle(color: Colors.white),
      brightness: Brightness.light,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
    dividerTheme: DividerThemeData(
      color: Colors.black.withValues(alpha: 0.12),
      thickness: 1,
      space: 1,
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
    ),
    progressIndicatorTheme: ProgressIndicatorThemeData(color: _accent),
    cardTheme: const CardThemeData(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(18)),
      ),
      elevation: 0,
    ),
    textTheme: ThemeData.light().textTheme.copyWith(
      titleLarge: ThemeData.light().textTheme.titleLarge?.copyWith(
        fontWeight: FontWeight.w600,
      ),
      headlineMedium: ThemeData.light().textTheme.headlineMedium?.copyWith(
        fontWeight: FontWeight.w600,
      ),
    ),
  );

  static final ThemeData dark = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: ColorScheme.fromSeed(
      seedColor: _accent,
      brightness: Brightness.dark,
    ),
    scaffoldBackgroundColor: const Color(0xFF0B0B0F),
    cardColor: const Color(0xFF171922),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: false,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: _accent,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    ),
    navigationRailTheme: NavigationRailThemeData(
      indicatorColor: Colors.transparent,
    ),
    chipTheme: ChipThemeData(
      backgroundColor: Colors.grey.shade800,
      disabledColor: Colors.grey.shade700,
      selectedColor: _accent,
      secondarySelectedColor: _accent,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      labelStyle: const TextStyle(color: Colors.white70),
      secondaryLabelStyle: const TextStyle(color: Colors.white),
      brightness: Brightness.dark,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
    dividerTheme: DividerThemeData(
      color: Colors.white.withValues(alpha: 0.12),
      thickness: 1,
      space: 1,
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
    ),
    progressIndicatorTheme: ProgressIndicatorThemeData(color: _accent),
    cardTheme: const CardThemeData(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(18)),
      ),
      elevation: 0,
    ),
    textTheme: ThemeData.dark().textTheme.copyWith(
      titleLarge: ThemeData.dark().textTheme.titleLarge?.copyWith(
        fontWeight: FontWeight.w600,
      ),
      headlineMedium: ThemeData.dark().textTheme.headlineMedium?.copyWith(
        fontWeight: FontWeight.w600,
      ),
    ),
  );
}
