import 'package:flutter/material.dart';

import '../screens/home_page.dart';
import 'app_lock.dart';

class RMoneyApp extends StatelessWidget {
  const RMoneyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'RMoney',
      themeMode: ThemeMode.system,
      theme: buildRMoneyTheme(Brightness.light),
      darkTheme: buildRMoneyTheme(Brightness.dark),
      builder: (context, child) => AppLock(child: child!),
      home: const HomePage(),
    );
  }
}

ThemeData buildRMoneyTheme(Brightness brightness) {
  final isDark = brightness == Brightness.dark;
  final scheme = ColorScheme.fromSeed(
    seedColor: const Color(0xFF167D60),
    brightness: brightness,
  ).copyWith(
    primary: isDark ? const Color(0xFF82DDBB) : const Color(0xFF173D32),
    onPrimary: isDark ? const Color(0xFF103B2D) : Colors.white,
    secondary: isDark ? const Color(0xFF6FD9B2) : const Color(0xFF167D60),
    secondaryContainer:
        isDark ? const Color(0xFF214D3F) : const Color(0xFFDAF2E7),
    onSecondaryContainer:
        isDark ? const Color(0xFFBEF3DB) : const Color(0xFF173D32),
    surface: isDark ? const Color(0xFF171A19) : const Color(0xFFF5F7F6),
    onSurface: isDark ? const Color(0xFFF0F3F1) : const Color(0xFF1F2925),
    onSurfaceVariant:
        isDark ? const Color(0xFFA8B6AE) : const Color(0xFF65736C),
    surfaceContainer: isDark ? const Color(0xFF222725) : Colors.white,
    surfaceContainerHighest:
        isDark ? const Color(0xFF2D3430) : const Color(0xFFEDF2EF),
    outlineVariant: isDark ? const Color(0xFF3D4741) : const Color(0xFFDCE5DF),
  );

  return ThemeData(
    useMaterial3: true,
    brightness: brightness,
    colorScheme: scheme,
    scaffoldBackgroundColor: scheme.surface,
    fontFamily: 'Roboto',
    textTheme: const TextTheme().apply(
      bodyColor: scheme.onSurface,
      displayColor: scheme.onSurface,
    ),
    cardTheme: CardThemeData(
      color: scheme.surfaceContainer,
      elevation: 0,
      shadowColor: Colors.black.withValues(alpha: 0.08),
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: scheme.outlineVariant)),
      margin: EdgeInsets.zero,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: scheme.surfaceContainerHighest.withValues(alpha: 0.72),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: scheme.outlineVariant),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: scheme.outlineVariant),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: scheme.secondary, width: 1.6),
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      height: 72,
      elevation: 0,
      backgroundColor: scheme.surfaceContainer,
      indicatorColor: scheme.secondaryContainer,
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        final selected = states.contains(WidgetState.selected);
        return TextStyle(
          fontSize: 10,
          fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
          color:
              selected ? scheme.onSecondaryContainer : scheme.onSurfaceVariant,
        );
      }),
      iconTheme: WidgetStateProperty.resolveWith((states) {
        final selected = states.contains(WidgetState.selected);
        return IconThemeData(
          color:
              selected ? scheme.onSecondaryContainer : scheme.onSurfaceVariant,
        );
      }),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size.fromHeight(48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    ),
    chipTheme: ChipThemeData(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      selectedColor: scheme.secondaryContainer,
      backgroundColor: scheme.surfaceContainerHighest,
      labelStyle: TextStyle(
        color: scheme.onSurface,
        fontWeight: FontWeight.w700,
      ),
      side: BorderSide(color: scheme.outlineVariant),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor:
          isDark ? const Color(0xFF303E36) : const Color(0xFF173D32),
      contentTextStyle: const TextStyle(color: Colors.white),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
  );
}
