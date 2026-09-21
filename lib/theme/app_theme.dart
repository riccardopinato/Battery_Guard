import 'package:flutter/material.dart';

class AppTheme {
  const AppTheme._();

  static ThemeData light() {
    final scheme = ColorScheme.fromSeed(seedColor: const Color(0xFF21A366),brightness: Brightness.light);
    return _theme(scheme);
  }

  static ThemeData dark() {
    final scheme = ColorScheme.fromSeed(seedColor: const Color(0xFF3DDC84),brightness: Brightness.dark);
    return _theme(scheme);
  }

  static ThemeData _theme(ColorScheme scheme) {
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: scheme.surface,
      navigationBarTheme: NavigationBarThemeData(height: 72,indicatorColor: scheme.primaryContainer),
      cardTheme: CardThemeData(elevation: 0,color: scheme.surfaceContainerLow,shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24))),
      filledButtonTheme: FilledButtonThemeData(style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52),shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)))),
    );
  }
}
